from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List

from . import models, schemas, crud
from .database import engine, get_db
from .auth import (
    crear_token_acceso,
    requerir_rol,
    USUARIOS_DB
)

# Crea las tablas en la base de datos al iniciar
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SafeDriver API",
    description="Sistema Inteligente de Prevención de Fatiga y Seguridad Vial.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Sistema"])
def root():
    return {"status": "online", "sistema": "SafeDriver v1.0"}

@app.post("/token", tags=["Seguridad"])
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = USUARIOS_DB.get(form_data.username)
    if not user or form_data.password != user["password"]:
        raise HTTPException(
            status_code=401,
            detail="Usuario o contraseña incorrectos"
        )
    token = crear_token_acceso({"sub": form_data.username, "role": user["role"]})
    return {"access_token": token, "token_type": "bearer", "role": user["role"]}

@app.post("/conductores/", response_model=schemas.ConductorOut, status_code=201, tags=["Conductores"])
def crear_conductor(
    conductor: schemas.ConductorCreate,
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor"]))
):
    return crud.crear_conductor(db, conductor)

@app.get("/conductores/", response_model=List[schemas.ConductorOut], tags=["Conductores"])
def listar_conductores(
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if usuario["role"] == "usuario":
        conductor = crud.obtener_conductor(db, usuario["conductor_id"])
        return [conductor] if conductor else []
    return crud.obtener_conductores(db)

@app.get("/conductores/{conductor_id}", response_model=schemas.ConductorOut, tags=["Conductores"])
def obtener_conductor(
    conductor_id: int, 
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if usuario["role"] == "usuario" and usuario["conductor_id"] != conductor_id:
        raise HTTPException(status_code=403, detail="Acceso denegado")
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return conductor

@app.delete("/conductores/{conductor_id}", tags=["Conductores"])
def eliminar_conductor(
    conductor_id: int, 
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor"]))
):
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    db.delete(conductor)
    db.commit()
    return {"mensaje": "Conductor eliminado exitosamente"}

@app.put("/conductores/{conductor_id}", response_model=schemas.ConductorOut, tags=["Conductores"])
def actualizar_conductor(
    conductor_id: int,
    conductor_actualizado: schemas.ConductorCreate,
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor"]))
):
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    conductor.nombre = conductor_actualizado.nombre
    conductor.licencia = conductor_actualizado.licencia
    db.commit()
    db.refresh(conductor)
    return conductor

@app.post("/vehiculos/", response_model=schemas.VehiculoOut, status_code=201, tags=["Vehículos"])
def crear_vehiculo(
    vehiculo: schemas.VehiculoCreate,
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor"]))
):
    conductor = crud.obtener_conductor(db, vehiculo.conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return crud.crear_vehiculo(db, vehiculo)

# ── Lógica de Aislamiento Aplicada a Vehículos ────────────
@app.get("/vehiculos/", response_model=List[schemas.VehiculoOut], tags=["Vehículos"])
def listar_vehiculos(
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if usuario["role"] == "usuario":
        # Filtramos para que el chofer solo vea su propio camión
        return db.query(models.Vehiculo).filter(models.Vehiculo.conductor_id == usuario["conductor_id"]).all()
    return crud.obtener_vehiculos(db)

@app.get("/stats", tags=["Dashboard"])
def obtener_estadisticas(
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if usuario["role"] == "usuario":
        return crud.obtener_stats(db, conductor_id=usuario["conductor_id"])
    return crud.obtener_stats(db)

# ── Endpoint público para el ecosistema IoT ───────────────
@app.get("/iot/conductores-activos", tags=["IoT"])
def get_conductores_activos(db: Session = Depends(get_db)):
    """
    Endpoint SIN JWT — diseñado para que el sensor IoT (mqtt_sender.py)
    descubra dinámicamente qué pares (conductor_id, vehiculo_id) son
    válidos en la base de datos, en vez de usar IDs hardcodeados.
    Retorna 404 si aún no hay vehículos registrados.
    """
    vehiculos = db.query(models.Vehiculo).all()
    pares = [
        {"conductor_id": v.conductor_id, "vehiculo_id": v.id}
        for v in vehiculos
    ]
    if not pares:
        raise HTTPException(status_code=404, detail="No hay vehículos registrados")
    return pares

@app.post("/alertas/", response_model=schemas.AlertaOut, status_code=201, tags=["Alertas"])
def registrar_alerta(
    alerta: schemas.AlertaCreate,
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if not crud.obtener_conductor(db, alerta.conductor_id):
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    vehiculo = db.query(models.Vehiculo).filter(
        models.Vehiculo.id == alerta.vehiculo_id
    ).first()
    if not vehiculo:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")
    return crud.crear_alerta(db, alerta)

@app.get("/alertas/", response_model=List[schemas.AlertaOut], tags=["Alertas"])
def listar_alertas(
    conductor_id: int = None,
    db: Session = Depends(get_db),
    usuario: dict = Depends(requerir_rol(["gestor", "usuario"]))
):
    if usuario["role"] == "usuario":
        return crud.obtener_alertas(db, conductor_id=usuario["conductor_id"])
    return crud.obtener_alertas(db, conductor_id)