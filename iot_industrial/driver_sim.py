import requests
import time
import random

# ─── CONFIGURACIÓN ───────────────────────────────────────────────
API_URL_LOGIN  = "http://localhost:8000/token"
API_URL_ALERTA = "http://localhost:8000/alertas/"

USUARIO    = "admin"
CONTRASENA = "safedriver123"

# ID del conductor y vehículo que deben existir en la DB
CONDUCTOR_ID = 1
VEHICULO_ID  = 1

INTERVALO_NORMAL    = 3   # segundos en modo normal
INTERVALO_CRITICO   = 1   # segundos en modo emergencia

# ─── UMBRALES DE FATIGA ──────────────────────────────────────────
# nivel_fatiga: 0.0 (despierto) → 1.0 (dormido)
# frecuencia_parpadeo: normal ~15-20/min, fatiga <8/min
# velocidad: alerta si supera 90 km/h con fatiga detectada

UMBRAL_FATIGA_ALERTA  = 0.5
UMBRAL_FATIGA_CRITICO = 0.75
UMBRAL_VELOCIDAD      = 90.0


# ─── FUNCIONES DE SIMULACIÓN ─────────────────────────────────────

def obtener_token() -> str:
    """Hace login en el backend y retorna el JWT."""
    print("🔐 Autenticando con el backend SafeDriver...")
    try:
        resp = requests.post(
            API_URL_LOGIN,
            data={"username": USUARIO, "password": CONTRASENA},
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        if resp.status_code == 200:
            token = resp.json()["access_token"]
            print("✅ Token JWT obtenido correctamente.\n")
            return token
        else:
            print(f"❌ Error de login: {resp.status_code} — {resp.text}")
            exit(1)
    except Exception as e:
        print(f"[CRÍTICO] No hay conexión con el backend: {e}")
        exit(1)


def leer_sensores_cabina() -> dict:
    """
    Simula los sensores de visión artificial y GPS del vehículo.
    Retorna un diccionario con las lecturas del momento.
    """
    # Parpadeo: normal 15-20/min. Fatiga baja esto a <8
    frecuencia_parpadeo = round(random.uniform(3.0, 22.0), 1)

    # Nivel de fatiga derivado del parpadeo + algo de ruido
    # Cuanto menos parpadea, más fatigado
    base_fatiga = max(0.0, (12.0 - frecuencia_parpadeo) / 12.0)
    nivel_fatiga = round(min(1.0, base_fatiga + random.uniform(-0.05, 0.1)), 2)

    # Velocidad: entre 40 y 110 km/h
    velocidad_kmh = round(random.uniform(40.0, 110.0), 1)

    return {
        "frecuencia_parpadeo": frecuencia_parpadeo,
        "nivel_fatiga": nivel_fatiga,
        "velocidad_kmh": velocidad_kmh,
    }


def clasificar_alerta(sensores: dict) -> tuple[str, str]:
    """
    Determina el nivel y tipo de alerta según las lecturas del sensor.
    Retorna (nivel, tipo_alerta).
    """
    f = sensores["nivel_fatiga"]
    v = sensores["velocidad_kmh"]

    if f >= UMBRAL_FATIGA_CRITICO or (f >= UMBRAL_FATIGA_ALERTA and v > UMBRAL_VELOCIDAD):
        return "CRITICO", "SUEÑO_DETECTADO"
    elif f >= UMBRAL_FATIGA_ALERTA or v > UMBRAL_VELOCIDAD:
        return "ALERTA", "FATIGA_TEMPRANA"
    else:
        return "NORMAL", "MONITOREO"


def enviar_alerta(token: str, sensores: dict, nivel: str, tipo: str) -> bool:
    """Envía la alerta al endpoint /alertas/ del backend."""
    payload = {
        "conductor_id": CONDUCTOR_ID,
        "vehiculo_id":  VEHICULO_ID,
        "nivel":        nivel,
        "tipo":         tipo,
        "descripcion":  (
            f"Fatiga={sensores['nivel_fatiga']} | "
            f"Parpadeo={sensores['frecuencia_parpadeo']}/min | "
            f"Velocidad={sensores['velocidad_kmh']} km/h"
        )
    }
    headers = {"Authorization": f"Bearer {token}"}

    try:
        resp = requests.post(API_URL_ALERTA, json=payload, headers=headers)
        return resp.status_code in (200, 201)
    except Exception as e:
        print(f"[CRÍTICO] Sin conexión con el backend: {e}")
        return False


# ─── LOOP PRINCIPAL ──────────────────────────────────────────────

def iniciar_simulacion():
    print("=" * 55)
    print("   🚛  SafeDriver — Simulador IoT de Cabina  🚛")
    print("=" * 55)

    token = obtener_token()
    ciclo = 0

    while True:
        ciclo += 1
        sensores = leer_sensores_cabina()
        nivel, tipo = clasificar_alerta(sensores)

        # Mostrar lectura en consola
        icono = {"NORMAL": "🟢", "ALERTA": "🟡", "CRITICO": "🔴"}[nivel]
        print(f"[Ciclo {ciclo:04d}] {icono} {nivel:7s} | "
              f"Fatiga={sensores['nivel_fatiga']:.2f} | "
              f"Parpadeo={sensores['frecuencia_parpadeo']:5.1f}/min | "
              f"Vel={sensores['velocidad_kmh']:5.1f} km/h")

        if nivel == "CRITICO":
            print(f"           ⚠️  [ALERTA] {tipo} — enviando al backend...")

        # Enviar solo si no es NORMAL (para no saturar la DB en modo demo)
        # Cambia a `True` si quieres registrar todos los ciclos
        if nivel != "NORMAL":
            ok = enviar_alerta(token, sensores, nivel, tipo)
            status = "✅ Registrado" if ok else "❌ Falló"
            print(f"           {status} en backend.")

        # Frecuencia dinámica: emergencia → más rápido
        intervalo = INTERVALO_CRITICO if nivel == "CRITICO" else INTERVALO_NORMAL
        time.sleep(intervalo)


if __name__ == "__main__":
    iniciar_simulacion()