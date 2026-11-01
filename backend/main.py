from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Sistema de Inventario Hospitalario - Hospital San Gabriel",
    description="API REST para la gestión de inventario hospitalario",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "sistema": "Hospital San Gabriel - Sistema de Inventario Hospitalario",
        "estado": "operativo",
        "version": "0.1.0",
    }


@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "backend-inventario-hospitalario"}
