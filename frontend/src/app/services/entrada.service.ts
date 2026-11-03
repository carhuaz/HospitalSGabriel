import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { Entrada, EntradaCreate, EntradaFiltros } from '../interfaces/entrada.interface';

@Injectable({ providedIn: 'root' })
export class EntradaService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/entradas`;

  listar(filtros: EntradaFiltros = {}): Observable<Entrada[]> {
    let params = new HttpParams();

    if (filtros.id_producto && filtros.id_producto > 0) {
      params = params.set('id_producto', filtros.id_producto);
    }
    if (filtros.fecha_inicio) {
      params = params.set('fecha_inicio', filtros.fecha_inicio);
    }
    if (filtros.fecha_fin) {
      params = params.set('fecha_fin', filtros.fecha_fin);
    }

    return this.http.get<Entrada[]>(this.baseUrl, { params });
  }

  registrar(datos: EntradaCreate): Observable<Entrada> {
    return this.http.post<Entrada>(this.baseUrl, datos);
  }
}
