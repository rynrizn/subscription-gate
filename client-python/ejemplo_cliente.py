#!/usr/bin/env python3
"""
==============================================================================
subscription-gate | Cliente de Ejemplo en Python
==============================================================================

Propósito:
Demostrar el flujo completo de autenticación y validación de suscripción
para una aplicación de escritorio conectada a Supabase:
  1. Identificación del hardware del equipo (hash único y persistente).
  2. Inicio de sesión con correo y contraseña contra Supabase Auth.
  3. Validación de acceso mediante la función RPC segura 'validar_acceso'.
  4. Interpretación clara de motivos de aceptación o rechazo.

AVISO EDUCATIVO Y DE SEGURIDAD:
- Este script es una demostración educativa. En una aplicación de escritorio
  distribuida en producción, cualquier script o ejecutable Python puede ser
  desensamblado o modificado localmente por un usuario con conocimientos técnicos.
- La sal ("CAMBIA-ESTA-SAL") debe ser única para tu aplicación.
- Consulta SECURITY.md para conocer cómo endurecer tu aplicación.
==============================================================================
"""

import getpass
import hashlib
import os
import platform
import subprocess
import sys
import httpx

# ============================================================================
# 1. Función para calcular el identificador del equipo (Hardware ID)
# ============================================================================
def id_equipo(sal: str = "CAMBIA-ESTA-SAL") -> str:
    """
    Devuelve un hash estable y único del equipo (SHA-256 en hexadecimal de 64 caracteres).

    Estrategia multiplataforma:
    - Windows: Lee 'MachineGuid' del Registro de Windows (HKLM\\SOFTWARE\\Microsoft\\Cryptography).
    - macOS: Lee el 'IOPlatformUUID' mediante el comando nativo del sistema 'ioreg'.
    - Linux: Lee el identificador persistente del sistema en '/etc/machine-id'
      o '/var/lib/dbus/machine-id'.
    - En caso de fallo o permisos restringidos, recurre a identificadores del sistema base.
    """
    base = ""

    try:
        if sys.platform == "win32":
            # Lectura del Registro de Windows utilizando la biblioteca estándar winreg
            import winreg
            clave = winreg.OpenKey(
                winreg.HKEY_LOCAL_MACHINE,
                r"SOFTWARE\Microsoft\Cryptography",
                0,
                winreg.KEY_READ | winreg.KEY_WOW64_64KEY
            )
            base = winreg.QueryValueEx(clave, "MachineGuid")[0]
            winreg.CloseKey(clave)

        elif sys.platform == "darwin":
            # macOS: Ejecutar comando seguro ioreg para obtener el UUID de la placa base
            salida = subprocess.run(
                ["ioreg", "-rd1", "-c", "IOPlatformExpertDevice"],
                capture_output=True,
                text=True,
                check=True
            ).stdout
            for linea in salida.splitlines():
                if "IOPlatformUUID" in linea:
                    base = linea.split('"')[-2]
                    break

        else:
            # Linux: Leer el machine-id estándar del sistema operativo
            for ruta in ("/etc/machine-id", "/var/lib/dbus/machine-id"):
                try:
                    with open(ruta, "r", encoding="utf-8") as f:
                        base = f.read().strip()
                        if base:
                            break
                except OSError:
                    continue

    except Exception as err:
        # Registro silencioso o depuración si no se pudo leer el hardware específico
        base = ""

    # Si por alguna restricción de permisos no se obtuvo el identificador primario,
    # se utiliza información del procesador y nodo de red como alternativa de respaldo
    if not base:
        base = f"fallback-{platform.node()}-{platform.processor()}-{platform.machine()}"

    # Combinamos la base del equipo con el nombre de red y la sal secreta de la app
    cadena_combinada = f"{base}|{platform.node()}|{sal}"

    # Generamos un hash SHA-256 estricto (exactamente 64 caracteres hexadecimales)
    return hashlib.sha256(cadena_combinada.encode("utf-8")).hexdigest()


# ============================================================================
# 2. Funciones de comunicación con Supabase (Auth y RPC)
# ============================================================================
def iniciar_sesion(url_supabase: str, anon_key: str, email: str, password: str) -> str:
    """
    Autentica al usuario contra Supabase Auth usando el endpoint REST estándar.
    Retorna el 'access_token' (JWT) si las credenciales son válidas.
    """
    endpoint = f"{url_supabase.rstrip('/')}/auth/v1/token?grant_type=password"
    cabeceras = {
        "apikey": anon_key,
        "Content-Type": "application/json",
    }
    cuerpo = {
        "email": email,
        "password": password,
    }

    with httpx.Client(timeout=15.0) as cliente:
        respuesta = cliente.post(endpoint, headers=cabeceras, json=cuerpo)

    if respuesta.status_code == 200:
        datos = respuesta.json()
        return datos.get("access_token", "")
    elif respuesta.status_code == 400:
        datos = respuesta.json()
        error_desc = datos.get("error_description", datos.get("msg", "Credenciales incorrectas"))
        raise PermissionError(f"Error de credenciales: {error_desc}")
    else:
        raise ConnectionError(f"Error al conectar con Supabase Auth (código HTTP {respuesta.status_code})")


def validar_licencia(url_supabase: str, anon_key: str, token_acceso: str, hardware_hash: str) -> dict:
    """
    Invoca la función de PostgreSQL 'validar_acceso' vía RPC.
    Envía el access_token en la cabecera Authorization y el identificador de hardware.
    """
    endpoint = f"{url_supabase.rstrip('/')}/rest/v1/rpc/validar_acceso"
    cabeceras = {
        "apikey": anon_key,
        "Authorization": f"Bearer {token_acceso}",
        "Content-Type": "application/json",
    }
    cuerpo = {
        "p_hardware_id": hardware_hash,
    }

    with httpx.Client(timeout=15.0) as cliente:
        respuesta = cliente.post(endpoint, headers=cabeceras, json=cuerpo)

    if respuesta.status_code == 200:
        return respuesta.json()
    else:
        raise ConnectionError(
            f"Fallo en la llamada RPC validar_acceso: HTTP {respuesta.status_code} - {respuesta.text}"
        )


# ============================================================================
# 3. Flujo principal del cliente
# ============================================================================
def main():
    print("====================================================================")
    print("         subscription-gate | Cliente de Verificación de Acceso       ")
    print("====================================================================\n")

    # Leer configuración desde variables de entorno o solicitar interactivamente
    url_supabase = os.environ.get("SUPABASE_URL", "").strip()
    anon_key = os.environ.get("SUPABASE_ANON_KEY", "").strip()

    if not url_supabase:
        url_supabase = input("Ingresa la URL de tu proyecto Supabase (ej. https://xyz.supabase.co): ").strip()
    if not anon_key:
        anon_key = input("Ingresa la Anon / Public Key de Supabase: ").strip()

    if not url_supabase or not anon_key:
        print("\n[ERROR] Debes proporcionar la URL y la Anon Key de Supabase para continuar.")
        sys.exit(1)

    print("\n--- 1. Identificación del Equipo ---")
    hw_id = id_equipo()
    print(f"ID del equipo calculado (SHA-256): {hw_id[:12]}...{hw_id[-8:]} (64 caracteres)")

    print("\n--- 2. Autenticación de Usuario ---")
    email = input("Correo electrónico: ").strip()
    password = getpass.getpass("Contraseña: ")

    if not email or not password:
        print("\n[ERROR] El correo y la contraseña son obligatorios.")
        sys.exit(1)

    # Paso A: Iniciar sesión
    print("\nConectando con Supabase Auth...")
    try:
        token = iniciar_sesion(url_supabase, anon_key, email, password)
        print("✓ Autenticación exitosa.")
    except PermissionError as e:
        print(f"\n[RECHAZADO] {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR DE CONEXIÓN] No fue posible iniciar sesión: {e}")
        sys.exit(1)

    # Paso B: Validar suscripción y equipo
    print("Verificando suscripción y vinculación con la base de datos...")
    try:
        resultado = validar_licencia(url_supabase, anon_key, token, hw_id)
    except Exception as e:
        print(f"\n[ERROR EN SERVIDOR] {e}")
        sys.exit(1)

    # Paso C: Interpretar respuesta del servidor
    autorizado = resultado.get("autorizado", False)
    motivo = resultado.get("motivo", "DESCONOCIDO")

    print("\n====================================================================")
    print("                       RESULTADO DE ACCESO                          ")
    print("====================================================================")

    if autorizado and motivo == "OK":
        dias_restantes = resultado.get("dias_restantes", 0)
        expira_en = resultado.get("expira_en", "Desconocida")
        print(" [ACCESO CONCEDIDO]")
        print(f" Tu suscripción está activa y autorizada para este equipo.")
        print(f" - Días restantes : {dias_restantes} día(s)")
        print(f" - Expira el       : {expira_en}")
        print("====================================================================")
        print("Iniciando la aplicación de escritorio...")
        # Aquí se ejecutaría la lógica principal de tu aplicación de escritorio
        sys.exit(0)
    else:
        print(" [ACCESO DENEGADO]")
        print(f" Código de motivo : {motivo}")

        # Mensajes didácticos y comprensibles para el usuario final en español
        if motivo == "HARDWARE_NO_COINCIDE":
            print("\nExplicación:")
            print(" Esta licencia ya se encuentra vinculada a otro ordenador.")
            print(" Si cambiaste de equipo o formateaste tu sistema, contacta al")
            print(" administrador para solicitar el reseteo del equipo vinculado.")

        elif motivo == "LICENCIA_EXPIRADA":
            expira_en = resultado.get("expira_en", "previamente")
            print("\nExplicación:")
            print(f" Tu período de suscripción finalizó el {expira_en}.")
            print(" Por favor contacta al administrador para renovar tu acceso.")

        elif motivo == "CUENTA_BLOQUEADA":
            print("\nExplicación:")
            print(" Tu cuenta ha sido bloqueada administrativamente.")
            print(" Por favor ponte en contacto con soporte técnico.")

        elif motivo == "SIN_LICENCIA":
            print("\nExplicación:")
            print(" No existe un registro de licencia asociado a tu cuenta de usuario.")
            print(" Solicita al administrador que cree tu licencia en el sistema.")

        elif motivo == "HARDWARE_INVALIDO":
            print("\nExplicación:")
            print(" El identificador de hardware enviado no cumple con el formato requerido.")

        elif motivo == "NO_AUTENTICADO":
            print("\nExplicación:")
            print(" La sesión no fue reconocida por el servidor.")

        else:
            print(f"\nExplicación: Respuesta no reconocida ({motivo}).")

        print("====================================================================")
        sys.exit(1)


if __name__ == "__main__":
    main()
