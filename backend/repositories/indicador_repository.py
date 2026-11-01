from datetime import date
from typing import Any
from repositories.database import execute_sp_one, execute_sp_query


class IndicadorRepository:
    """Repositorio de Consultas e Indicadores del Inventario mediante procedimientos almacenados."""

    @staticmethod
    def obtener_resumen(dias_alerta: int = 30) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Indicadores_Resumen", (dias_alerta,))

    @staticmethod
    def obtener_productos_mayores_salidas(
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
        top: int = 10,
    ) -> list[dict[str, Any]]:
        return execute_sp_query(
            "dbo.sp_Indicadores_ProductosMayoresSalidas",
            (fecha_inicio, fecha_fin, top),
        )
