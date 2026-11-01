from fastapi import APIRouter

api_router = APIRouter(prefix="/api")


@api_router.get("/health", tags=["Sistema"])
def health_check():
    """Verifica que el servidor FastAPI se encuentra en ejecución."""
    return {
        "status": "ok",
        "service": "backend-inventario-hospitalario",
        "hospital": "Hospital San Gabriel",
    }
