from typing import Any
from repositories.database import execute_sp_one, execute_sp_query


class CategoriaRepository:
    """Repositorio de acceso a datos de Categorías mediante procedimientos almacenados."""

    @staticmethod
    def listar(solo_activas: bool = True) -> list[dict[str, Any]]:
        return execute_sp_query("dbo.sp_Categorias_Listar", (1 if solo_activas else 0,))

    @staticmethod
    def obtener_por_id(id_categoria: int) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Categorias_ObtenerPorId", (id_categoria,))

    @staticmethod
    def registrar(nombre: str, descripcion: str | None = None) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Categorias_Registrar", (nombre, descripcion))

    @staticmethod
    def actualizar(
        id_categoria: int,
        nombre: str,
        descripcion: str | None = None,
        activo: bool = True,
    ) -> dict[str, Any] | None:
        return execute_sp_one(
            "dbo.sp_Categorias_Actualizar",
            (id_categoria, nombre, descripcion, 1 if activo else 0),
        )
