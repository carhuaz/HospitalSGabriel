import { DecimalPipe } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormField, FormRoot, form, max, min } from '@angular/forms/signals';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { IndicadoresResumen, ProductoMayorSalida } from '../../interfaces/indicador.interface';
import { ProductoStockBajo, ProductoVencimiento } from '../../interfaces/producto.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { IndicadorService } from '../../services/indicador.service';

interface VencimientosForm {
  dias_alerta: number;
  estado: string;
}

interface MayoresSalidasForm {
  fecha_inicio: string;
  fecha_fin: string;
  top: number;
}

@Component({
  selector: 'app-indicadores',
  imports: [DecimalPipe, FormField, FormRoot],
  templateUrl: './indicadores.component.html',
})
export class Indicadores implements OnInit {
  private readonly indicadorService = inject(IndicadorService);

  readonly resumen = signal<IndicadoresResumen | null>(null);
  readonly stockBajo = signal<ProductoStockBajo[]>([]);
  readonly vencimientos = signal<ProductoVencimiento[]>([]);
  readonly mayoresSalidas = signal<ProductoMayorSalida[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');

  readonly vencimientosModel = signal<VencimientosForm>({
    dias_alerta: 30,
    estado: '',
  });

  readonly vencimientosForm = form(
    this.vencimientosModel,
    (schema) => {
      min(schema.dias_alerta, 0);
    },
    {
      submission: {
        action: async () => {
          this.cargarVencimientos();
        },
      },
    },
  );

  readonly mayoresModel = signal<MayoresSalidasForm>({
    fecha_inicio: '',
    fecha_fin: '',
    top: 10,
  });

  readonly mayoresForm = form(
    this.mayoresModel,
    (schema) => {
      min(schema.top, 1);
      max(schema.top, 100);
    },
    {
      submission: {
        action: async () => {
          this.cargarMayoresSalidas();
        },
      },
    },
  );

  ngOnInit(): void {
    this.cargarTodo();
  }

  cargarTodo(): void {
    this.cargando.set(true);
    this.error.set('');

    forkJoin({
      resumen: this.indicadorService.resumen(),
      stockBajo: this.indicadorService.stockBajo(),
      vencimientos: this.indicadorService.vencimientos(),
      mayoresSalidas: this.indicadorService.mayoresSalidas(),
    })
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: ({ resumen, stockBajo, vencimientos, mayoresSalidas }) => {
          this.resumen.set(resumen);
          this.stockBajo.set(stockBajo);
          this.vencimientos.set(vencimientos);
          this.mayoresSalidas.set(mayoresSalidas);
        },
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  cargarVencimientos(): void {
    const filtros = this.vencimientosModel();
    this.error.set('');

    this.indicadorService
      .vencimientos(Number(filtros.dias_alerta), filtros.estado || undefined)
      .subscribe({
        next: (vencimientos) => this.vencimientos.set(vencimientos),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  cargarMayoresSalidas(): void {
    const filtros = this.mayoresModel();
    this.error.set('');

    this.indicadorService
      .mayoresSalidas(
        filtros.fecha_inicio || undefined,
        filtros.fecha_fin || undefined,
        Number(filtros.top),
      )
      .subscribe({
        next: (mayoresSalidas) => this.mayoresSalidas.set(mayoresSalidas),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  numero(valor: string | number): number {
    return Number(valor);
  }

  badgeVencimiento(estado: string): string {
    return estado === 'VENCIDO' ? 'text-bg-danger' : 'text-bg-warning';
  }
}
