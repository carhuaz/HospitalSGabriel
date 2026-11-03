import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { Categoria, CategoriaCreate, CategoriaUpdate } from '../interfaces/categoria.interface';

@Injectable({ providedIn: 'root' })
export class CategoriaService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/categorias`;

  listar(soloActivas = true): Observable<Categoria[]> {
    return this.http.get<Categoria[]>(this.baseUrl, {
      params: { solo_activas: soloActivas },
    });
  }

  obtener(idCategoria: number): Observable<Categoria> {
    return this.http.get<Categoria>(`${this.baseUrl}/${idCategoria}`);
  }

  crear(datos: CategoriaCreate): Observable<Categoria> {
    return this.http.post<Categoria>(this.baseUrl, datos);
  }

  actualizar(idCategoria: number, datos: CategoriaUpdate): Observable<Categoria> {
    return this.http.put<Categoria>(`${this.baseUrl}/${idCategoria}`, datos);
  }
}
