from fastapi import APIRouter
from api.auth import router as auth_router
from api.categorias import router as categorias_router
from api.entradas import router as entradas_router
from api.indicadores import router as indicadores_router
from api.movimientos import router as movimientos_router
from api.productos import router as productos_router
from api.salidas import router as salidas_router
from repositories.database import test_server_connection

api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router)
api_router.include_router(categorias_router)
api_router.include_router(productos_router)
api_router.include_router(entradas_router)
api_router.include_router(salidas_router)
api_router.include_router(movimientos_router)
api_router.include_router(indicadores_router)


@api_router.get("/health", tags=["Sistema"])
def health_check():
    """Verifica que el servidor FastAPI y la conexión a SQL Server están operativos."""
    db_info = test_server_connection()
    return {
        "status": "ok",
        "service": "backend-inventario-hospitalario",
        "hospital": "Hospital San Gabriel",
        "database": db_info,
    }
