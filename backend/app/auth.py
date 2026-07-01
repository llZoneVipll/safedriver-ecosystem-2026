from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer

SECRET_KEY = "SAFEDRIVER_UNMSM_SECRET_2026"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ── Base de datos de usuarios simulada con los 3 conductores ─────
USUARIOS_DB = {
    "admin": {
        "username": "admin",
        "password": "safedriver123",
        "role": "gestor",
        "conductor_id": None
    },
    "conductor1": {
        "username": "conductor1",
        "password": "driver123",
        "role": "usuario",
        "conductor_id": 1
    },
    "conductor2": {
        "username": "conductor2",
        "password": "driver123",
        "role": "usuario",
        "conductor_id": 2
    },
    "conductor3": {
        "username": "conductor3",
        "password": "driver123",
        "role": "usuario",
        "conductor_id": 3
    }
}

def crear_token_acceso(data: dict):
    payload = data.copy()
    expiracion = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload.update({"exp": expiracion})
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token

def verificar_token(token: str = Depends(oauth2_scheme)):
    error_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        role: str = payload.get("role")
        
        if username is None or role is None:
            raise error_credenciales
            
        user_data = USUARIOS_DB.get(username, {})
        conductor_id = user_data.get("conductor_id")
        
        return {"username": username, "role": role, "conductor_id": conductor_id}
    except JWTError:
        raise error_credenciales

def requerir_rol(roles_permitidos: list):
    def validacion(usuario_actual: dict = Depends(verificar_token)):
        if usuario_actual["role"] not in roles_permitidos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta acción"
            )
        return usuario_actual
    return validacion
