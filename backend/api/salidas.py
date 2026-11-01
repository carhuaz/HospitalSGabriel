from datetime import date
from fastapi import APIRouter, Query, status
from schemas.salida_schema import SalidaCreate, SalidaResponse
from services.salida_service import SalidaService

router = APIRouter(prefix="/salidas", tags=["Salidas Hospitalarias"])


@router.get("", response_model=list[SalidaResponse])
def listar_salidas(
    id_producto: int | None = Query(default=None, gt=0, description="Filtrar por ID de producto"),
    area_destino: str | None = Query(default=None, description="Filtrar por área hospitalaria de destino"),
    fecha_inicio: date | None = Query(default=None, description="Fecha inicial del rango"),
    fecha_fin: date | None = Query(default=None, description="Fecha final del rango"),
):
    return SalidaService.listar_salidas(
        id_producto=id_producto,
        area_destino=area_destino,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
    )


@router.post("", response_model=SalidaResponse, status_code=status.HTTP_201_CREATED)
def registrar_salida(datos: SalidaCreate):
    return SalidaService.registrar_salida(datos)
