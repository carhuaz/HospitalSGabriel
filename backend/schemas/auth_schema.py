from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=50)
    password: str = Field(..., min_length=1, max_length=255)


class UsuarioResponse(BaseModel):
    id_usuario: int
    username: str
    nombre_completo: str
    rol: str
    activo: bool
