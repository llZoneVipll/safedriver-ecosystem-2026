import paho.mqtt.client as mqtt
import requests
import json
import time
import sys
import os

# ─── CONFIGURACIÓN (desde variables de entorno, con default para uso local) ──
BROKER = os.getenv("MQTT_BROKER", "broker.hivemq.com")
PORT   = int(os.getenv("MQTT_PORT", "1883"))

TOPIC_SUBSCRIBE = os.getenv("MQTT_TOPIC", "safedriver/telemetria/vehiculos/+")

API_URL_LOGIN  = os.getenv("API_URL_LOGIN", "http://backend:8000/token")
API_URL_ALERTA = os.getenv("API_URL_ALERTA", "http://backend:8000/alertas/")

USUARIO    = os.getenv("USUARIO", "admin")
CONTRASENA = os.getenv("CONTRASENA", "safedriver123")

UMBRAL_FATIGA_ALERTA = 0.5
UMBRAL_VELOCIDAD     = 90.0

# Caché para el Deadband Filter (Laboratorio 11)
cache_local = {}
TOKEN = None


def obtener_token() -> str:
    """Obtiene el JWT del backend, con reintentos (útil al arrancar en Docker)."""
    print(f"🔐 Bridge solicitando JWT a {API_URL_LOGIN}...")
    intentos = 0
    while intentos < 10:
        try:
            resp = requests.post(
                API_URL_LOGIN,
                data={"username": USUARIO, "password": CONTRASENA},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=5
            )
            if resp.status_code == 200:
                token = resp.json()["access_token"]
                print("✅ Token JWT obtenido exitosamente.\n")
                return token
            else:
                print(f"❌ Error obteniendo Token: {resp.status_code} - {resp.text}")
        except Exception as e:
            print(f"⏳ Backend aún no disponible ({e}). Reintentando en 3s...")

        intentos += 1
        time.sleep(3)

    print("[CRÍTICO] No se pudo autenticar tras varios intentos.")
    sys.exit(1)


def evaluar_alerta(fatiga, velocidad):
    if fatiga >= 0.75 or (fatiga >= UMBRAL_FATIGA_ALERTA and velocidad > UMBRAL_VELOCIDAD):
        return "CRITICO", "SUEÑO_DETECTADO"
    elif fatiga >= UMBRAL_FATIGA_ALERTA or velocidad > UMBRAL_VELOCIDAD:
        return "ALERTA", "FATIGA_TEMPRANA"
    return "NORMAL", "MONITOREO"


def variacion_significativa(viejo, nuevo):
    if viejo == 0:
        return True
    return abs(nuevo - viejo) / viejo > 0.05


def on_message(client, userdata, msg):
    global TOKEN
    try:
        vehiculo_id = int(msg.topic.split('/')[-1])
        payload = json.loads(msg.payload.decode())

        conductor_id = payload["conductor_id"]
        fatiga       = payload["nivel_fatiga"]
        velocidad    = payload["velocidad_kmh"]
        ahora        = time.time()

        nivel, tipo = evaluar_alerta(fatiga, velocidad)

        # ─── FILTRO DEADBAND (LAB 11) ───────────────────────────────
        guardar_en_db = False
        razon_filtro  = ""

        if vehiculo_id not in cache_local:
            guardar_en_db = True
            razon_filtro = "Primera lectura"
        else:
            ultimo = cache_local[vehiculo_id]
            tiempo_transcurrido = ahora - ultimo["tiempo"]

            if tiempo_transcurrido > 60:
                guardar_en_db = True
                razon_filtro = "Keep-alive (>60s)"
            elif nivel != "NORMAL":
                guardar_en_db = True
                razon_filtro = f"Emergencia ({nivel})"
            elif variacion_significativa(ultimo["fatiga"], fatiga) or variacion_significativa(ultimo["velocidad"], velocidad):
                guardar_en_db = True
                razon_filtro = "Variación > 5%"

        cache_local[vehiculo_id] = {"fatiga": fatiga, "velocidad": velocidad, "tiempo": ahora}

        print(f"[RX Vehiculo {vehiculo_id}] Fatiga: {fatiga} | Vel: {velocidad}")

        # ─── INGESTA HTTP ────────────────────────────────────────────
        if guardar_en_db:
            data = {
                "conductor_id": conductor_id,
                "vehiculo_id": vehiculo_id,
                "nivel": nivel,
                "tipo": tipo,
                "valor_velocidad": velocidad,
                "valor_fatiga": fatiga
            }
            headers = {"Authorization": f"Bearer {TOKEN}"}

            try:
                resp = requests.post(API_URL_ALERTA, json=data, headers=headers, timeout=5)
                if resp.status_code in (200, 201):
                    print(f"   ✅ [INGESTA DB] {tipo} - {razon_filtro}")
                else:
                    print(f"   ❌ [ERROR DB] Código {resp.status_code}: {resp.text}")
            except Exception as e:
                print(f"   ❌ [ERROR CONEXIÓN] {e}")
        else:
            print(f"   🔕 [FILTRADO] Lectura redundante (diferencia < 5%).")

    except Exception as e:
        print(f"❌ Error procesando mensaje MQTT: {e}")


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("🟢 Conectado exitosamente al Broker MQTT")
        client.subscribe(TOPIC_SUBSCRIBE)
        print(f"🎧 Suscrito al tópico: {TOPIC_SUBSCRIBE}\n")
    else:
        print(f"🔴 Error de conexión al Broker. Código: {rc}")
        sys.exit(1)


def iniciar_bridge():
    global TOKEN

    print("=" * 60)
    print("   🌉 SafeDriver — MQTT Bridge & Data Ingestion (Lab 11) 🌉")
    print("=" * 60)

    TOKEN = obtener_token()

    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    print(f"🔌 Conectando al Broker MQTT ({BROKER})...")
    try:
        client.connect(BROKER, PORT, keepalive=60)
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n🛑 Bridge detenido por el usuario.")
        client.disconnect()
    except Exception as e:
        print(f"[CRÍTICO] Error conectando al Broker: {e}")
        sys.exit(1)


if __name__ == "__main__":
    iniciar_bridge()