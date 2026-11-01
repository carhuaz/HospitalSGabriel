import os
from contextlib import contextmanager
from pathlib import Path
from typing import Any

import pyodbc
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


class DatabaseConfig:
    """Configuración de conexión a SQL Server cargada desde variables de entorno."""

    DRIVER: str = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
    SERVER: str = os.getenv("DB_SERVER", r"localhost\SQLEXPRESS")
    DATABASE: str = os.getenv("DB_NAME", "HospitalSanGabrielDB")
    TRUSTED_CONNECTION: str = os.getenv("DB_TRUSTED_CONNECTION", "yes")
    USER: str = os.getenv("DB_USER", "")
    PASSWORD: str = os.getenv("DB_PASSWORD", "")
    TRUST_SERVER_CERTIFICATE: str = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")

    @classmethod
    def get_connection_string(cls, include_database: bool = True) -> str:
        parts = [
            f"DRIVER={{{cls.DRIVER}}}",
            f"SERVER={cls.SERVER}",
        ]
        if include_database:
            parts.append(f"DATABASE={cls.DATABASE}")

        if cls.TRUSTED_CONNECTION.lower() in ("yes", "true", "1"):
            parts.append("Trusted_Connection=yes")
        else:
            parts.append(f"UID={cls.USER}")
            parts.append(f"PWD={cls.PASSWORD}")

        if cls.TRUST_SERVER_CERTIFICATE.lower() in ("yes", "true", "1"):
            parts.append("TrustServerCertificate=yes")

        return ";".join(parts) + ";"


@contextmanager
def get_db_connection(include_database: bool = True, autocommit: bool = False):
    """Provee una conexión a SQL Server gestionando su cierre automático."""
    conn_str = DatabaseConfig.get_connection_string(include_database=include_database)
    conn = pyodbc.connect(conn_str, autocommit=autocommit)
    try:
        yield conn
    finally:
        conn.close()


def _rows_to_dicts(cursor: pyodbc.Cursor) -> list[dict[str, Any]]:
    if not cursor.description:
        return []
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def execute_sp_query(sp_name: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    """Ejecuta un procedimiento almacenado de consulta y devuelve una lista de diccionarios."""
    placeholders = ", ".join(["?"] * len(params))
    sql = f"EXEC {sp_name} {placeholders}" if placeholders else f"EXEC {sp_name}"
    with get_db_connection(autocommit=True) as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        while cursor.description is None:
            if not cursor.nextset():
                return []
        return _rows_to_dicts(cursor)


def execute_sp_one(sp_name: str, params: tuple[Any, ...] = ()) -> dict[str, Any] | None:
    """Ejecuta un procedimiento almacenado y devuelve el primer registro o None."""
    rows = execute_sp_query(sp_name, params)
    return rows[0] if rows else None


def execute_sp_multiple_sets(sp_name: str, params: tuple[Any, ...] = ()) -> list[list[dict[str, Any]]]:
    """Ejecuta un procedimiento almacenado que devuelve múltiples conjuntos de resultados."""
    placeholders = ", ".join(["?"] * len(params))
    sql = f"EXEC {sp_name} {placeholders}" if placeholders else f"EXEC {sp_name}"
    result_sets: list[list[dict[str, Any]]] = []
    with get_db_connection(autocommit=True) as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        while True:
            if cursor.description is not None:
                result_sets.append(_rows_to_dicts(cursor))
            if not cursor.nextset():
                break
    return result_sets


def test_server_connection() -> dict[str, str]:
    """Comprueba la conectividad con la instancia de SQL Server."""
    with get_db_connection(include_database=False, autocommit=True) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT @@SERVERNAME AS servidor, CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)) AS version")
        row = cursor.fetchone()
        return {
            "servidor": str(row.servidor) if row else DatabaseConfig.SERVER,
            "version": str(row.version) if row else "desconocida",
            "base_datos_objetivo": DatabaseConfig.DATABASE,
        }
