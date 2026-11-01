from datetime import date, datetime
from typing import Any
from repositories.database import execute_sp_one, execute_sp_query


class SalidaRepository:
    """Repositorio de acceso a datos de Salidas mediante procedimientos almacenados."""

    @staticmethod
    def registrar(
        id_producto: int,
        cantidad: int,
        motivo: str,
        area_destino: str,
        id_lote: int | None = None,
        numero_lote: str | None = None,
        fecha: datetime | None = None,
    ) -> dict[str, Any] | None:
        return execute_sp_one(
            "dbo.sp_Salidas_Registrar",
            (
                id_producto,
                cantidad,
                motivo,
                area_destino,
                id_lote,
                numero_lote,
                fecha,
            ),
        )

    @staticmethod
    def listar(
        id_producto: int | None = None,
        area_destino: str | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Salidas_Listar",
            (id_producto, area_destino, fecha_inicio, fecha_fin),
        )
