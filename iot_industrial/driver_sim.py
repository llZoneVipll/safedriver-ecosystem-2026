import requests
import time
import random

# ─── CONFIGURACIÓN ───────────────────────────────────────────────
API_URL_LOGIN       = "http://localhost:8000/token"
API_URL_ALERTA      = "http://localhost:8000/alertas/"
API_URL_CONDUCTORES = "http://localhost:8000/conductores/"
API_URL_VEHICULOS   = "http://localhost:8000/vehiculos/"

USUARIO    = "admin"
CONTRASENA = "safedriver123"

# IDs de la flota a simular
FLOTA_IDS = [1, 2, 3]

INTERVALO_NORMAL  = 3
INTERVALO_CRITICO = 1

UMBRAL_FATIGA_ALERTA  = 0.5
UMBRAL_FATIGA_CRITICO = 0.75
UMBRAL_VELOCIDAD      = 90.0

# ─── FUNCIONES DE SIMULACIÓN ─────────────────────────────────────

def obtener_token() -> str:
    print("🔐 Autenticando con el backend SafeDriver...")
    try:
        resp = requests.post(
            API_URL_LOGIN,
            data={"username": USUARIO, "password": CONTRASENA},
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        if resp.status_code == 200:
            return resp.json()["access_token"]
        else:
            print(f"❌ Error de login: {resp.status_code}")
            exit(1)
    except Exception as e:
        print(f"[CRÍTICO] Sin conexión: {e}")
        exit(1)

def inicializar_flota(token: str):
    print("⚙️ Verificando e inicializando base de datos para pruebas...")
    headers = {"Authorization": f"Bearer {token}"}
    
    for i in FLOTA_IDS:
        resp = requests.get(f"{API_URL_CONDUCTORES}{i}", headers=headers)
        if resp.status_code == 404:
            print(f"   ➜ Creando Conductor {i} y su Camión...")
            requests.post(API_URL_CONDUCTORES, json={
                "nombre": f"Conductor de Prueba {i}",
                "licencia": f"LIC-000{i}"
            }, headers=headers)
            requests.post(API_URL_VEHICULOS, json={
                "placa": f"TRK-90{i}",
                "modelo": "Volvo FH16 (Simulado)",
                "conductor_id": i
            }, headers=headers)
    print("✅ Base de datos lista.\n")

def leer_sensores_cabina() -> dict:
    frecuencia_parpadeo = round(random.uniform(3.0, 22.0), 1)
    base_fatiga = max(0.0, (12.0 - frecuencia_parpadeo) / 12.0)
    nivel_fatiga = round(min(1.0, base_fatiga + random.uniform(-0.05, 0.1)), 2)
    velocidad_kmh = round(random.uniform(40.0, 110.0), 1)

    if nivel_fatiga > 0.7:
        valor_bpm = round(random.uniform(50.0, 65.0), 1)
    else:
        valor_bpm = round(random.uniform(70.0, 95.0), 1)

    return {
        "frecuencia_parpadeo": frecuencia_parpadeo,
        "nivel_fatiga": nivel_fatiga,
        "velocidad_kmh": velocidad_kmh,
        "valor_bpm": valor_bpm,
    }

def clasificar_alerta(sensores: dict) -> tuple[str, str]:
    f = sensores["nivel_fatiga"]
    v = sensores["velocidad_kmh"]
    if f >= UMBRAL_FATIGA_CRITICO or (f >= UMBRAL_FATIGA_ALERTA and v > UMBRAL_VELOCIDAD):
        return "CRITICO", "SUEÑO_DETECTADO"
    elif f >= UMBRAL_FATIGA_ALERTA or v > UMBRAL_VELOCIDAD:
        return "ALERTA", "FATIGA_TEMPRANA"
    else:
        return "NORMAL", "MONITOREO"

def enviar_alerta(token: str, sensores: dict, nivel: str, tipo: str, conductor_vehiculo_id: int) -> bool:
    payload = {
        "conductor_id": conductor_vehiculo_id,
        "vehiculo_id":  conductor_vehiculo_id,
        "nivel":        nivel,
        "tipo":         tipo,
        "valor_bpm":    sensores["valor_bpm"],
        "valor_velocidad": sensores["velocidad_kmh"],
        "parpadeos_por_minuto": sensores["frecuencia_parpadeo"]
    }
    try:
        resp = requests.post(API_URL_ALERTA, json=payload, headers={"Authorization": f"Bearer {token}"})
        return resp.status_code in (200, 201)
    except:
        return False

def iniciar_simulacion():
    print("=" * 55)
    print("   🚛 SafeDriver — Simulador IoT Multi-Vehículo 🚛")
    print("=" * 55)

    token = obtener_token()
    inicializar_flota(token)
    ciclo = 0

    while True:
        ciclo += 1
        id_actual = random.choice(FLOTA_IDS) 
        sensores = leer_sensores_cabina()
        nivel, tipo = clasificar_alerta(sensores)

        icono = {"NORMAL": "🟢", "ALERTA": "🟡", "CRITICO": "🔴"}[nivel]
        print(f"[Ciclo {ciclo:04d} | Chofer {id_actual}] {icono} {nivel:7s} | Fatiga={sensores['nivel_fatiga']:.2f} | Vel={sensores['velocidad_kmh']:5.1f}")

        if nivel != "NORMAL":
            enviar_alerta(token, sensores, nivel, tipo, id_actual)

        time.sleep(INTERVALO_CRITICO if nivel == "CRITICO" else INTERVALO_NORMAL)

if __name__ == "__main__":
    iniciar_simulacion()