from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# ── Token de autenticación ─────────────────────────────────
def obtener_token():
    response = client.post("/token", data={
        "username": "admin",
        "password": "safedriver123"
    })
    return response.json()["access_token"]

def cabecera_auth():
    token = obtener_token()
    return {"Authorization": f"Bearer {token}"}


# ── Test 1: El servidor responde ───────────────────────────
def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "online"


# ── Test 2: Login correcto devuelve token ──────────────────
def test_login_correcto():
    response = client.post("/token", data={
        "username": "admin",
        "password": "safedriver123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()


# ── Test 3: Login incorrecto devuelve 401 ─────────────────
def test_login_incorrecto():
    response = client.post("/token", data={
        "username": "admin",
        "password": "contraseña_incorrecta"
    })
    assert response.status_code == 401


# ── Test 4: Sin token no se puede crear conductor ─────────
def test_crear_conductor_sin_token():
    response = client.post("/conductores/", json={
        "nombre": "Test Sin Token",
        "licencia": "XX-000"
    })
    assert response.status_code == 401


# ── Test 5: Con token sí se puede crear conductor ─────────
def test_crear_conductor_con_token():
    response = client.post("/conductores/",
        json={"nombre": "Ana Torres", "licencia": "LC-002"},
        headers=cabecera_auth()
    )
    assert response.status_code == 201
    assert response.json()["nombre"] == "Ana Torres"


# ── Test 6: Crear vehículo vinculado al conductor ──────────
def test_crear_vehiculo():
    # Primero crear conductor
    r = client.post("/conductores/",
        json={"nombre": "Pedro Rios", "licencia": "LC-003"},
        headers=cabecera_auth()
    )
    conductor_id = r.json()["id"]

    # Luego crear vehículo
    response = client.post("/vehiculos/",
        json={
            "placa": "XYZ-999",
            "modelo": "Scania R450",
            "conductor_id": conductor_id
        },
        headers=cabecera_auth()
    )
    assert response.status_code == 201
    assert response.json()["placa"] == "XYZ-999"


# ── Test 7: Alerta con conductor inexistente da 404 ────────
def test_alerta_conductor_inexistente():
    response = client.post("/alertas/",
        json={
            "tipo": "FATIGA",
            "nivel": "CRITICO",
            "valor_bpm": 45.0,
            "conductor_id": 9999,
            "vehiculo_id": 1
        },
        headers=cabecera_auth()
    )
    assert response.status_code == 404