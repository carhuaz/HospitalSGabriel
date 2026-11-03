import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';

import { environment } from '../../environments/environment';
import { LoginRequest, Usuario } from '../interfaces/auth.interface';

const STORAGE_KEY = 'hospital-sg-usuario';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly usuarioSignal = signal<Usuario | null>(this.leerUsuarioGuardado());

  readonly usuario = this.usuarioSignal.asReadonly();
  readonly estaAutenticado = computed(() => this.usuarioSignal() !== null);

  login(credenciales: LoginRequest): Observable<Usuario> {
    return this.http.post<Usuario>(`${environment.apiUrl}/auth/login`, credenciales).pipe(
      tap((usuario) => {
        this.usuarioSignal.set(usuario);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(usuario));
      }),
    );
  }

  logout(): void {
    this.usuarioSignal.set(null);
    localStorage.removeItem(STORAGE_KEY);
  }

  tieneRol(...roles: string[]): boolean {
    const usuario = this.usuarioSignal();
    return usuario !== null && roles.includes(usuario.rol);
  }

  private leerUsuarioGuardado(): Usuario | null {
    try {
      const valor = localStorage.getItem(STORAGE_KEY);
      return valor ? (JSON.parse(valor) as Usuario) : null;
    } catch {
      return null;
    }
  }
}
