from fastapi import APIRouter, Query, status
from schemas.categoria_schema import CategoriaCreate, CategoriaResponse, CategoriaUpdate
from services.categoria_service import CategoriaService

router = APIRouter(prefix="/categorias", tags=["Categorías"])


@router.get("", response_model=list[CategoriaResponse])
def listar_categorias(
    solo_activas: bool = Query(default=True, description="Filtrar únicamente categorías activas"),
):
    return CategoriaService.listar_categorias(solo_activas=solo_activas)


@router.get("/{id_categoria}", response_model=CategoriaResponse)
def obtener_categoria(id_categoria: int):
    return CategoriaService.obtener_categoria(id_categoria)


@router.post("", response_model=CategoriaResponse, status_code=status.HTTP_201_CREATED)
def registrar_categoria(datos: CategoriaCreate):
    return CategoriaService.registrar_categoria(datos)


@router.put("/{id_categoria}", response_model=CategoriaResponse)
def actualizar_categoria(id_categoria: int, datos: CategoriaUpdate):
    return CategoriaService.actualizar_categoria(id_categoria, datos)
