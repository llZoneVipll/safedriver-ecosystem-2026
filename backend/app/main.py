from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List

from . import models, schemas, crud
from .database import engine, get_db
from .auth import (
    crear_token_acceso,
    verificar_token,
    USUARIO_ADMIN
)

# Crea las tablas en la base de datos al iniciar
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SafeDriver API",
    description="""
Sistema Inteligente de Prevención de Fatiga y Seguridad Vial.

## Seguridad
Para usar los endpoints protegidos:
1. Ve a **/token** y haz login con `admin` / `safedriver123`
2. Copia el `access_token` que recibes
3. Haz clic en el botón **Authorize** (arriba a la derecha)
4. Escribe: `Bearer <tu_token>`
    """,
    version="1.0.0",
)

# CORS para permitir conexión desde la app móvil
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health check (público) ─────────────────────────────────
@app.get("/", tags=["Sistema"])
def root():
    return {"status": "online", "sistema": "SafeDriver v1.0"}


# ── Login: obtener token JWT ───────────────────────────────
@app.post("/token", tags=["Seguridad"],
          summary="Iniciar sesión y obtener token")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Verificar usuario y contraseña
    if (form_data.username != USUARIO_ADMIN["username"] or
            form_data.password != USUARIO_ADMIN["password"]):
        raise HTTPException(
            status_code=401,
            detail="Usuario o contraseña incorrectos"
        )
    # Crear y devolver el token
    token = crear_token_acceso({"sub": form_data.username})
    return {"access_token": token, "token_type": "bearer"}


# ── Conductores (público para leer, protegido para crear) ──
@app.post(
    "/conductores/",
    response_model=schemas.ConductorOut,
    status_code=201,
    tags=["Conductores"],
    summary="Registrar conductor (requiere token)",
)
def crear_conductor(
    conductor: schemas.ConductorCreate,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    return crud.crear_conductor(db, conductor)

@app.get(
    "/conductores/",
    response_model=List[schemas.ConductorOut],
    tags=["Conductores"],
    summary="Listar conductores",
)
def listar_conductores(db: Session = Depends(get_db)):
    return crud.obtener_conductores(db)

@app.get(
    "/conductores/{conductor_id}",
    response_model=schemas.ConductorOut,
    tags=["Conductores"],
)
def obtener_conductor(conductor_id: int, db: Session = Depends(get_db)):
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return conductor

@app.delete(
    "/conductores/{conductor_id}",
    tags=["Conductores"],
    summary="Eliminar conductor (requiere token)"
)
def eliminar_conductor(
    conductor_id: int, 
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    # Buscamos al conductor usando tu función CRUD actual
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    
    # Eliminamos el registro de la base de datos
    db.delete(conductor)
    db.commit()
    return {"mensaje": "Conductor eliminado exitosamente"}

@app.put(
    "/conductores/{conductor_id}",
    response_model=schemas.ConductorOut,
    tags=["Conductores"],
    summary="Editar conductor (requiere token)"
)
def actualizar_conductor(
    conductor_id: int,
    conductor_actualizado: schemas.ConductorCreate,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    conductor = crud.obtener_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    
    # Actualizamos los valores en la base de datos
    conductor.nombre = conductor_actualizado.nombre
    conductor.licencia = conductor_actualizado.licencia
    
    db.commit()
    db.refresh(conductor)
    return conductor

# ── Vehículos ──────────────────────────────────────────────
@app.post(
    "/vehiculos/",
    response_model=schemas.VehiculoOut,
    status_code=201,
    tags=["Vehículos"],
    summary="Registrar vehículo (requiere token)",
)
def crear_vehiculo(
    vehiculo: schemas.VehiculoCreate,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    conductor = crud.obtener_conductor(db, vehiculo.conductor_id)
    if not conductor:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return crud.crear_vehiculo(db, vehiculo)

@app.get(
    "/vehiculos/",
    response_model=List[schemas.VehiculoOut],
    tags=["Vehículos"],
)
def listar_vehiculos(db: Session = Depends(get_db)):
    return crud.obtener_vehiculos(db)

# ── Stats Dashboard ────────────────────────────────────────
@app.get("/stats", tags=["Dashboard"],
         summary="Estadísticas generales del sistema")
def obtener_estadisticas(
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)
):
    return crud.obtener_stats(db)


# ── Eliminar conductor ─────────────────────────────────────
@app.delete("/conductores/{conductor_id}",
            tags=["Conductores"],
            summary="Eliminar conductor (requiere token)")
def eliminar_conductor(
    conductor_id: int,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)
):
    conductor = crud.eliminar_conductor(db, conductor_id)
    if not conductor:
        raise HTTPException(status_code=404,
                            detail="Conductor no encontrado")
    return {"msj": f"Conductor {conductor_id} eliminado"}

# ── Alertas ────────────────────────────────────────────────
@app.post(
    "/alertas/",
    response_model=schemas.AlertaOut,
    status_code=201,
    tags=["Alertas"],
    summary="Registrar alerta de telemetría (requiere token)",
    description="El sensor IoT debe enviar un Bearer Token válido. Valida conductor y vehículo.",
)
def registrar_alerta(
    alerta: schemas.AlertaCreate,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    if not crud.obtener_conductor(db, alerta.conductor_id):
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    vehiculo = db.query(models.Vehiculo).filter(
        models.Vehiculo.id == alerta.vehiculo_id
    ).first()
    if not vehiculo:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")
    return crud.crear_alerta(db, alerta)

@app.get(
    "/alertas/",
    response_model=List[schemas.AlertaOut],
    tags=["Alertas"],
    summary="Listar alertas",
)
def listar_alertas(
    conductor_id: int = None,
    db: Session = Depends(get_db),
    usuario: str = Depends(verificar_token)   #  PROTEGIDO
):
    return crud.obtener_alertas(db, conductor_id)