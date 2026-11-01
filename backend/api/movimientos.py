from datetime import date
from fastapi import APIRouter, Query
from schemas.movimiento_schema import MovimientoResponse
from services.movimiento_service import MovimientoService

router = APIRouter(prefix="/movimientos", tags=["Historial de Movimientos"])


@router.get("", response_model=list[MovimientoResponse])
def listar_movimientos(
    id_producto: int | None = Query(default=None, gt=0, description="Filtrar por ID de producto"),
    tipo_movimiento: str | None = Query(default=None, description="Filtrar por tipo: 'ENTRADA' o 'SALIDA'"),
    area_destino: str | None = Query(default=None, description="Filtrar por área hospitalaria de destino"),
    fecha_inicio: date | None = Query(default=None, description="Fecha inicial del rango"),
    fecha_fin: date | None = Query(default=None, description="Fecha final del rango"),
):
    return MovimientoService.listar_movimientos(
        id_producto=id_producto,
        tipo_movimiento=tipo_movimiento,
        area_destino=area_destino,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
    )
