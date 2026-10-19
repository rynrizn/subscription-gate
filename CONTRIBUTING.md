# Guía de Contribución | Contributing Guide

¡Gracias por tu interés en colaborar con **`subscription-gate`**! Este proyecto busca ser la mejor plantilla didáctica, abierta y segura para implementar autenticación y control de licencias con costo cero.

---

## 1. Principios del Repositorio

Toda contribución debe respetar los siguientes principios rectores:

1. **Cero Secretos y Repositorio Público:** Ninguna contribución puede contener claves reales de Supabase (`service_role`, credenciales de bases de datos de producción), URLs de proyectos privados ni datos personales.
2. **Costo Cero ($0):** Las soluciones deben mantenerse dentro del plan gratuito de Supabase, hosting estático gratuito y librerías de código abierto.
3. **Simplicidad y Didáctica:** El código debe ser limpio, con dependencias mínimas y con comentarios explicativos en español para que desarrolladores de cualquier nivel puedan aprender y adaptarlo.
4. **Seguridad por Diseño:** Cualquier cambio en la base de datos debe incluir políticas de RLS adecuadas y el principio de mínimo privilegio.

---

## 2. Cómo Contribuir

1. Haz un **Fork** del repositorio.
2. Crea una rama para tu funcionalidad o corrección:
   ```bash
   git checkout -b feat/mi-mejora
   ```
3. Realiza tus cambios asegurándote de:
   - Probar la compilación del panel web:
     ```bash
     cd admin-web && npm run build
     ```
   - Comprobar la sintaxis del cliente Python:
     ```bash
     python -m py_compile client-python/ejemplo_cliente.py
     ```
   - Actualizar la suite `supabase/tests/rls.sql` si agregas nuevas reglas en PostgreSQL.
4. Realiza commits pequeños y descriptivos siguiendo la convención de [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` Nuevas características
   - `fix:` Corrección de errores
   - `docs:` Cambios en la documentación
   - `refactor:` Mejoras en el código sin cambiar comportamiento
   - `test:` Pruebas unitarias o de RLS
5. Abre un **Pull Request** explicando detalladamente el cambio y el problema que resuelve.

---

## 3. Código de Conducta

Por favor mantén un ambiente colaborativo, constructivo y respetuoso para toda la comunidad.
