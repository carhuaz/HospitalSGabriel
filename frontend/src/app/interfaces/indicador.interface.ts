export interface IndicadoresResumen {
  total_productos_activos: number;
  total_categorias_activas: number;
  total_productos_stock_bajo: number;
  total_productos_vencidos: number;
  total_productos_proximos_vencer: number;
  valor_referencial_inventario: string;
  total_movimientos_hoy: number;
}

export interface ProductoMayorSalida {
  id_producto: number;
  codigo: string;
  nombre: string;
  nombre_categoria: string;
  unidad_medida: string;
  precio_unitario: string;
  stock_actual: number;
  total_unidades_salidas: number;
  numero_salidas: number;
  valor_estimado_salidas: string;
}
