from datetime import date
from decimal import Decimal
from typing import Any
from repositories.database import execute_sp_one, execute_sp_query


class ProductoRepository:
    """Repositorio de acceso a datos de Productos y Lotes mediante procedimientos almacenados."""

    @staticmethod
    def listar(
        busqueda: str | None = None,
        id_categoria: int | None = None,
        solo_activos: bool | None = None,
    ) -> list[dict[str, Any]]:
        activo_param = None if solo_activos is None else (1 if solo_activos else 0)
        return execute_sp_query(
            "dbo.sp_Productos_Listar",
            (busqueda, id_categoria, activo_param),
        )

    @staticmethod
    def obtener_por_id(id_producto: int) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Productos_ObtenerPorId", (id_producto,))

    @staticmethod
    def registrar(
        codigo: str,
        nombre: str,
        descripcion: str | None,
        id_categoria: int,
        unidad_medida: str,
        precio_unitario: Decimal,
        stock_minimo: int,
        fecha_vencimiento: date | None,
        maneja_lotes: bool,
    ) -> dict[str, Any] | None:
        return execute_sp_one(
            "dbo.sp_Productos_Registrar",
            (
                codigo,
                nombre,
                descripcion,
                id_categoria,
                unidad_medida,
                precio_unitario,
                stock_minimo,
                fecha_vencimiento,
                1 if maneja_lotes else 0,
            ),
        )

    @staticmethod
    def actualizar(
        id_producto: int,
        codigo: str,
        nombre: str,
        descripcion: str | None,
        id_categoria: int,
        unidad_medida: str,
        precio_unitario: Decimal,
        stock_minimo: int,
        fecha_vencimiento: date | None,
        maneja_lotes: bool,
        activo: bool,
    ) -> dict[str, Any] | None:
        return execute_sp_one(
            "dbo.sp_Productos_Actualizar",
            (
                id_producto,
                codigo,
                nombre,
                descripcion,
                id_categoria,
                unidad_medida,
                precio_unitario,
                stock_minimo,
                fecha_vencimiento,
                1 if maneja_lotes else 0,
                1 if activo else 0,
            ),
        )

    @staticmethod
    def desactivar(id_producto: int) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Productos_Desactivar", (id_producto,))

    @staticmethod
    def listar_lotes(id_producto: int, solo_con_stock: bool = False) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Lotes_ListarPorProducto",
            (id_producto, 1 if solo_con_stock else 0),
        )

    @staticmethod
    def listar_stock_bajo() -> list[dict[str, Any]]:
        return execute_sp_query("dbo.sp_Productos_StockBajo")

    @staticmethod
    def listar_vencimientos(
        dias_alerta: int = 30,
        estado: str | None = None,
    ) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Productos_Vencimientos",
            (dias_alerta, estado),
        )
