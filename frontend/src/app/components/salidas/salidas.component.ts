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

import { Producto } from '../../interfaces/producto.interface';
import { Salida, SalidaCreate, SalidaFiltros } from '../../interfaces/salida.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { ProductoService } from '../../services/producto.service';
import { SalidaService } from '../../services/salida.service';

interface SalidaForm {
  id_producto: string;
  cantidad: number;
  motivo: string;
  area_destino: string;
  numero_lote: string;
}

interface FiltrosSalidaForm {
  id_producto: string;
  area_destino: string;
  fecha_inicio: string;
  fecha_fin: string;
}

@Component({
  selector: 'app-salidas',
  imports: [FormField, FormRoot],
  templateUrl: './salidas.component.html',
})
export class Salidas implements OnInit {
  private readonly salidaService = inject(SalidaService);
  private readonly productoService = inject(ProductoService);

  readonly salidas = signal<Salida[]>([]);
  readonly productos = signal<Producto[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');
  readonly mensaje = signal('');

  readonly filtrosModel = signal<FiltrosSalidaForm>({
    id_producto: '0',
    area_destino: '',
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

  readonly salidaModel = signal<SalidaForm>({
    id_producto: '0',
    cantidad: 0,
    motivo: '',
    area_destino: '',
    numero_lote: '',
  });

  readonly salidaForm = form(
    this.salidaModel,
    (schema) => {
      validate(schema.id_producto, ({ value }) =>
        Number(value()) > 0 ? undefined : { kind: 'producto-requerido' },
      );
      min(schema.cantidad, 1);
      required(schema.motivo);
      minLength(schema.motivo, 2);
      required(schema.area_destino);
      minLength(schema.area_destino, 2);
    },
    {
      submission: {
        action: async (field) => {
          this.error.set('');
          this.mensaje.set('');

          const valor = field().value();
          const datos: SalidaCreate = {
            id_producto: Number(valor.id_producto),
            cantidad: Number(valor.cantidad),
            motivo: valor.motivo.trim(),
            area_destino: valor.area_destino.trim(),
            numero_lote: valor.numero_lote.trim() || null,
          };

          try {
            await firstValueFrom(this.salidaService.registrar(datos));
            this.mensaje.set('Salida registrada correctamente.');
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
    const datosFiltro: SalidaFiltros = {
      id_producto: Number(filtros.id_producto) || undefined,
      area_destino: filtros.area_destino.trim() || undefined,
      fecha_inicio: filtros.fecha_inicio || undefined,
      fecha_fin: filtros.fecha_fin || undefined,
    };

    this.salidaService
      .listar(datosFiltro)
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: (salidas) => this.salidas.set(salidas),
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
    this.salidaModel.set({
      id_producto: '0',
      cantidad: 0,
      motivo: '',
      area_destino: '',
      numero_lote: '',
    });
  }
}
