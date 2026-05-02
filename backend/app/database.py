from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Nombre del archivo de base de datos que se creará automáticamente
SQLALCHEMY_DATABASE_URL = "sqlite:///./safedriver.db"

# Motor de conexión
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)

# Fábrica de sesiones
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Clase base para los modelos
Base = declarative_base()

# Esta función se usará en cada endpoint para obtener la conexión a la DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()