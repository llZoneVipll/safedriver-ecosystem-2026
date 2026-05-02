from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ── Conductor ──────────────────────────────────────────────
class ConductorCreate(BaseModel):
    nombre: str
    licencia: str

class ConductorOut(BaseModel):
    id: int
    nombre: str
    licencia: str

    class Config:
        from_attributes = True


# ── Vehículo ───────────────────────────────────────────────
class VehiculoCreate(BaseModel):
    placa: str
    modelo: str
    conductor_id: int

class VehiculoOut(BaseModel):
    id: int
    placa: str
    modelo: str
    conductor_id: int

    class Config:
        from_attributes = True


# ── Alerta ─────────────────────────────────────────────────
class AlertaCreate(BaseModel):
    tipo: str
    nivel: str
    valor_bpm: Optional[float] = None
    valor_velocidad: Optional[float] = None
    parpadeos_por_minuto: Optional[float] = None
    conductor_id: int
    vehiculo_id: int

class AlertaOut(BaseModel):
    id: int
    tipo: str
    nivel: str
    valor_bpm: Optional[float]
    valor_velocidad: Optional[float]
    parpadeos_por_minuto: Optional[float]
    timestamp: datetime
    conductor_id: int
    vehiculo_id: int

    class Config:
        from_attributes = True