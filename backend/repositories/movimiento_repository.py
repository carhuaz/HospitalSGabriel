from datetime import date
from typing import Any
from repositories.database import execute_sp_query


class MovimientoRepository:
    """Repositorio de acceso al Historial de Movimientos mediante procedimientos almacenados."""

    @staticmethod
    def listar(
        id_producto: int | None = None,
        tipo_movimiento: str | None = None,
        area_destino: str | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Movimientos_Listar",
            (
                id_producto,
                tipo_movimiento,
                area_destino,
                fecha_inicio,
                fecha_fin,
            ),
        )
