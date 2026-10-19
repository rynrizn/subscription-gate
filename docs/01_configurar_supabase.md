# 01. Configurar Supabase paso a paso

Esta guía te explica cómo preparar tu proyecto en Supabase (100% en el plan gratuito) para que funcione con `subscription-gate`.

---

## 1. Crear un proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) e inicia sesión con tu cuenta de GitHub.
2. Haz clic en **"New project"**.
3. Selecciona tu organización y completa:
   - **Name:** `mi-app-licencias` (o el nombre que elijas).
   - **Database Password:** Elige una contraseña segura y guárdala en tu gestor de contraseñas.
   - **Region:** Selecciona la región geográfica más cercana a tus usuarios (ej. *Frankfurt*, *São Paulo*, *East US*).
   - **Pricing Plan:** Elige **Free Plan** ($0/mes).
4. Haz clic en **"Create new project"** y espera ~2 minutos a que el aprovisionamiento de PostgreSQL termine.

---

## 2. Desactivar el registro público (Signups)

> [!IMPORTANT]
> **Paso Crítico de Seguridad:** Si dejas los registros públicos activados, cualquier persona con tu `anon key` podría registrarse y obtener una licencia de prueba de 30 días ilimitadamente.

1. En la consola de Supabase, ve al menú lateral izquierdo: **Authentication** &rarr; **Configuration** (o **Providers** / **Email** según la versión).
2. Localiza la sección de configuración de correo (**Email Auth Provider**).
3. Busca la opción **"Enable Signups"** y **desactívala (OFF)**.
4. Guarda los cambios (**Save**).

A partir de este momento, solo tú (o tu sistema backend) podrás dar de alta usuarios desde la consola administrativa de Supabase.

---

## 3. Ejecutar las migraciones SQL

Ve al menú **SQL Editor** en el panel izquierdo de Supabase y ejecuta los archivos de migración en el orden exacto:

### Paso 3.1: Ejecutar `001_esquema.sql`
1. Haz clic en **"New query"**.
2. Copia todo el contenido de [`supabase/migrations/001_esquema.sql`](../supabase/migrations/001_esquema.sql).
3. Pégalo en el editor y haz clic en **"Run"**.
4. Verás el mensaje *"Success. No rows returned"*. Esto habrá creado:
   - Tabla `public.admins`
   - Tabla `public.licencias`
   - Row Level Security (RLS) y sus políticas
   - El trigger `crear_licencia_al_crear_usuario`

### Paso 3.2: Ejecutar `002_funciones.sql`
1. Haz clic en **"New query"**.
2. Copia el contenido de [`supabase/migrations/002_funciones.sql`](../supabase/migrations/002_funciones.sql).
3. Pégalo en el editor y haz clic en **"Run"**.
4. Esto creará:
   - La función `public.validar_acceso(p_hardware_id)`
   - Las funciones administrativas `admin_renovar`, `admin_reset_hardware` y `admin_bloquear`
   - Los permisos de ejecución restringidos (revocados a `anon`, otorgados a `authenticated`)

---

## 4. Crear tu primer usuario Administrador

1. Ve a **Authentication** &rarr; **Users** en el menú de Supabase.
2. Haz clic en el botón verde **"Add user"** &rarr; **"Create user"**.
3. Ingresa tu correo electrónico (ej. `admin@tudominio.com`) y una contraseña fuerte.
4. Haz clic en **"Create user"**.
5. En la lista de usuarios, localiza la columna **"User UID"** de tu usuario recién creado y cópiala (es un UUID con formato `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
6. Vuelve a **SQL Editor**, crea una nueva consulta y ejecuta lo siguiente (reemplazando con tu UID real):

```sql
INSERT INTO public.admins (user_id)
VALUES ('tu-uuid-aqui');
```

7. Para confirmar que quedó registrado como administrador, ejecuta:
```sql
SELECT * FROM public.admins;
```

---

## 5. Dónde obtener tus credenciales (y advertencia de seguridad)

Ve a **Project Settings** (icono de engranaje) &rarr; **API**:

- **Project URL:** Tu URL con formato `https://xxxxxxxxxxxxxxxxxxxx.supabase.co`.
- **Project API Keys:**
  - `anon` / `public`: **Esta es la clave que debes usar** en tu panel web (`VITE_SUPABASE_ANON_KEY`) y en el cliente de escritorio. Es segura para incluir en aplicaciones cliente porque la base de datos está protegida con RLS.

> [!CAUTION]
> **NUNCA utilices ni reveles la clave `service_role`:**
> La clave `service_role` se salta todas las políticas de Row Level Security (RLS) y otorga acceso total de lectura y escritura a cualquier dato de tu base de datos.
> **Bajo ninguna circunstancia** debes colocar la `service_role` en el panel web, en el cliente de escritorio, ni subirla a repositorios de código. `subscription-gate` está diseñada para funcionar de forma 100% segura usando únicamente la `anon key`.
