from datetime import date
from fastapi import HTTPException, status
from repositories.movimiento_repository import MovimientoRepository
from schemas.movimiento_schema import MovimientoResponse
from services.exceptions import handle_db_error


class MovimientoService:
    """Servicio de lógica de negocio para la consulta y filtrado del historial de movimientos."""

    @staticmethod
    def listar_movimientos(
        id_producto: int | None = None,
        tipo_movimiento: str | None = None,
        area_destino: str | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[MovimientoResponse]:
        try:
            if tipo_movimiento and tipo_movimiento.upper() not in ("ENTRADA", "SALIDA"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El tipo de movimiento debe ser 'ENTRADA' o 'SALIDA'.",
                )
            if fecha_inicio and fecha_fin and fecha_inicio > fecha_fin:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La fecha de inicio no puede ser posterior a la fecha de fin.",
                )
            rows = MovimientoRepository.listar(
                id_producto=id_producto,
                tipo_movimiento=tipo_movimiento,
                area_destino=area_destino,
                fecha_inicio=fecha_inicio,
                fecha_fin=fecha_fin,
            )
            return [MovimientoResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)
