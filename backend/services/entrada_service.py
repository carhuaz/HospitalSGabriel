from datetime import date
from fastapi import HTTPException, status
from repositories.entrada_repository import EntradaRepository
from schemas.entrada_schema import EntradaCreate, EntradaResponse
from services.exceptions import handle_db_error


class EntradaService:
    """Servicio de lógica de negocio para el registro y consulta de entradas de inventario."""

    @staticmethod
    def registrar_entrada(datos: EntradaCreate) -> EntradaResponse:
        try:
            if datos.cantidad <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La cantidad de entrada debe ser un número entero mayor que cero.",
                )
            row = EntradaRepository.registrar(
                id_producto=datos.id_producto,
                cantidad=datos.cantidad,
                motivo=datos.motivo,
                numero_lote=datos.numero_lote,
                fecha_vencimiento=datos.fecha_vencimiento,
                fecha=datos.fecha,
            )
            return EntradaResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def listar_entradas(
        id_producto: int | None = None,
        fecha_inicio: date | None = None,
        fecha_fin: date | None = None,
    ) -> list[EntradaResponse]:
        try:
            if fecha_inicio and fecha_fin and fecha_inicio > fecha_fin:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La fecha de inicio no puede ser posterior a la fecha de fin.",
                )
            rows = EntradaRepository.listar(
                id_producto=id_producto,
                fecha_inicio=fecha_inicio,
                fecha_fin=fecha_fin,
            )
            return [EntradaResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)
