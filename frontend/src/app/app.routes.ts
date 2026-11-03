import { Routes } from '@angular/router';

import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./components/login/login.component').then((m) => m.Login),
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./components/layout/layout.component').then((m) => m.Layout),
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./components/dashboard/dashboard.component').then((m) => m.Dashboard),
      },
      {
        path: 'categorias',
        loadComponent: () =>
          import('./components/categorias/categorias.component').then((m) => m.Categorias),
      },
      {
        path: 'productos',
        loadComponent: () =>
          import('./components/productos/productos.component').then((m) => m.Productos),
      },
      {
        path: 'entradas',
        loadComponent: () =>
          import('./components/entradas/entradas.component').then((m) => m.Entradas),
      },
      {
        path: 'salidas',
        loadComponent: () =>
          import('./components/salidas/salidas.component').then((m) => m.Salidas),
      },
      {
        path: 'movimientos',
        loadComponent: () =>
          import('./components/movimientos/movimientos.component').then((m) => m.Movimientos),
      },
      {
        path: 'indicadores',
        loadComponent: () =>
          import('./components/indicadores/indicadores.component').then((m) => m.Indicadores),
      },
    ],
  },
  { path: '**', redirectTo: 'login' },
];
