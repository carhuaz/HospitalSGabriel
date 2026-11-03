import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import {
  Lote,
  Producto,
  ProductoCreate,
  ProductoFiltros,
  ProductoStockBajo,
  ProductoUpdate,
  ProductoVencimiento,
} from '../interfaces/producto.interface';

@Injectable({ providedIn: 'root' })
export class ProductoService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/productos`;

  listar(filtros: ProductoFiltros = {}): Observable<Producto[]> {
    let params = new HttpParams();

    if (filtros.busqueda?.trim()) {
      params = params.set('busqueda', filtros.busqueda.trim());
    }
    if (filtros.id_categoria && filtros.id_categoria > 0) {
      params = params.set('id_categoria', filtros.id_categoria);
    }
    if (filtros.solo_activos !== undefined) {
      params = params.set('solo_activos', filtros.solo_activos);
    }

    return this.http.get<Producto[]>(this.baseUrl, { params });
  }

  obtener(idProducto: number): Observable<Producto> {
    return this.http.get<Producto>(`${this.baseUrl}/${idProducto}`);
  }

  listarLotes(idProducto: number, soloConStock = false): Observable<Lote[]> {
    return this.http.get<Lote[]>(`${this.baseUrl}/${idProducto}/lotes`, {
      params: { solo_con_stock: soloConStock },
    });
  }

  crear(datos: ProductoCreate): Observable<Producto> {
    return this.http.post<Producto>(this.baseUrl, datos);
  }

  actualizar(idProducto: number, datos: ProductoUpdate): Observable<Producto> {
    return this.http.put<Producto>(`${this.baseUrl}/${idProducto}`, datos);
  }

  desactivar(idProducto: number): Observable<Producto> {
    return this.http.patch<Producto>(`${this.baseUrl}/${idProducto}/desactivar`, {});
  }

  stockBajo(): Observable<ProductoStockBajo[]> {
    return this.http.get<ProductoStockBajo[]>(`${this.baseUrl}/stock-bajo`);
  }

  vencimientos(diasAlerta = 30, estado?: string): Observable<ProductoVencimiento[]> {
    let params = new HttpParams().set('dias_alerta', diasAlerta);
    if (estado) {
      params = params.set('estado', estado);
    }
    return this.http.get<ProductoVencimiento[]>(`${this.baseUrl}/vencimientos`, { params });
  }
}
