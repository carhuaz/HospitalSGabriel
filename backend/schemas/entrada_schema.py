from datetime import date, datetime
from pydantic import BaseModel, Field, field_validator


class EntradaCreate(BaseModel):
    id_producto: int = Field(..., gt=0, description="ID del producto que ingresa")
    cantidad: int = Field(..., gt=0, description="Cantidad entera mayor que cero")
    motivo: str = Field(..., min_length=2, max_length=150, description="Motivo de ingreso (Compra, Donación, Devolución)")
    numero_lote: str | None = Field(default=None, max_length=60, description="Número de lote cuando corresponda")
    fecha_vencimiento: date | None = Field(default=None, description="Fecha de vencimiento del lote o ingreso")
    fecha: datetime | None = Field(default=None, description="Fecha y hora del ingreso (opcional, por defecto fecha actual)")

    @field_validator("motivo")
    @classmethod
    def validar_motivo(cls, v: str) -> str:
        valor = v.strip()
        if not valor:
            raise ValueError("El motivo de la entrada es obligatorio.")
        return valor

    @field_validator("numero_lote")
    @classmethod
    def limpiar_numero_lote(cls, v: str | None) -> str | None:
        if v is None:
            return None
        valor = v.strip()
        return valor if valor else None


class EntradaResponse(BaseModel):
    id_entrada: int
    id_movimiento: int | None = None
    id_producto: int
    codigo_producto: str
    nombre_producto: str
    id_lote: int | None = None
    numero_lote: str | None = None
    fecha_vencimiento: date | None = None
    cantidad: int
    fecha: datetime
    motivo: str
    stock_anterior: int | None = None
    stock_posterior: int | None = None
