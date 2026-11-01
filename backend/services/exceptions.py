import re
import pyodbc
from fastapi import HTTPException, status


def handle_db_error(exc: Exception) -> None:
    """Traduce errores de SQL Server y de negocio a HTTPException con código HTTP apropiado."""
    if isinstance(exc, HTTPException):
        raise exc

    if isinstance(exc, pyodbc.Error):
        raw_msg = str(exc)
        # Extraer mensaje limpio después del último corchete de ODBC
        cleaned = re.sub(r"^.*\](\s*)", "", raw_msg)
        cleaned = re.sub(r"\(\d+\)\s*\(SQLExecDirectW\)\'\)$", "", cleaned).strip(" '\"")

        # Clasificar según el código de error personalizado de nuestros Stored Procedures
        if any(code in raw_msg for code in ("50003", "50016", "50034")):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=cleaned or "El recurso solicitado no fue encontrado.",
            ) from exc

        if any(code in raw_msg for code in ("50002", "50011")) or "UQ_" in raw_msg:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=cleaned or "Ya existe un registro con el código o nombre indicado.",
            ) from exc

        if any(
            code in raw_msg
            for code in (
                "50001",
                "50004",
                "50009",
                "50010",
                "50012",
                "50013",
                "50014",
                "50015",
                "50020",
                "50021",
                "50022",
                "50023",
                "50030",
                "50031",
                "50032",
                "50033",
            )
        ) or "CK_" in raw_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=cleaned or "Operación rechazada por reglas de negocio del inventario.",
            ) from exc

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en la base de datos: {cleaned}",
        ) from exc

    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail=f"Error interno del servidor: {str(exc)}",
    ) from exc
