import { DecimalPipe } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { IndicadoresResumen } from '../../interfaces/indicador.interface';
import { ProductoStockBajo, ProductoVencimiento } from '../../interfaces/producto.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { IndicadorService } from '../../services/indicador.service';
import { ProductoService } from '../../services/producto.service';

@Component({
  selector: 'app-dashboard',
  imports: [DecimalPipe],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css',
})
export class Dashboard implements OnInit {
  private readonly indicadorService = inject(IndicadorService);
  private readonly productoService = inject(ProductoService);

  readonly resumen = signal<IndicadoresResumen | null>(null);
  readonly stockBajo = signal<ProductoStockBajo[]>([]);
  readonly vencimientos = signal<ProductoVencimiento[]>([]);
  readonly cargando = signal(false);
  readonly error = signal('');

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    this.cargando.set(true);
    this.error.set('');

    forkJoin({
      resumen: this.indicadorService.resumen(),
      stockBajo: this.productoService.stockBajo(),
      vencimientos: this.productoService.vencimientos(30),
    })
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: ({ resumen, stockBajo, vencimientos }) => {
          this.resumen.set(resumen);
          this.stockBajo.set(stockBajo);
          this.vencimientos.set(vencimientos);
        },
        error: (error: unknown) => {
          this.error.set(getApiErrorMessage(error));
        },
      });
  }

  numero(valor: string | number): number {
    return Number(valor);
  }

  badgeVencimiento(estado: string): string {
    return estado === 'VENCIDO' ? 'text-bg-danger' : 'text-bg-warning';
  }
}
