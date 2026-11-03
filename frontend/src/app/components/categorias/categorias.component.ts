import { Component, OnInit, inject, signal } from '@angular/core';
import { FormField, FormRoot, form, minLength, required } from '@angular/forms/signals';
import { firstValueFrom } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { Categoria, CategoriaCreate, CategoriaUpdate } from '../../interfaces/categoria.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { CategoriaService } from '../../services/categoria.service';

interface CategoriaForm {
  nombre: string;
  descripcion: string;
}

@Component({
  selector: 'app-categorias',
  imports: [FormField, FormRoot],
  templateUrl: './categorias.component.html',
  styleUrl: './categorias.component.css',
})
export class Categorias implements OnInit {
  private readonly categoriaService = inject(CategoriaService);

  readonly categorias = signal<Categoria[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');
  readonly mensaje = signal('');
  readonly editando = signal<Categoria | null>(null);

  readonly categoriaModel = signal<CategoriaForm>({
    nombre: '',
    descripcion: '',
  });

  readonly categoriaForm = form(
    this.categoriaModel,
    (schema) => {
      required(schema.nombre);
      minLength(schema.nombre, 2);
    },
    {
      submission: {
        action: async (field) => {
          this.error.set('');
          this.mensaje.set('');

          const valor = field().value();
          const categoriaActual = this.editando();

          const datos: CategoriaCreate = {
            nombre: valor.nombre.trim(),
            descripcion: valor.descripcion.trim() || null,
          };

          try {
            if (categoriaActual) {
              const actualizacion: CategoriaUpdate = {
                ...datos,
                activo: categoriaActual.activo,
              };
              await firstValueFrom(
                this.categoriaService.actualizar(categoriaActual.id_categoria, actualizacion),
              );
              this.mensaje.set('Categoría actualizada correctamente.');
            } else {
              await firstValueFrom(this.categoriaService.crear(datos));
              this.mensaje.set('Categoría registrada correctamente.');
            }

            this.editando.set(null);
            this.limpiarFormulario();
            this.cargar();
          } catch (error) {
            this.error.set(getApiErrorMessage(error));
          }
        },
      },
    },
  );

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    this.cargando.set(true);
    this.categoriaService
      .listar(false)
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: (categorias) => this.categorias.set(categorias),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  editar(categoria: Categoria): void {
    this.editando.set(categoria);
    this.mensaje.set('');
    this.error.set('');
    this.categoriaModel.set({
      nombre: categoria.nombre,
      descripcion: categoria.descripcion ?? '',
    });
  }

  cancelarEdicion(): void {
    this.editando.set(null);
    this.limpiarFormulario();
  }

  fechaCorta(fecha: string | null): string {
    return fecha ? fecha.slice(0, 10) : '—';
  }

  private limpiarFormulario(): void {
    this.categoriaModel.set({ nombre: '', descripcion: '' });
  }
}
