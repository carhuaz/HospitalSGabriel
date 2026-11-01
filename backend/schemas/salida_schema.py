from datetime import date, datetime
from pydantic import BaseModel, Field, field_validator


class SalidaCreate(BaseModel):
    id_producto: int = Field(..., gt=0, description="ID del producto a retirar")
    cantidad: int = Field(..., gt=0, description="Cantidad entera mayor que cero")
    motivo: str = Field(..., min_length=2, max_length=150, description="Motivo de la salida hospitalaria")
    area_destino: str = Field(
        ...,
        min_length=2,
        max_length=100,
        description="Área hospitalaria de destino (Emergencia, Hospitalización, Consultorios Externos, Laboratorio, etc.)",
    )
    id_lote: int | None = Field(default=None, gt=0, description="ID del lote específico a retirar (opcional)")
    numero_lote: str | None = Field(default=None, max_length=60, description="Número de lote específico a retirar (opcional)")
    fecha: datetime | None = Field(default=None, description="Fecha y hora de la salida (opcional)")

    @field_validator("motivo", "area_destino")
    @classmethod
    def validar_campos_texto(cls, v: str) -> str:
        valor = v.strip()
        if not valor:
            raise ValueError("El campo es obligatorio y no puede estar vacío.")
        return valor

    @field_validator("numero_lote")
    @classmethod
    def limpiar_numero_lote(cls, v: str | None) -> str | None:
        if v is None:
            return None
        valor = v.strip()
        return valor if valor else None


class SalidaResponse(BaseModel):
    id_salida: int
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
    area_destino: str
    stock_anterior: int | None = None
    stock_posterior: int | None = None
