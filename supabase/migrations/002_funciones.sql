-- ==============================================================================
-- 002_funciones.sql
-- subscription-gate: Funciones RPC de validación y administración
-- ==============================================================================

-- 1. Función para validar acceso desde el cliente de escritorio
-- Comprueba el estado de la suscripción, verifica el vínculo con el hardware_id
-- y utiliza el reloj de PostgreSQL en el servidor para evitar manipulaciones locales.
create or replace function public.validar_acceso(p_hardware_id text)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_lic public.licencias%rowtype;
begin
  -- 1.1. Verificar que la petición provenga de una sesión autenticada
  if v_uid is null then
    return jsonb_build_object('autorizado', false, 'motivo', 'NO_AUTENTICADO');
  end if;

  -- 1.2. Verificar formato del identificador de hardware (debe ser un hash SHA-256 de 64 caracteres)
  if p_hardware_id is null or length(p_hardware_id) <> 64 then
    return jsonb_build_object('autorizado', false, 'motivo', 'HARDWARE_INVALIDO');
  end if;

  -- 1.3. Buscar la licencia del usuario bloqueando la fila para evitar condiciones de carrera
  select * into v_lic from public.licencias where usuario_id = v_uid for update;
  if not found then
    return jsonb_build_object('autorizado', false, 'motivo', 'SIN_LICENCIA');
  end if;

  -- 1.4. Validar si la cuenta se encuentra administrativamente bloqueada
  if v_lic.bloqueada then
    return jsonb_build_object('autorizado', false, 'motivo', 'CUENTA_BLOQUEADA');
  end if;

  -- 1.5. Validar fecha de expiración comparada contra el reloj del servidor
  if v_lic.fecha_fin <= now() then
    return jsonb_build_object(
      'autorizado', false,
      'motivo', 'LICENCIA_EXPIRADA',
      'expira_en', v_lic.fecha_fin
    );
  end if;

  -- 1.6. Comprobación y vínculo de hardware
  if v_lic.hardware_id is null then
    -- Primer uso: se vincula automáticamente al equipo actual
    update public.licencias set hardware_id = p_hardware_id where usuario_id = v_uid;
  elsif v_lic.hardware_id <> p_hardware_id then
    -- El equipo actual no coincide con el equipo registrado
    return jsonb_build_object('autorizado', false, 'motivo', 'HARDWARE_NO_COINCIDE');
  end if;

  -- 1.7. Acceso autorizado exitosamente
  return jsonb_build_object(
    'autorizado', true,
    'motivo', 'OK',
    'dias_restantes', greatest(0, ceil(extract(epoch from (v_lic.fecha_fin - now())) / 86400))::int,
    'expira_en', v_lic.fecha_fin
  );
end $$;

comment on function public.validar_acceso(text) is 'Valida la licencia del usuario actual y vincula/compara el hardware_id';


-- 2. Funciones administrativas (requieren pertenecer a public.admins)

-- 2.1. Renovar licencia: agrega días a partir de la fecha actual o la fecha_fin vigente
create or replace function public.admin_renovar(p_usuario uuid, p_dias int)
returns timestamptz language plpgsql security definer
set search_path = public as $$
declare
  v_nueva timestamptz;
begin
  if not public.es_admin() then
    raise exception 'NO_AUTORIZADO';
  end if;

  -- Si la licencia ya venció, suma desde now(); si sigue vigente, extiende desde fecha_fin
  update public.licencias
     set fecha_fin = greatest(fecha_fin, now()) + make_interval(days => p_dias)
   where usuario_id = p_usuario
  returning fecha_fin into v_nueva;

  return v_nueva;
end $$;

comment on function public.admin_renovar(uuid, int) is 'Extiende la vigencia de una licencia sumando días a la fecha correspondiente';

-- 2.2. Resetear hardware: permite desvincular el equipo actual para permitir cambio de máquina
create or replace function public.admin_reset_hardware(p_usuario uuid)
returns void language plpgsql security definer
set search_path = public as $$
begin
  if not public.es_admin() then
    raise exception 'NO_AUTORIZADO';
  end if;

  update public.licencias
     set hardware_id = null
   where usuario_id = p_usuario;
end $$;

comment on function public.admin_reset_hardware(uuid) is 'Desvincula el hardware_id actual de un usuario para que pueda registrar otro';

-- 2.3. Bloquear o desbloquear cuenta de usuario
create or replace function public.admin_bloquear(p_usuario uuid, p_bloquear boolean)
returns void language plpgsql security definer
set search_path = public as $$
begin
  if not public.es_admin() then
    raise exception 'NO_AUTORIZADO';
  end if;

  update public.licencias
     set bloqueada = p_bloquear
   where usuario_id = p_usuario;
end $$;

comment on function public.admin_bloquear(uuid, boolean) is 'Bloquea o desbloquea administrativamente el acceso a una licencia';


-- 3. Permisos de Ejecución (Principio de mínimo privilegio)
-- Revocar ejecución a usuarios anónimos (anon) y rol público
revoke execute on function public.validar_acceso(text) from public, anon;
revoke execute on function public.admin_renovar(uuid, int) from public, anon;
revoke execute on function public.admin_reset_hardware(uuid) from public, anon;
revoke execute on function public.admin_bloquear(uuid, boolean) from public, anon;

-- Otorgar ejecución a usuarios autenticados (las funciones administrativas verifican internamente es_admin())
grant execute on function public.validar_acceso(text) to authenticated;
grant execute on function public.admin_renovar(uuid, int) to authenticated;
grant execute on function public.admin_reset_hardware(uuid) to authenticated;
grant execute on function public.admin_bloquear(uuid, boolean) to authenticated;
