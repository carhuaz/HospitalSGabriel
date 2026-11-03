import { DecimalPipe } from '@angular/common';
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

import { Categoria } from '../../interfaces/categoria.interface';
import {
  Lote,
  Producto,
  ProductoCreate,
  ProductoFiltros,
  ProductoUpdate,
} from '../../interfaces/producto.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { CategoriaService } from '../../services/categoria.service';
import { ProductoService } from '../../services/producto.service';

interface ProductoForm {
  codigo: string;
  nombre: string;
  descripcion: string;
  id_categoria: string;
  unidad_medida: string;
  precio_unitario: number;
  stock_minimo: number;
  fecha_vencimiento: string;
  maneja_lotes: boolean;
}

interface FiltrosProductoForm {
  busqueda: string;
  id_categoria: string;
  solo_activos: boolean;
}

@Component({
  selector: 'app-productos',
  imports: [DecimalPipe, FormField, FormRoot],
  templateUrl: './productos.component.html',
})
export class Productos implements OnInit {
  private readonly productoService = inject(ProductoService);
  private readonly categoriaService = inject(CategoriaService);

  readonly productos = signal<Producto[]>([]);
  readonly categorias = signal<Categoria[]>([]);
  readonly lotesProducto = signal<Lote[]>([]);
  readonly productoLotesNombre = signal('');
  readonly cargando = signal(false);
  readonly cargandoLotes = signal(false);
  readonly error = signal('');
  readonly mensaje = signal('');
  readonly editando = signal<Producto | null>(null);

  readonly filtrosModel = signal<FiltrosProductoForm>({
    busqueda: '',
    id_categoria: '0',
    solo_activos: true,
  });

  readonly filtrosForm = form(this.filtrosModel, {
    submission: {
      action: async () => {
        this.cargar();
      },
    },
  });

  readonly productoModel = signal<ProductoForm>({
    codigo: '',
    nombre: '',
    descripcion: '',
    id_categoria: '0',
    unidad_medida: '',
    precio_unitario: 0,
    stock_minimo: 0,
    fecha_vencimiento: '',
    maneja_lotes: true,
  });

  readonly productoForm = form(
    this.productoModel,
    (schema) => {
      required(schema.codigo);
      required(schema.nombre);
      minLength(schema.nombre, 2);
      required(schema.unidad_medida);
      validate(schema.id_categoria, ({ value }) =>
        Number(value()) > 0 ? undefined : { kind: 'categoria-requerida' },
      );
      min(schema.precio_unitario, 0.01);
      min(schema.stock_minimo, 0);
    },
    {
      submission: {
        action: async (field) => {
          this.error.set('');
          this.mensaje.set('');

          const valor = field().value();
          const productoActual = this.editando();

          const datos: ProductoCreate = {
            codigo: valor.codigo.trim(),
            nombre: valor.nombre.trim(),
            descripcion: valor.descripcion.trim() || null,
            id_categoria: Number(valor.id_categoria),
            unidad_medida: valor.unidad_medida.trim(),
            precio_unitario: Number(valor.precio_unitario),
            stock_minimo: Number(valor.stock_minimo),
            fecha_vencimiento: valor.fecha_vencimiento || null,
            maneja_lotes: valor.maneja_lotes,
          };

          try {
            if (productoActual) {
              const actualizacion: ProductoUpdate = {
                ...datos,
                activo: productoActual.activo,
              };
              await firstValueFrom(
                this.productoService.actualizar(productoActual.id_producto, actualizacion),
              );
              this.mensaje.set('Producto actualizado correctamente.');
            } else {
              await firstValueFrom(this.productoService.crear(datos));
              this.mensaje.set('Producto registrado correctamente.');
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
    this.cargarCategorias();
    this.cargar();
  }

  cargar(): void {
    this.cargando.set(true);
    this.error.set('');

    const filtros = this.filtrosModel();
    const datosFiltro: ProductoFiltros = {
      busqueda: filtros.busqueda.trim() || undefined,
      id_categoria: Number(filtros.id_categoria) || undefined,
      solo_activos: filtros.solo_activos,
    };

    this.productoService
      .listar(datosFiltro)
      .pipe(finalize(() => this.cargando.set(false)))
      .subscribe({
        next: (productos) => this.productos.set(productos),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  cargarCategorias(): void {
    this.categoriaService.listar(false).subscribe({
      next: (categorias) => this.categorias.set(categorias),
      error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
    });
  }

  editar(producto: Producto): void {
    this.editando.set(producto);
    this.mensaje.set('');
    this.error.set('');
    this.productoModel.set({
      codigo: producto.codigo,
      nombre: producto.nombre,
      descripcion: producto.descripcion ?? '',
      id_categoria: String(producto.id_categoria),
      unidad_medida: producto.unidad_medida,
      precio_unitario: Number(producto.precio_unitario),
      stock_minimo: producto.stock_minimo,
      fecha_vencimiento: producto.fecha_vencimiento ?? '',
      maneja_lotes: producto.maneja_lotes,
    });
  }

  cancelarEdicion(): void {
    this.editando.set(null);
    this.limpiarFormulario();
  }

  desactivar(producto: Producto): void {
    if (!confirm(`¿Desactivar el producto ${producto.codigo} - ${producto.nombre}?`)) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');

    this.productoService.desactivar(producto.id_producto).subscribe({
      next: () => {
        this.mensaje.set('Producto desactivado. Su historial se conserva.');
        this.cargar();
      },
      error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
    });
  }

  verLotes(producto: Producto): void {
    this.productoLotesNombre.set(`${producto.codigo} - ${producto.nombre}`);
    this.cargandoLotes.set(true);

    this.productoService
      .listarLotes(producto.id_producto, true)
      .pipe(finalize(() => this.cargandoLotes.set(false)))
      .subscribe({
        next: (lotes) => this.lotesProducto.set(lotes),
        error: (error: unknown) => this.error.set(getApiErrorMessage(error)),
      });
  }

  cerrarLotes(): void {
    this.productoLotesNombre.set('');
    this.lotesProducto.set([]);
  }

  numero(valor: string | number): number {
    return Number(valor);
  }

  fechaCorta(fecha: string | null): string {
    return fecha ? fecha.slice(0, 10) : '—';
  }

  badgeStock(producto: Producto): string {
    return producto.stock_bajo ? 'text-bg-warning' : 'text-bg-success';
  }

  private limpiarFormulario(): void {
    this.productoModel.set({
      codigo: '',
      nombre: '',
      descripcion: '',
      id_categoria: '0',
      unidad_medida: '',
      precio_unitario: 0,
      stock_minimo: 0,
      fecha_vencimiento: '',
      maneja_lotes: true,
    });
  }
}
