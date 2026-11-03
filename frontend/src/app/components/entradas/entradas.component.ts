import { Component, OnInit, inject, signal } from '@angular/core';
import {
  FormField,
  FormRoot,
  form,
  min,
  minLength,
  required,
  validate,
} from '@angular/forms/signals';
import { firstValueFrom } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { Entrada, EntradaCreate, EntradaFiltros } from '../../interfaces/entrada.interface';
import { Producto } from '../../interfaces/producto.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { EntradaService } from '../../services/entrada.service';
import { ProductoService } from '../../services/producto.service';

interface EntradaForm {
  id_producto: string;
  cantidad: number;
  motivo: string;
  numero_lote: string;
  fecha_vencimiento: string;
}

interface FiltrosEntradaForm {
  id_producto: string;
  fecha_inicio: string;
  fecha_fin: string;
}

@Component({
  selector: 'app-entradas',
  imports: [FormField, FormRoot],
  templateUrl: './entradas.component.html',
})
export class Entradas implements OnInit {
  private readonly entradaService = inject(EntradaService);
  private readonly productoService = inject(ProductoService);

  readonly entradas = signal<Entrada[]>([]);
  readonly productos = signal<Producto[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');
  readonly mensaje = signal('');

  readonly filtrosModel = signal<FiltrosEntradaForm>({
    id_producto: '0',
    fecha_inicio: '',
    fecha_fin: '',
  });

  readonly filtrosForm = form(this.filtrosModel, {
    submission: {
      action: async () => {
        this.cargar();
      },
    },
  });

  readonly entradaModel = signal<EntradaForm>({
    id_producto: '0',
    cantidad: 0,
    motivo: '',
    numero_lote: '',
    fecha_vencimiento: '',
  });

  readonly entradaForm = form(
    this.entradaModel,
    (schema) => {
      validate(schema.id_producto, ({ value }) =>
        Number(value()) > 0 ? undefined : { kind: 'producto-requerido' },
      );
      min(schema.cantidad, 1);
      required(schema.motivo);
      minLength(schema.motivo, 2);
    },
    {
      submission: {
        action: async (field) => {
          this.error.set('');
          this.mensaje.set('');

          const valor = field().value();
          const datos: EntradaCreate = {
            id_producto: Number(valor.id_producto),
            cantidad: Number(valor.cantidad),
            motivo: valor.motivo.trim(),
            numero_lote: valor.numero_lote.trim() || null,
            fecha_vencimiento: valor.fecha_vencimiento || null,
          };

          try {
            await firstValueFrom(this.entradaService.registrar(datos));
            this.mensaje.set('Entrada registrada correctamente.');
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
    this.cargarProductos();
    this.cargar();
  }

  cargar(): void {
    this.cargando.set(true);
    this.error.set('');

    const filtros = this.filtrosModel();
    const datosFiltro: EntradaFiltros = {
      id_producto: Number(filtros.id_producto) || undefined,
      fecha_inicio: filtros.fecha_inicio || undefined,
      fecha_fin: filtros.fecha_fin || undefined,
    };

    this.entradaService
      .listar(datosFiltro)
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: (entradas) => this.entradas.set(entradas),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  cargarProductos(): void {
    this.productoService.listar({ solo_activos: true }).subscribe({
      next: (productos) => this.productos.set(productos),
      error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
    });
  }

  fechaHora(valor: string): string {
    return valor.replace('T', ' ').slice(0, 16);
  }

  fechaCorta(fecha: string | null): string {
    return fecha ? fecha.slice(0, 10) : '—';
  }

  private limpiarFormulario(): void {
    this.entradaModel.set({
      id_producto: '0',
      cantidad: 0,
      motivo: '',
      numero_lote: '',
      fecha_vencimiento: '',
    });
  }
}
