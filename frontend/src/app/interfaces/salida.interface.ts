export interface SalidaCreate {
  id_producto: number;
  cantidad: number;
  motivo: string;
  area_destino: string;
  id_lote?: number | null;
  numero_lote: string | null;
  fecha?: string | null;
}

export interface Salida {
  id_salida: number;
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
  area_destino: string;
  stock_anterior: number | null;
  stock_posterior: number | null;
}

export interface SalidaFiltros {
  id_producto?: number;
  area_destino?: string;
  fecha_inicio?: string;
  fecha_fin?: string;
}
