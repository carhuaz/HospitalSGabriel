from datetime import date
from fastapi import APIRouter, Query
from schemas.indicador_schema import IndicadoresResumenResponse, ProductoMayorSalidaResponse
from schemas.producto_schema import ProductoStockBajoResponse, ProductoVencimientoResponse
from services.indicador_service import IndicadorService
from services.producto_service import ProductoService

router = APIRouter(prefix="/indicadores", tags=["Consultas e Indicadores"])


@router.get("/resumen", response_model=IndicadoresResumenResponse)
def obtener_resumen_indicadores(
    dias_alerta: int = Query(default=30, ge=0, description="Días de alerta para productos próximos a vencer"),
):
    return IndicadorService.obtener_resumen(dias_alerta=dias_alerta)


@router.get("/stock-bajo", response_model=list[ProductoStockBajoResponse])
def consultar_productos_stock_bajo():
    return ProductoService.listar_stock_bajo()


@router.get("/vencimientos", response_model=list[ProductoVencimientoResponse])
def consultar_productos_vencimientos(
    dias_alerta: int = Query(default=30, ge=0, description="Días de anticipación para considerar próximo a vencer"),
    estado: str | None = Query(default=None, description="Filtrar por 'VENCIDO' o 'PROXIMO_A_VENCER'"),
):
    return ProductoService.listar_vencimientos(dias_alerta=dias_alerta, estado=estado)


@router.get("/mayores-salidas", response_model=list[ProductoMayorSalidaResponse])
def consultar_productos_mayores_salidas(
    fecha_inicio: date | None = Query(default=None, description="Fecha inicial del periodo"),
    fecha_fin: date | None = Query(default=None, description="Fecha final del periodo"),
    top: int = Query(default=10, gt=0, le=100, description="Cantidad máxima de productos a mostrar"),
):
    return IndicadorService.obtener_productos_mayores_salidas(
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        top=top,
    )
