from datetime import date
from fastapi import HTTPException, status
from repositories.indicador_repository import IndicadorRepository
from schemas.indicador_schema import IndicadoresResumenResponse, ProductoMayorSalidaResponse
from services.exceptions import handle_db_error


class IndicadorService:
    """Servicio de lógica de negocio para consultas e indicadores en tiempo real."""

    @staticmethod
    def obtener_resumen(dias_alerta: int = 30) -> IndicadoresResumenResponse:
        try:
            if dias_alerta < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Los días de alerta no pueden ser negativos.",
                )
            row = IndicadorRepository.obtener_resumen(dias_alerta=dias_alerta)
            return IndicadoresResumenResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def obtener_productos_mayores_salidas(
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
        top: int = 10,
    ) -> list[ProductoMayorSalidaResponse]:
        try:
            if fecha_inicio and fecha_fin and fecha_inicio > fecha_fin:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La fecha de inicio no puede ser posterior a la fecha de fin.",
                )
            rows = IndicadorRepository.obtener_productos_mayores_salidas(
                fecha_inicio=fecha_inicio,
                fecha_fin=fecha_fin,
                top=top,
            )
            return [ProductoMayorSalidaResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)
