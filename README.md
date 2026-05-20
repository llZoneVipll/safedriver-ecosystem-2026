SafeDriver - Ecosistema Digital (2026)
Sistema Inteligente de Prevención de Fatiga y Seguridad Vial
Monorepo desarrollado para el curso de Desarrollo Basado en Plataformas.
Arquitectura del Proyecto
El ecosistema está dividido en plataformas independientes que conviven en este monorepo:
* **Backend:** API RESTful construida con Python (FastAPI, SQLAlchemy, JWT).
* **Mobile:** Consola de supervisión construida con Flutter (Dart, Provider/HTTP).

Instrucciones de Ejecución

1. Levantar la Central de Inteligencia (Backend)
1. Abrir una terminal e ingresar a la carpeta: `cd backend`
2. Activar el entorno virtual: 
   * Windows: `.\venv\Scripts\activate`
   * Linux/WSL: `source venv/bin/activate`
3. Instalar dependencias (si es primera vez): `pip install fastapi uvicorn[standard] sqlalchemy python-multipart "python-jose[cryptography]" "passlib[bcrypt]"`
4. Iniciar el servidor: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
*Nota: Swagger interactivo disponible en `http://localhost:8000/docs`*

2. Levantar la Consola de Monitoreo (Mobile)
1. Abrir una **nueva terminal** e ingresar a la carpeta: `cd mobile`
2. Descargar librerías (si es primera vez): `flutter pub get`
3. Ejecutar la aplicación (Web/Local): `flutter run -d chrome` o `flutter run`

Credenciales de Prueba (JWT)
Para probar los endpoints protegidos o iniciar sesión en la App móvil:
* **Usuario:** `admin`
* **Contraseña:** `safedriver123`
