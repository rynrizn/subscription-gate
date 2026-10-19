# Política de Seguridad | Security Policy

Este documento detalla el modelo de amenazas, las garantías de seguridad que ofrece `subscription-gate`, sus límites conocidos y las recomendaciones para endurecerlo antes de pasar a entornos de producción comercial.

---

## 1. Qué Protege esta Plantilla

- **Protección a nivel de base de datos con Row Level Security (RLS):**
  Un usuario autenticado solo puede ejecutar `SELECT` sobre su propia fila en `public.licencias`. Tiene completamente denegados los permisos de `INSERT`, `UPDATE` y `DELETE`.
- **Reloj autoritativo en el servidor:**
  La expiración de la licencia se calcula exclusivamente con la hora de PostgreSQL (`now()`). Cualquier intento del usuario de manipular el reloj local de su sistema operativo no tiene ningún impacto en el servidor.
- **Vínculo unívoco de hardware (1 equipo por licencia):**
  En el primer inicio de sesión, el hash del equipo se asocia de forma permanente al usuario. Cualquier intento de validación desde una máquina diferente es rechazado con el código `HARDWARE_NO_COINCIDE`.
- **Funciones seguras con contexto restringido:**
  Todas las funciones `SECURITY DEFINER` declaran explícitamente `SET search_path = public`, neutralizando vulnerabilidades de inyección de rutas en PostgreSQL.
- **Principio de mínimo privilegio para `anon`:**
  Todos los permisos de ejecución en funciones RPC de validación y administración están revocados para el rol público y anónimo.
- **Aislamiento de privilegios administrativos:**
  Las funciones de renovación, reseteo de equipo y bloqueo comprueban la presencia del UID en la tabla `public.admins` antes de ejecutar cualquier cambio.

---

## 2. Qué NO Protege (Límites y Modelo de Amenazas)

> [!WARNING]
> Ningún sistema de licencias cliente-servidor puede garantizar inmunidad contra un usuario con acceso físico completo a su ordenador y conocimientos avanzados de ingeniería inversa.

Esta plantilla didáctica **no cubre por sí sola**:

1. **Parcheo o modificación de binarios en el cliente:**
   Si distribuyes tu aplicación en Python puro o sin ofuscación/empaquetado seguro, un atacante puede alterar la condición `if not autorizado: exit()` directamente en el código de la aplicación cliente.
2. **Uso sin conexión a internet (Modo Offline):**
   La función `validar_acceso` requiere conectividad con Supabase. Sin conexión a internet, el cliente no puede verificar el estado de la suscripción.
3. **Clonación de entornos virtuales:**
   Si un usuario clona una máquina virtual completa (disco, MAC, GUID del sistema), ambas instancias generarán el mismo `hardware_id`.
4. **Intercepción de tráfico si se ignoran certificados TLS:**
   El cliente debe verificar siempre los certificados TLS/SSL para evitar ataques de tipo Man-in-the-Middle (MitM).

---

## 3. Siguientes Pasos de Endurecimiento (Hacia Producción)

Si planeas utilizar esta arquitectura como base para un producto comercial, se recomienda implementar los siguientes pasos de endurecimiento:

- **Tokens firmados con validez temporal y soporte offline:**
  Emitir un token criptográfico (JWT firmado con una clave privada asimétrica Ed25519 o RSA en una Edge Function) que contenga la fecha de expiración y el hardware_id, permitiendo que la aplicación trabaje sin conexión durante un período de gracia (ej. 48 o 72 horas).
- **Múltiples dispositivos por cuenta:**
  Crear una tabla relacional `licencia_dispositivos (id, usuario_id, hardware_id, nombre_dispositivo, created_at)` con un límite máximo (ej. 3 dispositivos por usuario).
- **Límite de tasa y detección de anomalías (Rate Limiting):**
  Configurar límites de peticiones para evitar ataques de fuerza bruta en los endpoints de autenticación y RPC.
- **Tabla de auditoría:**
  Registrar los eventos de validación (`ip`, `hardware_id`, `timestamp`, `resultado`) para detectar comportamientos inusuales o licencias compartidas indebidamente.
- **Autenticación en dos pasos (2FA/MFA):**
  Activar 2FA obligatorio en Supabase Auth para todos los usuarios con rol de administrador.
- **Automatización de altas y pagos con Edge Functions:**
  Procesar webhooks de pasarelas de pago (Stripe, Lemon Squeezy, Mercado Pago) mediante Supabase Edge Functions para crear o renovar usuarios de manera automatizada y segura.

---

## 4. Reporte Responsable de Vulnerabilidades

Si descubres una vulnerabilidad de seguridad en esta plantilla:
- **No** abras un issue público.
- Utiliza la función de **GitHub Private Vulnerability Reporting** en la pestaña de Seguridad del repositorio, o contacta de forma privada con los mantenedores.
- Proporciona una descripción detallada del problema, los pasos para reproducirlo y el impacto potencial.

---

> [!NOTE]
> *Aviso:* Esta plantilla se entrega con propósitos didácticos y de referencia. Revisa, prueba y adapta los parámetros según los requisitos de seguridad específicos de tu proyecto.
