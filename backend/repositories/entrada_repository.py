from datetime import date, datetime
from typing import Any
from repositories.database import execute_sp_one, execute_sp_query


class EntradaRepository:
    """Repositorio de acceso a datos de Entradas mediante procedimientos almacenados."""

    @staticmethod
    def registrar(
        id_producto: int,
        cantidad: int,
        motivo: str,
        numero_lote: str | None = None,
        fecha_vencimiento: date | None = None,
        fecha: datetime | None = None,
    ) -> dict[str, Any] | None:
        return execute_sp_one(
            "dbo.sp_Entradas_Registrar",
            (id_producto, cantidad, motivo, numero_lote, fecha_vencimiento, fecha),
        )

    @staticmethod
    def listar(
        id_producto: int | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Entradas_Listar",
            (id_producto, fecha_inicio, fecha_fin),
        )
