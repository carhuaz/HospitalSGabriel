export interface EntradaCreate {
  id_producto: number;
  cantidad: number;
  motivo: string;
  numero_lote: string | null;
  fecha_vencimiento: string | null;
  fecha?: string | null;
}

export interface Entrada {
  id_entrada: number;
  id_movimiento: number | null;
  id_producto: number;
  codigo_producto: string;
  nombre_producto: string;
  id_lote: number | null;
  numero_lote: string | null;
  fecha_vencimiento: string | null;
  cantidad: number;
  fecha: string;
  motivo: string;
  stock_anterior: number | null;
  stock_posterior: number | null;
}

export interface EntradaFiltros {
  id_producto?: number;
  fecha_inicio?: string;
  fecha_fin?: string;
}
