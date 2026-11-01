from datetime import date
from fastapi import HTTPException, status
from repositories.salida_repository import SalidaRepository
from schemas.salida_schema import SalidaCreate, SalidaResponse
from services.exceptions import handle_db_error


class SalidaService:
    """Servicio de lógica de negocio para el registro y consulta de salidas hospitalarias."""

    @staticmethod
    def registrar_salida(datos: SalidaCreate) -> SalidaResponse:
        try:
            if datos.cantidad <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La cantidad de salida debe ser un número entero mayor que cero.",
                )
            if not datos.area_destino or not datos.area_destino.strip():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El área hospitalaria de destino es obligatoria.",
                )
            row = SalidaRepository.registrar(
                id_producto=datos.id_producto,
                cantidad=datos.cantidad,
                motivo=datos.motivo,
                area_destino=datos.area_destino,
                id_lote=datos.id_lote,
                numero_lote=datos.numero_lote,
                fecha=datos.fecha,
            )
            return SalidaResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def listar_salidas(
        id_producto: int | None = None,
        area_destino: str | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[SalidaResponse]:
        try:
            if fecha_inicio and fecha_fin and fecha_inicio > fecha_fin:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La fecha de inicio no puede ser posterior a la fecha de fin.",
                )
            rows = SalidaRepository.listar(
                id_producto=id_producto,
                area_destino=area_destino,
                fecha_inicio=fecha_inicio,
                fecha_fin=fecha_fin,
            )
            return [SalidaResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)
