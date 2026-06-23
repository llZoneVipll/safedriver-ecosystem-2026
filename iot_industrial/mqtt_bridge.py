import paho.mqtt.client as mqtt
import requests
import json
import time

# ─── CONFIGURACIÓN ───────────────────────────────────────────────
BROKER = "broker.hivemq.com"
PORT = 1883
# El '+' permite escuchar a TODOS los vehículos a la vez
TOPIC_SUBSCRIBE = "safedriver/telemetria/vehiculos/+" 

API_URL_LOGIN = "http://localhost:8000/token"
API_URL_ALERTA = "http://localhost:8000/alertas/"
USUARIO = "admin"
CONTRASENA = "safedriver123"

UMBRAL_FATIGA_ALERTA = 0.5
UMBRAL_VELOCIDAD = 90.0

# Caché para el Deadband Filter (Laboratorio 11)
# Estructura: { vehiculo_id: {"fatiga": val, "velocidad": val, "tiempo": timestamp} }
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
    """Retorna True si el valor cambió más de un 5%"""
    if viejo == 0: return True
    return abs(nuevo - viejo) / viejo > 0.05

def on_message(client, userdata, msg):
    try:
        # Extraer ID del vehículo desde el tópico
        vehiculo_id = int(msg.topic.split('/')[-1])
        payload = json.loads(msg.payload.decode())
        
        conductor_id = payload["conductor_id"]
        fatiga = payload["nivel_fatiga"]
        velocidad = payload["velocidad_kmh"]
        ahora = time.time()
        
        nivel, tipo = evaluar_alerta(fatiga, velocidad)
        
        # ─── LÓGICA DE FILTRO (DEADBAND) ───
        guardar_en_db = False
        razon_filtro = ""
        
        if vehiculo_id not in cache_local:
            guardar_en_db = True
            razon_filtro = "Primera lectura"
        else:
            ultimo = cache_local[vehiculo_id]
            tiempo_transcurrido = ahora - ultimo["tiempo"]
            
            # Condición 1: Pasaron más de 60 segundos (Keep-alive)
            if tiempo_transcurrido > 60:
                guardar_en_db = True
                razon_filtro = "Keep-alive (>60s)"
            # Condición 2: El nivel de alerta es peligroso (ignorar filtro en emergencias)
            elif nivel != "NORMAL":
                guardar_en_db = True
                razon_filtro = f"Emergencia ({nivel})"
            # Condición 3: Cambio mayor al 5% en variables críticas
            elif variacion_significativa(ultimo["fatiga"], fatiga) or variacion_significativa(ultimo["velocidad"], velocidad):
                guardar_en_db = True
                razon_filtro = "Variación > 5%"

        # Actualizar caché
        cache_local[vehiculo_id] = {"fatiga": fatiga, "velocidad": velocidad, "tiempo": ahora}
        
        # Log en consola
        print(f"[RX Vehiculo {vehiculo_id}] Fatiga: {fatiga} | Vel: {velocidad}")
        
        # ─── INGESTA DE DATOS HTTP ───
        if guardar_en_db:
            data = {
                "conductor_id": conductor_id,
                "vehiculo_id": vehiculo_id,
                "nivel": nivel,
                "tipo": tipo,
                "descripcion": f"Fatiga: {fatiga} | Vel: {velocidad} km/h (Razón: {razon_filtro})"
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