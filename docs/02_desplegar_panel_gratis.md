# 02. Desplegar el Panel Web a Costo Cero

El panel de administración (`admin-web`) es una Single Page Application (SPA) construida con Vue 3 y Vite. Puedes alojarla **completamente gratis** en plataformas como Cloudflare Pages, Vercel, Netlify o GitHub Pages.

---

## 1. Parámetros de Configuración del Proyecto

Independientemente del proveedor que elijas, los parámetros de compilación de `admin-web` son:

| Parámetro | Valor |
|---|---|
| **Root directory (Directorio raíz)** | `admin-web` |
| **Build command (Comando de compilación)** | `npm run build` |
| **Output directory (Directorio de salida)** | `dist` |
| **Node.js Version** | `18+` o `20+` |

### Variables de Entorno Requeridas
En el panel de configuración de tu hosting, define las siguientes variables de entorno:

```ini
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-anon-key-publica-aqui
```

> [!NOTE]
> Estas variables tienen el prefijo `VITE_`, por lo que Vite las incrustará en el código compilado del frontend. Al ser la `anon key` protegida por las políticas RLS de Supabase, es seguro exponerla públicamente en el navegador.

---

## 2. Opciones de Despliegue Gratuito

### Opción A: Cloudflare Pages (Recomendada)
Cloudflare Pages ofrece ancho de banda ilimitado y despliegues automáticos desde GitHub en su plan gratuito.

1. Inicia sesión en [Cloudflare Dashboard](https://dash.cloudflare.com/) y ve a **Workers & Pages** &rarr; **Create application** &rarr; **Pages** &rarr; **Connect to Git**.
2. Selecciona tu repositorio `subscription-gate`.
3. Configura el build:
   - **Framework preset:** `Vite`
   - **Root directory:** `admin-web`
   - **Build command:** `npm run build`
   - **Build output directory:** `dist`
4. En **Environment variables**, agrega `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
5. Haz clic en **Save and Deploy**.
6. **Regla de enrutamiento SPA:** Cloudflare Pages maneja automáticamente las rutas de Vite si detecta el framework preset. De forma complementaria, puedes incluir un archivo `admin-web/public/_redirects` con el contenido:
   ```
   /* /index.html 200
   ```

---

### Opción B: Vercel
1. Ve a [vercel.com](https://vercel.com) e inicia sesión con GitHub.
2. Haz clic en **"Add New..."** &rarr; **"Project"** e importa `subscription-gate`.
3. En la sección **Root Directory**, haz clic en **Edit** y selecciona la carpeta `admin-web`.
4. En **Environment Variables**, añade:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. Haz clic en **Deploy**.
6. Para asegurar que rutas directas como `/usuarios` o `/login` no den error 404 al recargar, Vercel requiere un archivo `vercel.json` en `admin-web`:
   ```json
   {
     "rewrites": [{ "source": "/(.*)", "destination": "/" }]
   }
   ```

---

### Opción C: Netlify
1. Ve a [netlify.com](https://www.netlify.com/) e inicia sesión con GitHub.
2. Haz clic en **"Add new site"** &rarr; **"Import an existing project"**.
3. Selecciona tu repositorio.
4. Configuración:
   - **Base directory:** `admin-web`
   - **Build command:** `npm run build`
   - **Publish directory:** `admin-web/dist`
5. En **Site configuration** &rarr; **Environment variables**, agrega las variables `VITE_*`.
6. En `admin-web/public/_redirects`, añade la regla de reescritura SPA:
   ```
   /*    /index.html   200
   ```

---

## 3. Comprobación Post-Despliegue

1. Abre la URL pública generada por tu proveedor (ej. `https://mi-software.pages.dev`).
2. Deberías ver la **Landing Page promocional** en la raíz (`/`) con la presentación de la app, características, pasos de uso y preguntas frecuentes.
3. Haz clic en el botón **"Acceso Admin"** en la esquina superior derecha (o navega a `/login`) para acceder al inicio de sesión de administración.
4. Ingresa con las credenciales del usuario administrador que configuraste en Supabase.
5. Comprueba que eres redirigido a `/usuarios` y puedes visualizar la tabla de licencias y estadísticas.
6. Intenta recargar la página directamente en la ruta `/usuarios` para verificar que la regla de reescritura SPA funciona sin devolver error 404.
