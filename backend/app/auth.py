from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

# ── Configuración del token ────────────────────────────────
# Esta es la llave secreta con la que se firman los tokens
# En producción esto iría en una variable de entorno
SECRET_KEY = "SAFEDRIVER_UNMSM_SECRET_2026"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Este esquema le dice a FastAPI dónde esperar el token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ── Usuario simulado (en Parte 3 esto vendrá de la DB) ─────
USUARIO_ADMIN = {
    "username": "admin",
    "password": "safedriver123"
}


def crear_token_acceso(data: dict):
    """Genera un JWT firmado con expiración"""
    payload = data.copy()
    expiracion = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload.update({"exp": expiracion})
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


def verificar_token(token: str = Depends(oauth2_scheme)):
    """Valida el token en cada petición protegida"""
    error_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise error_credenciales
        return username
    except JWTError:
        raise error_credenciales