-- ==============================================================================
-- 001_esquema.sql
-- subscription-gate: Esquema inicial de tablas, RLS y triggers automáticos
-- ==============================================================================

-- 1. Tabla de administradores
-- Contiene los UUID de los usuarios de auth.users que tienen rol de administrador.
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

comment on table public.admins is 'Usuarios con permisos para administrar licencias y renovaciones';

-- Función para verificar si el usuario actual autenticado es administrador
create or replace function public.es_admin()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

comment on function public.es_admin() is 'Devuelve true si el usuario de la sesión actual está en la tabla admins';

-- 2. Tabla de licencias
-- Registra el estado de la suscripción, fecha de expiración y el hardware_id vinculado
create table if not exists public.licencias (
  usuario_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  fecha_fin timestamptz not null,
  hardware_id varchar(64),
  bloqueada boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.licencias is 'Registro de licencias por usuario, control de vencimiento y equipo vinculado';

-- 3. Activar Row Level Security (RLS) en ambas tablas
alter table public.admins enable row level security;
alter table public.licencias enable row level security;

-- 4. Políticas de Seguridad (RLS) para public.licencias
-- El usuario final autenticado SOLO puede consultar (SELECT) su propia fila de licencia o los administradores
create policy licencia_propia on public.licencias for select
  using (usuario_id = auth.uid() or public.es_admin());

-- Los administradores tienen acceso total para gestionar todas las licencias
create policy licencias_admin on public.licencias for all
  using (public.es_admin()) with check (public.es_admin());

-- Nota de seguridad para public.admins:
-- Al activar RLS y no definir políticas para clientes anon/authenticated,
-- ninguna consulta REST directa puede leer o escribir en public.admins.

-- 5. Trigger automático al crear un usuario en Supabase Auth
-- Cada vez que se crea un usuario desde el panel de Supabase Auth,
-- se genera automáticamente su licencia de prueba inicial (30 días).
create or replace function public.al_crear_usuario()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.licencias (usuario_id, email, fecha_fin)
  values (new.id, new.email, now() + interval '30 days');
  return new;
end $$;

-- Evitar duplicados del trigger si se reejecuta
drop trigger if exists crear_licencia_al_crear_usuario on auth.users;
create trigger crear_licencia_al_crear_usuario
  after insert on auth.users
  for each row execute function public.al_crear_usuario();
