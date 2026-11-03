import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { Salida, SalidaCreate, SalidaFiltros } from '../interfaces/salida.interface';

@Injectable({ providedIn: 'root' })
export class SalidaService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/salidas`;

  listar(filtros: SalidaFiltros = {}): Observable<Salida[]> {
    let params = new HttpParams();

    if (filtros.id_producto && filtros.id_producto > 0) {
      params = params.set('id_producto', filtros.id_producto);
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

    return this.http.get<Salida[]>(this.baseUrl, { params });
  }

  registrar(datos: SalidaCreate): Observable<Salida> {
    return this.http.post<Salida>(this.baseUrl, datos);
  }
}
