from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class Conductor(Base):
    __tablename__ = "conductores"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    licencia = Column(String, unique=True, nullable=False)

    # Un conductor puede tener muchos vehículos y muchas alertas
    vehiculos = relationship("Vehiculo", back_populates="conductor")
    alertas = relationship("Alerta", back_populates="conductor")


class Vehiculo(Base):
    __tablename__ = "vehiculos"

    id = Column(Integer, primary_key=True, index=True)
    placa = Column(String, unique=True, nullable=False)
    modelo = Column(String, nullable=False)
    conductor_id = Column(Integer, ForeignKey("conductores.id"), nullable=False)

    conductor = relationship("Conductor", back_populates="vehiculos")
    alertas = relationship("Alerta", back_populates="vehiculo")


class Alerta(Base):
    __tablename__ = "alertas"

    id = Column(Integer, primary_key=True, index=True)
    tipo = Column(String, nullable=False)           # "FATIGA" o "VELOCIDAD"
    nivel = Column(String, nullable=False)          # "CRITICO", "ALERTA" o "NORMAL"
    valor_bpm = Column(Float, nullable=True)        # Ritmo cardíaco del conductor
    valor_velocidad = Column(Float, nullable=True)  # Velocidad en km/h
    parpadeos_por_minuto = Column(Float, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    conductor_id = Column(Integer, ForeignKey("conductores.id"), nullable=False)
    vehiculo_id = Column(Integer, ForeignKey("vehiculos.id"), nullable=False)

    conductor = relationship("Conductor", back_populates="alertas")
    vehiculo = relationship("Vehiculo", back_populates="alertas")