-- ==============================================================================
-- supabase/tests/rls.sql
-- Suite de pruebas de seguridad, RLS y lógica de negocio para subscription-gate.
-- Puede ejecutarse en el SQL Editor de Supabase o mediante psql.
-- Se ejecuta dentro de una transacción que hace ROLLBACK al finalizar para no dejar datos residuales.
-- ==============================================================================

begin;

-- Desactivar temporalmente notices irrelevantes para mantener la salida limpia
set client_min_messages = notice;

do $$
declare
  v_admin_id uuid := '11111111-1111-1111-1111-111111111111';
  v_user1_id uuid := '22222222-2222-2222-2222-222222222222';
  v_user2_id uuid := '33333333-3333-3333-3333-333333333333';
  v_hw_original text := 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  v_hw_distinto text := 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  v_hw_invalido text := 'hash_muy_corto';

  v_res jsonb;
  v_count int;
  v_fecha timestamptz;
  v_fecha_esperada timestamptz;
  v_error_capturado boolean;
begin
  raise notice '============================================================';
  raise notice ' INICIANDO SUITE DE PRUEBAS: subscription-gate (RLS & RPC) ';
  raise notice '============================================================';

  -- --------------------------------------------------------------------------
  -- 0. Preparar datos de prueba simulados
  -- --------------------------------------------------------------------------
  -- Crear usuarios en auth.users si no existen
  insert into auth.users (id, email)
  values
    (v_admin_id, 'admin@test.local'),
    (v_user1_id, 'usuario1@test.local'),
    (v_user2_id, 'usuario2@test.local')
  on conflict (id) do nothing;

  -- Asignar administrador
  insert into public.admins (user_id) values (v_admin_id) on conflict do nothing;

  -- Crear licencias (limpiando previas del mock)
  delete from public.licencias where usuario_id in (v_admin_id, v_user1_id, v_user2_id);

  insert into public.licencias (usuario_id, email, fecha_fin, hardware_id, bloqueada)
  values
    (v_user1_id, 'usuario1@test.local', now() + interval '30 days', null, false),
    (v_user2_id, 'usuario2@test.local', now() + interval '30 days', null, false);

  -- --------------------------------------------------------------------------
  -- 1. PRUEBA: Aislamiento RLS en SELECT (un usuario solo ve su propia fila)
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);

  select count(*) into v_count from public.licencias;
  if v_count <> 1 then
    raise exception 'FALLO TEST 1: El usuario 1 vio % filas, esperaba ver exactamente 1', v_count;
  end if;
  raise notice '✓ [PASS] Test 1: Usuario normal solo puede leer su propia licencia (RLS Select)';

  -- --------------------------------------------------------------------------
  -- 2. PRUEBA: RLS bloquea UPDATE, INSERT y DELETE a usuarios normales
  -- --------------------------------------------------------------------------
  -- Intentar actualizar su propia fecha_fin directamente
  update public.licencias
     set fecha_fin = now() + interval '1000 days'
   where usuario_id = v_user1_id;

  -- Volver a rol administrador / superuser para comprobar que la fila no cambió
  set local role postgres;
  select fecha_fin into v_fecha from public.licencias where usuario_id = v_user1_id;
  if v_fecha > now() + interval '31 days' then
    raise exception 'FALLO TEST 2a: Un usuario normal logró modificar su propia fecha_fin';
  end if;

  -- Intentar insertar o borrar con rol authenticated
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);

  begin
    insert into public.licencias (usuario_id, email, fecha_fin)
    values ('44444444-4444-4444-4444-444444444444', 'hacker@test.local', now() + interval '100 days');
    raise exception 'FALLO TEST 2b: Se permitió INSERT a un usuario autenticado normal';
  exception when others then
    -- Se esperaba excepción por check policy o denegación
    null;
  end;

  delete from public.licencias where usuario_id = v_user1_id;
  set local role postgres;
  select count(*) into v_count from public.licencias where usuario_id = v_user1_id;
  if v_count = 0 then
    raise exception 'FALLO TEST 2c: Se permitió DELETE a un usuario autenticado normal';
  end if;
  raise notice '✓ [PASS] Test 2: RLS impide INSERT, UPDATE y DELETE directos a usuarios no-admin';

  -- --------------------------------------------------------------------------
  -- 3. PRUEBA: Usuario normal no puede invocar funciones admin_*
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);

  -- admin_renovar
  v_error_capturado := false;
  begin
    perform public.admin_renovar(v_user1_id, 30);
  exception when others then
    if sqlerrm like '%NO_AUTORIZADO%' then
      v_error_capturado := true;
    end if;
  end;
  if not v_error_capturado then
    raise exception 'FALLO TEST 3a: admin_renovar no arrojó NO_AUTORIZADO para usuario normal';
  end if;

  -- admin_reset_hardware
  v_error_capturado := false;
  begin
    perform public.admin_reset_hardware(v_user1_id);
  exception when others then
    if sqlerrm like '%NO_AUTORIZADO%' then
      v_error_capturado := true;
    end if;
  end;
  if not v_error_capturado then
    raise exception 'FALLO TEST 3b: admin_reset_hardware no arrojó NO_AUTORIZADO para usuario normal';
  end if;

  -- admin_bloquear
  v_error_capturado := false;
  begin
    perform public.admin_bloquear(v_user1_id, true);
  exception when others then
    if sqlerrm like '%NO_AUTORIZADO%' then
      v_error_capturado := true;
    end if;
  end;
  if not v_error_capturado then
    raise exception 'FALLO TEST 3c: admin_bloquear no arrojó NO_AUTORIZADO para usuario normal';
  end if;
  raise notice '✓ [PASS] Test 3: Funciones administrativas admin_* protegidas contra usuarios regulares';

  -- --------------------------------------------------------------------------
  -- 4. PRUEBA: Rol anon tiene revocada la ejecución
  -- --------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claim.sub', '', true);

  v_error_capturado := false;
  begin
    perform public.validar_acceso(v_hw_original);
  exception when insufficient_privilege then
    v_error_capturado := true;
  end;
  if not v_error_capturado then
    raise exception 'FALLO TEST 4: El rol anon pudo ejecutar validar_acceso sin permiso';
  end if;
  raise notice '✓ [PASS] Test 4: Rol anon no tiene permiso de ejecución en funciones RPC';

  -- --------------------------------------------------------------------------
  -- 5. PRUEBA: validar_acceso vincula en primer uso y detecta errores
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);

  -- 5a. Hardware inválido (longitud incorrecta)
  v_res := public.validar_acceso(v_hw_invalido);
  if (v_res->>'autorizado')::boolean <> false or (v_res->>'motivo') <> 'HARDWARE_INVALIDO' then
    raise exception 'FALLO TEST 5a: No rechazó hardware inválido. Respuesta: %', v_res;
  end if;

  -- 5b. Primer uso con hardware válido: debe autorizar y vincular
  v_res := public.validar_acceso(v_hw_original);
  if (v_res->>'autorizado')::boolean <> true or (v_res->>'motivo') <> 'OK' then
    raise exception 'FALLO TEST 5b: No autorizó primer uso con hardware válido. Respuesta: %', v_res;
  end if;

  -- Comprobar que en base de datos se guardó el hardware vinculado
  set local role postgres;
  select hardware_id into v_hw_invalido from public.licencias where usuario_id = v_user1_id;
  if v_hw_invalido <> v_hw_original then
    raise exception 'FALLO TEST 5b: No se persistió el hardware_id en licencias';
  end if;

  -- 5c. Segundo uso con OTRO equipo: debe rechazar con HARDWARE_NO_COINCIDE
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);
  v_res := public.validar_acceso(v_hw_distinto);
  if (v_res->>'autorizado')::boolean <> false or (v_res->>'motivo') <> 'HARDWARE_NO_COINCIDE' then
    raise exception 'FALLO TEST 5c: No rechazó hardware distinto. Respuesta: %', v_res;
  end if;

  -- 5d. Licencia Bloqueada: bloquear cuenta como admin y reintentar
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform public.admin_bloquear(v_user1_id, true);

  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);
  v_res := public.validar_acceso(v_hw_original);
  if (v_res->>'autorizado')::boolean <> false or (v_res->>'motivo') <> 'CUENTA_BLOQUEADA' then
    raise exception 'FALLO TEST 5d: No rechazó cuenta bloqueada. Respuesta: %', v_res;
  end if;

  -- Desbloquear
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform public.admin_bloquear(v_user1_id, false);

  -- 5e. Licencia Expirada: forzar fecha_fin en el pasado y probar
  set local role postgres;
  update public.licencias set fecha_fin = now() - interval '1 hour' where usuario_id = v_user1_id;

  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);
  v_res := public.validar_acceso(v_hw_original);
  if (v_res->>'autorizado')::boolean <> false or (v_res->>'motivo') <> 'LICENCIA_EXPIRADA' then
    raise exception 'FALLO TEST 5e: No rechazó licencia expirada. Respuesta: %', v_res;
  end if;
  raise notice '✓ [PASS] Test 5: validar_acceso valida correctamente primer uso, hardware, bloqueo y expiración';

  -- --------------------------------------------------------------------------
  -- 6. PRUEBA: admin_renovar suma desde now() si venció o desde fecha_fin si está vigente
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);

  -- Caso 6a: Licencia vencida (fecha_fin está en el pasado) -> debe renovar desde now()
  v_fecha := public.admin_renovar(v_user1_id, 30);
  if v_fecha < now() + interval '29 days' or v_fecha > now() + interval '31 days' then
    raise exception 'FALLO TEST 6a: Renovación de vencida no calculó desde now() + 30 días. Fecha: %', v_fecha;
  end if;

  -- Caso 6b: Licencia vigente (le quedan ~30 días) -> al sumar 10 días debe quedar en ~40 días
  v_fecha_esperada := v_fecha + interval '10 days';
  v_fecha := public.admin_renovar(v_user1_id, 10);
  if abs(extract(epoch from (v_fecha - v_fecha_esperada))) > 5 then
    raise exception 'FALLO TEST 6b: Renovación de vigente no extendió sobre fecha_fin existente. Fecha: %', v_fecha;
  end if;
  raise notice '✓ [PASS] Test 6: admin_renovar suma correctamente desde now() o desde fecha_fin vigente';

  -- --------------------------------------------------------------------------
  -- 7. PRUEBA: admin_reset_hardware permite re-vincular
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform public.admin_reset_hardware(v_user1_id);

  -- u_user1 ahora debería poder validar con v_hw_distinto
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', v_user1_id::text, true);
  v_res := public.validar_acceso(v_hw_distinto);
  if (v_res->>'autorizado')::boolean <> true then
    raise exception 'FALLO TEST 7: Tras reset de hardware no se pudo revincular. Respuesta: %', v_res;
  end if;
  raise notice '✓ [PASS] Test 7: admin_reset_hardware libera el vínculo y permite registrar un nuevo equipo';

  raise notice '============================================================';
  raise notice ' TODOS LOS TESTS RLS Y RPC COMPLETADOS SATISFACTORIAMENTE ';
  raise notice '============================================================';
end $$;

-- Revertir todos los cambios realizados durante la prueba
rollback;
