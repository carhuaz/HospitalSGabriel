from fastapi import HTTPException, status
from repositories.producto_repository import ProductoRepository
from schemas.producto_schema import (
    LoteResponse,
    ProductoCreate,
    ProductoResponse,
    ProductoStockBajoResponse,
    ProductoUpdate,
    ProductoVencimientoResponse,
)
from services.exceptions import handle_db_error


class ProductoService:
    """Servicio de lógica de negocio para la gestión de productos hospitalarios y lotes."""

    @staticmethod
    def listar_productos(
        busqueda: str | None = None,
        id_categoria: int | None = None,
        solo_activos: bool | None = None,
    ) -> list[ProductoResponse]:
        try:
            rows = ProductoRepository.listar(
                busqueda=busqueda,
                id_categoria=id_categoria,
                solo_activos=solo_activos,
            )
            return [ProductoResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def obtener_producto(id_producto: int) -> ProductoResponse:
        try:
            row = ProductoRepository.obtener_por_id(id_producto)
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="El producto solicitado no existe.",
                )
            return ProductoResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def registrar_producto(datos: ProductoCreate) -> ProductoResponse:
        try:
            if datos.precio_unitario <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El precio unitario debe ser mayor que cero.",
                )
            row = ProductoRepository.registrar(
                codigo=datos.codigo,
                nombre=datos.nombre,
                descripcion=datos.descripcion,
                id_categoria=datos.id_categoria,
                unidad_medida=datos.unidad_medida,
                precio_unitario=datos.precio_unitario,
                stock_minimo=datos.stock_minimo,
                fecha_vencimiento=datos.fecha_vencimiento,
                maneja_lotes=datos.maneja_lotes,
            )
            return ProductoResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def actualizar_producto(id_producto: int, datos: ProductoUpdate) -> ProductoResponse:
        try:
            if datos.precio_unitario <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El precio unitario debe ser mayor que cero.",
                )
            row = ProductoRepository.actualizar(
                id_producto=id_producto,
                codigo=datos.codigo,
                nombre=datos.nombre,
                descripcion=datos.descripcion,
                id_categoria=datos.id_categoria,
                unidad_medida=datos.unidad_medida,
                precio_unitario=datos.precio_unitario,
                stock_minimo=datos.stock_minimo,
                fecha_vencimiento=datos.fecha_vencimiento,
                maneja_lotes=datos.maneja_lotes,
                activo=datos.activo,
            )
            return ProductoResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def desactivar_producto(id_producto: int) -> ProductoResponse:
        try:
            row = ProductoRepository.desactivar(id_producto)
            return ProductoResponse(**row)
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def listar_lotes_producto(id_producto: int, solo_con_stock: bool = False) -> list[LoteResponse]:
        try:
            ProductoService.obtener_producto(id_producto)
            rows = ProductoRepository.listar_lotes(id_producto, solo_con_stock=solo_con_stock)
            return [LoteResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def listar_stock_bajo() -> list[ProductoStockBajoResponse]:
        try:
            rows = ProductoRepository.listar_stock_bajo()
            return [ProductoStockBajoResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)

    @staticmethod
    def listar_vencimientos(
        dias_alerta: int = 30,
        estado: str | None = None,
    ) -> list[ProductoVencimientoResponse]:
        try:
            if dias_alerta < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El número de días de alerta no puede ser negativo.",
                )
            if estado and estado.upper() not in ("VENCIDO", "PROXIMO_A_VENCER"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El filtro de estado debe ser 'VENCIDO' o 'PROXIMO_A_VENCER'.",
                )
            rows = ProductoRepository.listar_vencimientos(dias_alerta=dias_alerta, estado=estado)
            return [ProductoVencimientoResponse(**row) for row in rows]
        except Exception as exc:
            handle_db_error(exc)
