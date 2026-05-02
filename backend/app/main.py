from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List

from . import models, schemas, crud
from .database import engine, get_db

# Esta línea crea las tablas en la base de datos al iniciar el servidor
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SafeDriver API",
    description="Sistema Inteligente de Prevención de Fatiga y Seguridad Vial",
    version="1.0.0",
)

# Permite que la app móvil se conecte al backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health check ───────────────────────────────────────────
@app.get("/", tags=["Sistema"])
def root():
    return {"status": "online", "sistema": "SafeDriver v1.0"}


# ── Conductores ────────────────────────────────────────────
@app.post("/conductores/", response_model=schemas.ConductorOut,
          status_code=201, tags=["Conductores"])
def crear_conductor(conductor: schemas.ConductorCreate,
                    db: Session = Depends(get_db)):
    return crud.crear_conductor(db, conductor)

@app.get("/conductores/", response_model=List[schemas.ConductorOut],
         tags=["Conductores"])
def listar_conductores(db: Session = Depends(get_db)):
    return crud.obtener_conductores(db)

@app.get("/conductores/{conductor_id}", response_model=schemas.ConductorOut,
         tags=["Conductores"])
def obtener_conductor(conductor_id: int, db: Session = Depends(get_db)):
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return conductor


# ── Vehículos ──────────────────────────────────────────────
@app.post("/vehiculos/", response_model=schemas.VehiculoOut,
          status_code=201, tags=["Vehículos"])
def crear_vehiculo(vehiculo: schemas.VehiculoCreate,
                   db: Session = Depends(get_db)):
    conductor = crud.obtener_conductor(db, vehiculo.conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return crud.crear_vehiculo(db, vehiculo)

@app.get("/vehiculos/", response_model=List[schemas.VehiculoOut],
         tags=["Vehículos"])
def listar_vehiculos(db: Session = Depends(get_db)):
    return crud.obtener_vehiculos(db)


# ── Alertas ────────────────────────────────────────────────
@app.post("/alertas/", response_model=schemas.AlertaOut,
          status_code=201, tags=["Alertas"])
def registrar_alerta(alerta: schemas.AlertaCreate,
                     db: Session = Depends(get_db)):
    if not crud.obtener_conductor(db, alerta.conductor_id):
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    from . import models as m
    vehiculo = db.query(m.Vehiculo).filter(
        m.Vehiculo.id == alerta.vehiculo_id).first()
    if not vehiculo:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")
    return crud.crear_alerta(db, alerta)

@app.get("/alertas/", response_model=List[schemas.AlertaOut],
         tags=["Alertas"])
def listar_alertas(conductor_id: int = None,
                   db: Session = Depends(get_db)):
    return crud.obtener_alertas(db, conductor_id)