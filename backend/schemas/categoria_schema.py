from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class CategoriaBase(BaseModel):
    nombre: str = Field(..., min_length=2, max_length=100, description="Nombre de la categoría hospitalaria")
    descripcion: str | None = Field(default=None, max_length=255, description="Descripción de la categoría")

    @field_validator("nombre")
    @classmethod
    def validar_nombre_no_vacio(cls, v: str) -> str:
        valor = v.strip()
        if not valor:
            raise ValueError("El nombre de la categoría no puede estar vacío.")
        return valor


class CategoriaCreate(CategoriaBase):
    pass


class CategoriaUpdate(CategoriaBase):
    activo: bool = Field(default=True, description="Estado activo/inactivo de la categoría")


class CategoriaResponse(BaseModel):
    id_categoria: int
    nombre: str
    descripcion: str | None = None
    activo: bool
    fecha_creacion: datetime | None = None
    total_productos: int | None = 0
