from datetime import date
from fastapi import APIRouter, Query, status
from schemas.entrada_schema import EntradaCreate, EntradaResponse
from services.entrada_service import EntradaService

router = APIRouter(prefix="/entradas", tags=["Entradas de Inventario"])


@router.get("", response_model=list[EntradaResponse])
def listar_entradas(
    id_producto: int | None = Query(default=None, gt=0, description="Filtrar por ID de producto"),
    fecha_inicio: date | None = Query(default=None, description="Fecha inicial del rango"),
    fecha_fin: date | None = Query(default=None, description="Fecha final del rango"),
):
    return EntradaService.listar_entradas(
        id_producto=id_producto,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
    )


@router.post("", response_model=EntradaResponse, status_code=status.HTTP_201_CREATED)
def registrar_entrada(datos: EntradaCreate):
    return EntradaService.registrar_entrada(datos)
