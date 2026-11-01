from fastapi import HTTPException, status
from repositories.categoria_repository import CategoriaRepository
from schemas.categoria_schema import CategoriaCreate, CategoriaResponse, CategoriaUpdate
from services.exceptions import handle_db_error


class CategoriaService:
    """Servicio de lógica de negocio para la gestión de categorías."""

    @staticmethod
    def listar_categorias(solo_activas: bool = True) -> list[CategoriaResponse]:
        try:
            rows = CategoriaRepository.listar(solo_activas=solo_activas)
            return [CategoriaResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def obtener_categoria(id_categoria: int) -> CategoriaResponse:
        try:
            row = CategoriaRepository.obtener_por_id(id_categoria)
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="La categoría solicitada no existe.",
                )
            return CategoriaResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def registrar_categoria(datos: CategoriaCreate) -> CategoriaResponse:
        try:
            row = CategoriaRepository.registrar(
                nombre=datos.nombre,
                descripcion=datos.descripcion,
            )
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="No fue posible registrar la categoría.",
                )
            return CategoriaResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def actualizar_categoria(id_categoria: int, datos: CategoriaUpdate) -> CategoriaResponse:
        try:
            row = CategoriaRepository.actualizar(
                id_categoria=id_categoria,
                nombre=datos.nombre,
                descripcion=datos.descripcion,
                activo=datos.activo,
            )
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="La categoría indicada no existe.",
                )
            return CategoriaResponse(**row)
        except Exception as exc:
            handle_db_error(exc)
