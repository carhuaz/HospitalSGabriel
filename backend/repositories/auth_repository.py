from typing import Any
from repositories.database import execute_sp_one


class AuthRepository:
    """Repositorio de autenticación de usuarios mediante procedimientos almacenados."""

    @staticmethod
    def autenticar(username: str, password: str) -> dict[str, Any] | None:
        return execute_sp_one("dbo.sp_Usuarios_Autenticar", (username, password))
