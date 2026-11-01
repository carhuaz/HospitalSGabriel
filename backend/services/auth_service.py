from fastapi import HTTPException, status
from repositories.auth_repository import AuthRepository
from schemas.auth_schema import LoginRequest, UsuarioResponse
from services.exceptions import handle_db_error


class AuthService:
    """Servicio de autenticación de usuarios del sistema hospitalario."""

    @staticmethod
    def login(datos: LoginRequest) -> UsuarioResponse:
        try:
            row = AuthRepository.autenticar(datos.username, datos.password)
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Credenciales incorrectas o usuario inactivo.",
                )
            return UsuarioResponse(**row)
        except Exception as exc:
            handle_db_error(exc)
