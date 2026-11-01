from datetime import date, datetime
from pydantic import BaseModel


class MovimientoResponse(BaseModel):
    id_movimiento: int
    id_producto: int
    codigo_producto: str
    nombre_producto: str
    nombre_categoria: str
    tipo_movimiento: str
    cantidad: int
    fecha: datetime
    motivo: str
    area_destino: str | None = None
    id_lote: int | None = None
    numero_lote: str | None = None
    fecha_vencimiento_lote: date | None = None
    stock_anterior: int
    stock_posterior: int
