import paho.mqtt.client as mqtt
import requests
import json
import os
import time

# ─── CONFIGURACIÓN ───────────────────────────────────────────────
BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC_SUBSCRIBE = "safedriver/telemetria/vehiculos/+" 

API_URL_LOGIN = "http://backend:8000/token"
API_URL_ALERTA = os.environ.get("API_URL", "http://localhost:8000/alertas/")
USUARIO = "admin"
CONTRASENA = "safedriver123"

UMBRAL_FATIGA_ALERTA = 0.5
UMBRAL_VELOCIDAD = 90.0

cache_local = {}

def obtener_token() -> str:
    print("🔐 Bridge solicitando JWT al backend...")
    resp = requests.post(
        API_URL_LOGIN,
        data={"username": USUARIO, "password": CONTRASENA},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    if resp.status_code == 200:
        return resp.json()["access_token"]
    else:
        print(f"❌ Error obteniendo Token: {resp.text}")
        exit(1)

TOKEN = obtener_token()

def evaluar_alerta(fatiga, velocidad):
    if fatiga >= 0.75 or (fatiga >= UMBRAL_FATIGA_ALERTA and velocidad > UMBRAL_VELOCIDAD):
        return "CRITICO", "SUEÑO_DETECTADO"
    elif fatiga >= UMBRAL_FATIGA_ALERTA or velocidad > UMBRAL_VELOCIDAD:
        return "ALERTA", "FATIGA_TEMPRANA"
    return "NORMAL", "MONITOREO"

def variacion_significativa(viejo, nuevo):
    if viejo == 0: return True
    return abs(nuevo - viejo) / viejo > 0.05

def on_message(client, userdata, msg):
    try:
        vehiculo_id = int(msg.topic.split('/')[-1])
        payload = json.loads(msg.payload.decode())
        
        conductor_id = payload.get("conductor_id", vehiculo_id)
        fatiga = payload["nivel_fatiga"]
        velocidad = payload["velocidad_kmh"]
        # Extraemos el BPM si el sender lo envió, sino asumimos un default seguro
        bpm = payload.get("valor_bpm", 75.0)
        parpadeo = payload.get("frecuencia_parpadeo", 15.0)
        
        ahora = time.time()
        nivel, tipo = evaluar_alerta(fatiga, velocidad)
        
        guardar_en_db = False
        razon_filtro = ""
        
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
        
        if guardar_en_db:
            # AQUI ESTABA EL ERROR: Ahora mandamos el diccionario exactamente como lo pide Pydantic
            data = {
                "conductor_id": conductor_id,
                "vehiculo_id": vehiculo_id,
                "nivel": nivel,
                "tipo": tipo,
                "valor_bpm": bpm,
                "valor_velocidad": velocidad,
                "parpadeos_por_minuto": parpadeo
            }
            headers = {"Authorization": f"Bearer {TOKEN}"}
            resp = requests.post(API_URL_ALERTA, json=data, headers=headers)
            
            if resp.status_code in (200, 201):
                print(f"   ✅ [INGESTA DB] {tipo} - {razon_filtro}")
            else:
                print(f"   ❌ [ERROR DB] {resp.status_code}")
        else:
            print("   🔕 [FILTRADO] Lectura redundante ignorada.")
            
    except Exception as e:
        print(f"Error procesando mensaje: {e}")

def iniciar_bridge():
    print("=" * 55)
    print("   🌉 SafeDriver — MQTT Bridge & Data Ingestion 🌉")
    print("=" * 55)
    
    client = mqtt.Client()
    client.on_message = on_message
    
    client.connect(BROKER, PORT)
    client.subscribe(TOPIC_SUBSCRIBE)
    
    print(f"🎧 Escuchando en el tópico global: {TOPIC_SUBSCRIBE}")
    client.loop_forever()

if __name__ == "__main__":
    iniciar_bridge()