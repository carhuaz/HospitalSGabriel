import { Component, OnInit, inject, signal } from '@angular/core';
import { FormField, FormRoot, form } from '@angular/forms/signals';
import { finalize } from 'rxjs/operators';

import { Movimiento, MovimientoFiltros } from '../../interfaces/movimiento.interface';
import { Producto } from '../../interfaces/producto.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { MovimientoService } from '../../services/movimiento.service';
import { ProductoService } from '../../services/producto.service';

interface FiltrosMovimientoForm {
  id_producto: string;
  tipo_movimiento: string;
  area_destino: string;
  fecha_inicio: string;
  fecha_fin: string;
}

@Component({
  selector: 'app-movimientos',
  imports: [FormField, FormRoot],
  templateUrl: './movimientos.component.html',
  styleUrl: './movimientos.component.css',
})
export class Movimientos implements OnInit {
  private readonly movimientoService = inject(MovimientoService);
  private readonly productoService = inject(ProductoService);

  readonly movimientos = signal<Movimiento[]>([]);
  readonly productos = signal<Producto[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');

  readonly filtrosModel = signal<FiltrosMovimientoForm>({
    id_producto: '0',
    tipo_movimiento: '',
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

  ngOnInit(): void {
    this.cargarProductos();
    this.cargar();
  }

  cargar(): void {
    this.cargando.set(true);
    this.error.set('');

    const filtros = this.filtrosModel();
    const datosFiltro: MovimientoFiltros = {
      id_producto: Number(filtros.id_producto) || undefined,
      tipo_movimiento: filtros.tipo_movimiento || undefined,
      area_destino: filtros.area_destino.trim() || undefined,
      fecha_inicio: filtros.fecha_inicio || undefined,
      fecha_fin: filtros.fecha_fin || undefined,
    };

    this.movimientoService
      .listar(datosFiltro)
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: (movimientos) => this.movimientos.set(movimientos),
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

  badgeTipo(tipo: string): string {
    return tipo === 'ENTRADA' ? 'text-bg-success' : 'text-bg-primary';
  }
}
