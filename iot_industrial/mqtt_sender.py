import paho.mqtt.client as mqtt
import json
import time
import random
import requests
import os

# ─── CONFIGURACIÓN (desde variables de entorno, con default para uso local) ──
BROKER = os.getenv("MQTT_BROKER", "broker.hivemq.com")
PORT   = int(os.getenv("MQTT_PORT", "1883"))

API_URL_PARES = os.getenv("API_URL_PARES", "http://localhost:8000/iot/conductores-activos")
INTERVALO_REFRESCO_PARES = int(os.getenv("INTERVALO_REFRESCO_PARES", "30"))


def cargar_pares_desde_backend() -> list[dict]:
    """Consulta al backend los pares (conductor_id, vehiculo_id) registrados."""
    try:
        resp = requests.get(API_URL_PARES, timeout=5)
        if resp.status_code == 200:
            pares = resp.json()
            print(f"✅ Pares cargados desde backend: {pares}")
            return pares
        else:
            print(f"⚠️  Backend retornó {resp.status_code}. Reintentando en {INTERVALO_REFRESCO_PARES}s...")
            return []
    except Exception as e:
        print(f"⚠️  No se pudo contactar el backend ({API_URL_PARES}): {e}")
        return []


def leer_sensores_cabina(conductor_id: int) -> dict:
    frecuencia_parpadeo = round(random.uniform(3.0, 22.0), 1)
    base_fatiga         = max(0.0, (12.0 - frecuencia_parpadeo) / 12.0)
    nivel_fatiga        = round(min(1.0, base_fatiga + random.uniform(-0.05, 0.1)), 2)
    velocidad_kmh       = round(random.uniform(40.0, 110.0), 1)

    return {
        "conductor_id":        conductor_id,
        "frecuencia_parpadeo": frecuencia_parpadeo,
        "nivel_fatiga":        nivel_fatiga,
        "velocidad_kmh":       velocidad_kmh,
        "timestamp":           time.time()
    }


def iniciar_sensor():
    client = mqtt.Client()
    print(f"🔌 Conectando al Broker MQTT ({BROKER})...")

    # Reintentos de conexión (útil al arrancar en Docker antes que el broker externo responda)
    conectado = False
    while not conectado:
        try:
            client.connect(BROKER, PORT)
            conectado = True
            print("✅ Conectado al Broker MQTT.\n")
        except Exception as e:
            print(f"⏳ No se pudo conectar al broker ({e}). Reintentando en 3s...")
            time.sleep(3)

    pares           = []
    ultimo_refresco = 0
    ciclo           = 0

    while True:
        ahora = time.time()
        if ahora - ultimo_refresco >= INTERVALO_REFRESCO_PARES or not pares:
            print("🔄 Consultando pares conductor/vehículo al backend...")
            pares           = cargar_pares_desde_backend()
            ultimo_refresco = ahora

        if not pares:
            print("⏳ Sin pares disponibles. Esperando 10s...")
            time.sleep(10)
            continue

        par   = random.choice(pares)
        c_id  = par["conductor_id"]
        v_id  = par["vehiculo_id"]
        topic = f"safedriver/telemetria/vehiculos/{v_id}"

        ciclo  += 1
        payload = leer_sensores_cabina(c_id)
        client.publish(topic, json.dumps(payload))

        print(f"[TX {ciclo:04d}] Conductor={c_id} | Vehiculo={v_id} | "
              f"Fatiga={payload['nivel_fatiga']} | "
              f"Vel={payload['velocidad_kmh']} km/h → Broker")

        time.sleep(2)


if __name__ == "__main__":
    iniciar_sensor()