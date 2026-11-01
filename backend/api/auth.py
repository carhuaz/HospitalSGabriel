from fastapi import APIRouter
from schemas.auth_schema import LoginRequest, UsuarioResponse
from services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/login", response_model=UsuarioResponse)
def iniciar_sesion(datos: LoginRequest):
    return AuthService.login(datos)
