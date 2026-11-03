import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { IndicadoresResumen, ProductoMayorSalida } from '../interfaces/indicador.interface';
import { ProductoStockBajo, ProductoVencimiento } from '../interfaces/producto.interface';

@Injectable({ providedIn: 'root' })
export class IndicadorService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/indicadores`;

  resumen(diasAlerta = 30): Observable<IndicadoresResumen> {
    return this.http.get<IndicadoresResumen>(`${this.baseUrl}/resumen`, {
      params: { dias_alerta: diasAlerta },
    });
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

  mayoresSalidas(
    fechaInicio?: string,
    fechaFin?: string,
    top = 10,
  ): Observable<ProductoMayorSalida[]> {
    let params = new HttpParams().set('top', top);

    if (fechaInicio) {
      params = params.set('fecha_inicio', fechaInicio);
    }
    if (fechaFin) {
      params = params.set('fecha_fin', fechaFin);
    }

    return this.http.get<ProductoMayorSalida[]>(`${this.baseUrl}/mayores-salidas`, {
      params,
    });
  }
}
