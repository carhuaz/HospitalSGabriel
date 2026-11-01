from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, Field, field_validator


class ProductoBase(BaseModel):
    codigo: str = Field(..., min_length=1, max_length=50, description="Código único del producto hospitalario")
    nombre: str = Field(..., min_length=2, max_length=150, description="Nombre del medicamento o insumo")
    descripcion: str | None = Field(default=None, max_length=500, description="Descripción detallada")
    id_categoria: int = Field(..., gt=0, description="ID de la categoría asociada")
    unidad_medida: str = Field(..., min_length=1, max_length=50, description="Unidad de medida (ej. Caja, Ampolla, Frasco, Unidad)")
    precio_unitario: Decimal = Field(..., gt=0, max_digits=12, decimal_places=2, description="Precio unitario mayor que cero")
    stock_minimo: int = Field(default=0, ge=0, description="Stock mínimo de alerta")
    fecha_vencimiento: date | None = Field(default=None, description="Fecha de vencimiento referencial cuando corresponda")
    maneja_lotes: bool = Field(default=True, description="Indica si el producto requiere trazabilidad por lotes")

    @field_validator("codigo", "nombre", "unidad_medida")
    @classmethod
    def validar_texto_obligatorio(cls, v: str) -> str:
        valor = v.strip()
        if not valor:
            raise ValueError("El campo no puede estar vacío ni contener solo espacios.")
        return valor


class ProductoCreate(ProductoBase):
    pass


class ProductoUpdate(ProductoBase):
    activo: bool = Field(default=True, description="Estado activo o inactivo del producto")


class ProductoResponse(BaseModel):
    id_producto: int
    codigo: str
    nombre: str
    descripcion: str | None = None
    id_categoria: int
    nombre_categoria: str
    unidad_medida: str
    precio_unitario: Decimal
    stock_actual: int
    stock_minimo: int
    fecha_vencimiento: date | None = None
    maneja_lotes: bool
    activo: bool
    fecha_creacion: datetime | None = None
    fecha_actualizacion: datetime | None = None
    stock_bajo: bool = False
    estado_vencimiento: str | None = None
    dias_para_vencer: int | None = None


class LoteResponse(BaseModel):
    id_lote: int
    id_producto: int
    codigo_producto: str
    nombre_producto: str
    numero_lote: str
    fecha_vencimiento: date | None = None
    cantidad_inicial: int
    stock_disponible: int
    activo: bool
    fecha_registro: datetime | None = None
    estado_vencimiento: str
    dias_para_vencer: int | None = None


class ProductoStockBajoResponse(BaseModel):
    id_producto: int
    codigo: str
    nombre: str
    id_categoria: int
    nombre_categoria: str
    unidad_medida: str
    precio_unitario: Decimal
    stock_actual: int
    stock_minimo: int
    deficit_stock: int
    fecha_vencimiento: date | None = None
    activo: bool


class ProductoVencimientoResponse(BaseModel):
    id_producto: int
    codigo: str
    nombre: str
    id_categoria: int
    nombre_categoria: str
    unidad_medida: str
    precio_unitario: Decimal
    stock_actual: int
    id_lote: int | None = None
    numero_lote: str | None = None
    cantidad_afectada: int
    fecha_vencimiento: date
    dias_para_vencer: int
    estado_vencimiento: str
