# Guía de Publicación del Repositorio (Checklist para el Mantenedor)

> **Nota:** Este documento es una guía interna para el creador/mantenedor del repositorio al momento de publicarlo en GitHub. No es necesario mantenerlo si prefieres eliminarlo antes o después del lanzamiento.

---

## 1. Configuración del Repositorio en GitHub

### 1.1. Marcar como Plantilla (Template Repository)
1. Entra a tu repositorio en GitHub: `https://github.com/<TU_USUARIO>/subscription-gate`.
2. Ve a la pestaña **Settings** (Configuración) &rarr; **General**.
3. En la primera sección, marca la casilla:
   - [x] **Template repository** *(permite que otros desarrolladores hagan clic en "Use this template" para generar su propio repositorio a partir de este).*

---

### 1.2. Descripción y Sitio Web
En la página principal del repositorio, haz clic en el icono de engranaje (⚙️) junto a **About**:

- **Description (Sugerida en español):**
  > Plantilla didáctica y segura para añadir login, suscripción con vencimiento y amarre a un equipo a aplicaciones de escritorio con costo $0 (Supabase + Vue 3).
- **Description (Alternativa en inglés):**
  > Free & secure educational template for desktop licensing: Supabase Auth, PostgreSQL RLS, hardware binding, and a Vue 3 admin panel.
- **Website:** La URL de demostración o de tu panel desplegado en Cloudflare Pages / Vercel (si lo deseas).

---

### 1.3. Topics (Etiquetas) Recomendadas
Añade las siguientes etiquetas para optimizar la visibilidad en el buscador de GitHub:

```text
supabase
licensing
subscription
vue
tailwindcss
desktop-app
python
rls
postgresql
template
software-licensing
hardware-id
```

---

## 2. Crear la Primera Release (`v1.0.0`)

1. En la barra lateral derecha de la página principal del repositorio, haz clic en **Releases** &rarr; **Create a new release** (o **Draft a new release**).
2. **Tag version:** `v1.0.0` (crear nuevo tag al publicar sobre la rama `main`).
3. **Release title:** `subscription-gate v1.0.0 - Versión Inicial Estable`
4. **Release notes:** Puedes copiar el siguiente resumen:

```markdown
### 🚀 subscription-gate v1.0.0

Primera versión pública de la plantilla didáctica y segura para añadir autenticación, control de suscripciones y amarre de hardware a aplicaciones de escritorio con costo $0.

#### ✨ Características incluidas
- **Base de Datos & Seguridad:**
  - Esquema completo de tablas `admins` y `licencias`.
  - Row Level Security (RLS) estricta: usuarios solo leen su propia licencia.
  - Funciones RPC con reloj autoritativo en servidor PostgreSQL (`validar_acceso`, `admin_renovar`, `admin_reset_hardware`, `admin_bloquear`).
  - Suite de pruebas de seguridad SQL (`supabase/tests/rls.sql`).
- **Panel Web de Administración (`admin-web`):**
  - Desarrollado con Vue 3 (`<script setup>`), Vite, Vue Router y Tailwind CSS.
  - Diseño minimalista y profesional en modo oscuro (OLED #09090b).
  - Métricas en tiempo real (vigentes, por vencer, vencidas, bloqueadas).
  - Interfaz 100% responsiva (gestión completa desde el celular y escritorio).
- **Cliente de Escritorio Didáctico (`client-python`):**
  - Implementación con `httpx` comentada línea por línea.
  - Identificación multiplataforma de hardware (Windows, macOS, Linux).
  - Traducción y explicación amigable de todos los estados y motivos de rechazo.
- **Documentación Completa:**
  - Inicio rápido en 6 pasos y arquitectura en diagrama Mermaid.
  - Guías detalladas: configuración de Supabase, despliegue a costo 0 e integración genérica en cualquier app.
  - Política de seguridad (`SECURITY.md`) y Licencia MIT.
```

5. Haz clic en **Publish release**.

---

## 3. Verificaciones Finales

- [ ] Repositorio configurado como **Public**.
- [ ] No hay archivos `.env` con credenciales reales subidos en los commits.
- [ ] `.gitignore` previene la subida accidental de secretos, node_modules y certificados.
- [ ] La compilación del panel (`npm run build`) y el cliente Python ejecutan sin errores.
