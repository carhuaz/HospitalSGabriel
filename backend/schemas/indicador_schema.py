from decimal import Decimal
from pydantic import BaseModel


class IndicadoresResumenResponse(BaseModel):
    total_productos_activos: int
    total_categorias_activas: int
    total_productos_stock_bajo: int
    total_productos_vencidos: int
    total_productos_proximos_vencer: int
    valor_referencial_inventario: Decimal
    total_movimientos_hoy: int


class ProductoMayorSalidaResponse(BaseModel):
    id_producto: int
    codigo: str
    nombre: str
    nombre_categoria: str
    unidad_medida: str
    precio_unitario: Decimal
    stock_actual: int
    total_unidades_salidas: int
    numero_salidas: int
    valor_estimado_salidas: Decimal
