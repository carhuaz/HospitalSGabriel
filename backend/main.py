from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.router import api_router

app = FastAPI(
    title="Sistema de Inventario Hospitalario - Hospital San Gabriel",
    description=(
        "API REST con arquitectura por capas y procedimientos almacenados en SQL Server "
        "para la gestión de medicamentos, insumos médicos y materiales hospitalarios."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/", tags=["Sistema"])
def root():
    return {
        "sistema": "Hospital San Gabriel - Sistema de Inventario Hospitalario",
        "estado": "operativo",
        "version": "1.0.0",
        "docs": "/docs",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
