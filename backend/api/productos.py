from fastapi import APIRouter, Query, status
from schemas.producto_schema import (
    LoteResponse,
    ProductoCreate,
    ProductoResponse,
    ProductoStockBajoResponse,
    ProductoUpdate,
    ProductoVencimientoResponse,
)
from services.producto_service import ProductoService

router = APIRouter(prefix="/productos", tags=["Productos Hospitalarios"])


@router.get("", response_model=list[ProductoResponse])
def listar_productos(
    busqueda: str | None = Query(default=None, description="Buscar por código o nombre del producto"),
    id_categoria: int | None = Query(default=None, gt=0, description="Filtrar por ID de categoría"),
    solo_activos: bool | None = Query(default=None, description="Filtrar por estado activo/inactivo"),
):
    return ProductoService.listar_productos(
        busqueda=busqueda,
        id_categoria=id_categoria,
        solo_activos=solo_activos,
    )


@router.get("/stock-bajo", response_model=list[ProductoStockBajoResponse])
def listar_productos_stock_bajo():
    return ProductoService.listar_stock_bajo()


@router.get("/vencimientos", response_model=list[ProductoVencimientoResponse])
def listar_productos_vencimientos(
    dias_alerta: int = Query(default=30, ge=0, description="Días de anticipación para considerar próximo a vencer"),
    estado: str | None = Query(default=None, description="Filtrar por 'VENCIDO' o 'PROXIMO_A_VENCER'"),
):
    return ProductoService.listar_vencimientos(dias_alerta=dias_alerta, estado=estado)


@router.get("/{id_producto}", response_model=ProductoResponse)
def obtener_producto(id_producto: int):
    return ProductoService.obtener_producto(id_producto)


@router.get("/{id_producto}/lotes", response_model=list[LoteResponse])
def listar_lotes_producto(
    id_producto: int,
    solo_con_stock: bool = Query(default=False, description="Mostrar solo lotes con stock disponible"),
):
    return ProductoService.listar_lotes_producto(id_producto, solo_con_stock=solo_con_stock)


@router.post("", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def registrar_producto(datos: ProductoCreate):
    return ProductoService.registrar_producto(datos)


@router.put("/{id_producto}", response_model=ProductoResponse)
def actualizar_producto(id_producto: int, datos: ProductoUpdate):
    return ProductoService.actualizar_producto(id_producto, datos)


@router.patch("/{id_producto}/desactivar", response_model=ProductoResponse)
def desactivar_producto(id_producto: int):
    return ProductoService.desactivar_producto(id_producto)


@router.delete("/{id_producto}", response_model=ProductoResponse)
def eliminar_logico_producto(id_producto: int):
    """Desactiva el producto conservando su historial de movimientos (Regla 7)."""
    return ProductoService.desactivar_producto(id_producto)
