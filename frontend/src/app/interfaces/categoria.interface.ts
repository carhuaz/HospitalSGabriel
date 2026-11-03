export interface Categoria {
  id_categoria: number;
  nombre: string;
  descripcion: string | null;
  activo: boolean;
  fecha_creacion: string | null;
  total_productos?: number | null;
}

export interface CategoriaCreate {
  nombre: string;
  descripcion: string | null;
}

export interface CategoriaUpdate extends CategoriaCreate {
  activo: boolean;
}
