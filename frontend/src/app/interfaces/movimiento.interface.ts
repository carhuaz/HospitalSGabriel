export interface Movimiento {
  id_movimiento: number;
  id_producto: number;
  codigo_producto: string;
  nombre_producto: string;
  nombre_categoria: string;
  tipo_movimiento: string;
  cantidad: number;
  fecha: string;
  motivo: string;
  area_destino: string | null;
  id_lote: number | null;
  numero_lote: string | null;
  fecha_vencimiento_lote: string | null;
  stock_anterior: number;
  stock_posterior: number;
}

export interface MovimientoFiltros {
  id_producto?: number;
  tipo_movimiento?: string;
  area_destino?: string;
  fecha_inicio?: string;
  fecha_fin?: string;
}
