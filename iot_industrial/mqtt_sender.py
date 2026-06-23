import paho.mqtt.client as mqtt
import json
import time
import random

# ─── CONFIGURACIÓN MQTT ──────────────────────────────────────────
BROKER = "broker.hivemq.com"
PORT = 1883
VEHICULO_ID = 1
CONDUCTOR_ID = 1
# Tópico específico para este vehículo
TOPIC = f"safedriver/telemetria/vehiculos/{VEHICULO_ID}"

def leer_sensores_cabina() -> dict:
    frecuencia_parpadeo = round(random.uniform(3.0, 22.0), 1)
    base_fatiga = max(0.0, (12.0 - frecuencia_parpadeo) / 12.0)
    nivel_fatiga = round(min(1.0, base_fatiga + random.uniform(-0.05, 0.1)), 2)
    velocidad_kmh = round(random.uniform(40.0, 110.0), 1)

    return {
        "conductor_id": CONDUCTOR_ID,
        "frecuencia_parpadeo": frecuencia_parpadeo,
        "nivel_fatiga": nivel_fatiga,
        "velocidad_kmh": velocidad_kmh,
        "timestamp": time.time()
    }

def iniciar_sensor():
    client = mqtt.Client()
    print("🔌 Conectando al Broker MQTT (HiveMQ)...")
    client.connect(BROKER, PORT)
    
    print(f"📡 Iniciando transmisión en tópico: {TOPIC}")
    print("-" * 50)
    
    ciclo = 0
    while True:
        ciclo += 1
        payload = leer_sensores_cabina()
        
        # Publicar los datos en formato JSON
        client.publish(TOPIC, json.dumps(payload))
        
        print(f"[TX {ciclo:04d}] Fatiga: {payload['nivel_fatiga']} | Vel: {payload['velocidad_kmh']} km/h -> Enviado al Broker")
        
        # El sensor envía datos constantemente cada 2 segundos
        time.sleep(2)

if __name__ == "__main__":
    iniciar_sensor()