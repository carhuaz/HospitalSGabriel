export interface Producto {
  id_producto: number;
  codigo: string;
  nombre: string;
  descripcion: string | null;
  id_categoria: number;
  nombre_categoria: string;
  unidad_medida: string;
  precio_unitario: string;
  stock_actual: number;
  stock_minimo: number;
  fecha_vencimiento: string | null;
  maneja_lotes: boolean;
  activo: boolean;
  fecha_creacion: string | null;
  fecha_actualizacion: string | null;
  stock_bajo: boolean;
  estado_vencimiento: string | null;
  dias_para_vencer: number | null;
}

export interface ProductoCreate {
  codigo: string;
  nombre: string;
  descripcion: string | null;
  id_categoria: number;
  unidad_medida: string;
  precio_unitario: number;
  stock_minimo: number;
  fecha_vencimiento: string | null;
  maneja_lotes: boolean;
}

export interface ProductoUpdate extends ProductoCreate {
  activo: boolean;
}

export interface ProductoFiltros {
  busqueda?: string;
  id_categoria?: number;
  solo_activos?: boolean;
}

export interface Lote {
  id_lote: number;
  id_producto: number;
  codigo_producto: string;
  nombre_producto: string;
  numero_lote: string;
  fecha_vencimiento: string | null;
  cantidad_inicial: number;
  stock_disponible: number;
  activo: boolean;
  fecha_registro: string | null;
  estado_vencimiento: string;
  dias_para_vencer: number | null;
}

export interface ProductoStockBajo {
  id_producto: number;
  codigo: string;
  nombre: string;
  id_categoria: number;
  nombre_categoria: string;
  unidad_medida: string;
  precio_unitario: string;
  stock_actual: number;
  stock_minimo: number;
  deficit_stock: number;
  fecha_vencimiento: string | null;
  activo: boolean;
}

export interface ProductoVencimiento {
  id_producto: number;
  codigo: string;
  nombre: string;
  id_categoria: number;
  nombre_categoria: string;
  unidad_medida: string;
  precio_unitario: string;
  stock_actual: number;
  id_lote: number | null;
  numero_lote: string | null;
  cantidad_afectada: number;
  fecha_vencimiento: string;
  dias_para_vencer: number;
  estado_vencimiento: string;
}
