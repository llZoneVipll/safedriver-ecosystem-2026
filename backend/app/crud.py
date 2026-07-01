from sqlalchemy.orm import Session
from . import models, schemas

# ── Conductores ────────────────────────────────────────────
def crear_conductor(db: Session, conductor: schemas.ConductorCreate):
    nuevo = models.Conductor(
        nombre=conductor.nombre,
        licencia=conductor.licencia
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

def obtener_conductores(db: Session):
    return db.query(models.Conductor).all()

def obtener_conductor(db: Session, conductor_id: int):
    return db.query(models.Conductor).filter(
        models.Conductor.id == conductor_id
    ).first()

# ── Vehículos ──────────────────────────────────────────────
def crear_vehiculo(db: Session, vehiculo: schemas.VehiculoCreate):
    nuevo = models.Vehiculo(
        placa=vehiculo.placa,
        modelo=vehiculo.modelo,
        conductor_id=vehiculo.conductor_id
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

def obtener_vehiculos(db: Session):
    return db.query(models.Vehiculo).all()

# ── Alertas ────────────────────────────────────────────────
def crear_alerta(db: Session, alerta: schemas.AlertaCreate):
    nueva = models.Alerta(**alerta.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva

def obtener_alertas(db: Session, conductor_id: int = None):
    query = db.query(models.Alerta)
    if conductor_id:
        query = query.filter(models.Alerta.conductor_id == conductor_id)
    return query.order_by(models.Alerta.timestamp.desc()).all()

# ── Stats para el Dashboard ────────────────────────────────
def obtener_stats(db: Session, conductor_id: int = None):
    query_alertas = db.query(models.Alerta)
    
    # Lógica de aislamiento: Si hay un conductor_id, filtramos todo por él
    if conductor_id:
        query_alertas = query_alertas.filter(models.Alerta.conductor_id == conductor_id)
        total_conductores = 1 # Para el chofer, él es el único conductor en su contexto
    else:
        total_conductores = db.query(models.Conductor).count()

    return {
        "total_conductores": total_conductores,
        "total_alertas":     query_alertas.count(),
        "alertas_criticas":  query_alertas.filter(models.Alerta.nivel == "CRITICO").count(),
        "alertas_en_alerta": query_alertas.filter(models.Alerta.nivel == "ALERTA").count(),
    }

# ── Eliminar conductor ─────────────────────────────────────
def eliminar_conductor(db: Session, conductor_id: int):
    conductor = db.query(models.Conductor).filter(
        models.Conductor.id == conductor_id
    ).first()
    if conductor:
        db.delete(conductor)
        db.commit()
    return conductor