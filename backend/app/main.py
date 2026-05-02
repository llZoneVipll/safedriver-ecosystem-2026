from fastapi import FastAPI
app = FastAPI(
    title="SafeDriver API Cloud",
    description="Central de inteligencia para la prevención de fatiga y seguridad vial."
)
@app.get("/")
def health_check():
    return {"status": "operativo", "plataforma": "SafeDriver Backend"}