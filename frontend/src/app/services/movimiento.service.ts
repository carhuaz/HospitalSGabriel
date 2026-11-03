import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { Movimiento, MovimientoFiltros } from '../interfaces/movimiento.interface';

@Injectable({ providedIn: 'root' })
export class MovimientoService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/movimientos`;

  listar(filtros: MovimientoFiltros = {}): Observable<Movimiento[]> {
    let params = new HttpParams();

    if (filtros.id_producto && filtros.id_producto > 0) {
      params = params.set('id_producto', filtros.id_producto);
    }
    if (filtros.tipo_movimiento) {
      params = params.set('tipo_movimiento', filtros.tipo_movimiento);
    }
    if (filtros.area_destino?.trim()) {
      params = params.set('area_destino', filtros.area_destino.trim());
    }
    if (filtros.fecha_inicio) {
      params = params.set('fecha_inicio', filtros.fecha_inicio);
    }
    if (filtros.fecha_fin) {
      params = params.set('fecha_fin', filtros.fecha_fin);
    }

    return this.http.get<Movimiento[]>(this.baseUrl, { params });
  }
}
