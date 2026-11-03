# AGENTS.md — Frontend (Hospital San Gabriel)

App Angular 22 standalone que consume la API FastAPI de `../backend/` (puerto 8000). No hay workspace raíz ni scripts unificados: ejecuta todo desde `frontend/`.

## Comandos

- `npm install`
- `npm start` → http://localhost:4200
- `npm run build` (también valida tipos y templates)
- `npm test` (Vitest + jsdom mediante `@angular/build:unit-test`; specs `*.spec.ts`)
- Formato: `npx prettier --write .` (no hay script npm; configuración en `.prettierrc`)

No hay lint, typecheck separado ni e2e configurados, y no hay CI. La verificación disponible es `npm run build` + `npm test`.

El CLI de Angular 22 exige Node `^22.22.3 || ^24.15.0 || >=26.0.0`. Si el Node local es anterior, los comandos `ng` fallan al arrancar (no por el código); en ese caso usa el workaround:

```powershell
npx -y node@22.22.3 node_modules/@angular/cli/bin/ng.js build
```

## Arquitectura obligatoria

```text
src/app/
├── components/
│   ├── layout/       layout.component.{ts,html}
│   ├── login/        login.component.{ts,html}
│   ├── dashboard/    dashboard.component.{ts,html}
│   ├── categorias/   categorias.component.{ts,html}
│   ├── productos/    productos.component.{ts,html}
│   ├── entradas/     entradas.component.{ts,html}
│   ├── salidas/      salidas.component.{ts,html}
│   ├── movimientos/  movimientos.component.{ts,html}
│   └── indicadores/  indicadores.component.{ts,html}
├── services/
│   ├── auth.service.ts
│   ├── categoria.service.ts
│   ├── producto.service.ts
│   ├── entrada.service.ts
│   ├── salida.service.ts
│   ├── movimiento.service.ts
│   ├── indicador.service.ts
│   └── api-error.ts
├── interfaces/
│   ├── auth.interface.ts
│   ├── categoria.interface.ts
│   ├── producto.interface.ts
│   ├── entrada.interface.ts
│   ├── salida.interface.ts
│   ├── movimiento.interface.ts
│   └── indicador.interface.ts
├── guards/
│   └── auth.guard.ts
├── app.config.ts
├── app.routes.ts
├── app.ts / app.html
└── app.spec.ts

src/environments/
├── environment.ts
└── environment.development.ts
```

Flujo de datos obligatorio:

```text
componente.html → componente.ts → service → API backend
```

- **HTML:** solo presentación y eventos. No contiene lógica de negocio ni llamadas HTTP.
- **Componente TS:** maneja el estado de la vista (preferir `signal()`), atiende eventos y delega en servicios. Nunca usa `HttpClient` directamente.
- **Services:** única capa que consume endpoints con `HttpClient`. Se declaran `providedIn: 'root'`, usan `environment.apiUrl` y devuelven `Observable<T>` tipados. Un service por dominio: `auth`, `categorias`, `productos`, `entradas`, `salidas`, `movimientos`, `indicadores`.
- **Interfaces:** viven en `src/app/interfaces/`. Tipan requests, responses y estado; no usar `any`. Reutiliza las interfaces entre services y componentes.
- Todos los componentes son standalone (sin NgModules) y usan `templateUrl`/`styleUrl` separados, como el componente `App` existente.

## Formularios (Signal Forms)

- Se usa la API experimental `@angular/forms/signals`: `form()`, `FormField` (`[formField]`) y `FormRoot` (`[formRoot]`).
- El modelo vive en un `signal<T>` y se pasa como primer argumento a `form()`; el envío se declara en `submission.action`.
- Validadores disponibles: `required`, `minLength`, `maxLength`, `min`, `max`, `pattern`, `validate`.
- `min`/`max` solo aplican a campos `number`. Para `<select>` usa el valor como `string` en el modelo y valida con `validate(schema.campo, ({ value }) => ...)`, convirtiendo con `Number()` al construir el payload.
- No agregues atributos HTML `min`/`max` en inputs con `[formField]`: el validador pertenece al esquema, no al template.

## Environments y HTTP

- `src/environments/environment.ts` y `environment.development.ts` ya existen con `apiUrl: 'http://127.0.0.1:8000/api'`.
- `angular.json` tiene `fileReplacements` en la configuración `development`, de modo que `npm start` usa `environment.development.ts`.
- `provideHttpClient()` está registrado en `src/app/app.config.ts`.
- Importa siempre `environment.apiUrl`; no hardcodees URLs ni dupliques el puerto 8000 en los services.
- Los services solo deben llamar endpoints existentes del backend bajo `/api`; no inventes rutas.

## Bootstrap 5

- Bootstrap 5 se usa **solo por CDN** en `src/index.html`: CSS en `<head>` y bundle JS antes de `</body>`.
- No instalar `bootstrap` por npm ni agregarlo a `styles`/`scripts` de `angular.json`.
- Usar clases de Bootstrap 5 en las plantillas. Los estilos globales propios van en `src/styles.css`; el CSS de cada componente solo para ajustes específicos.

## Integración con el backend

- La API se sirve en `http://127.0.0.1:8000/api`; Swagger en `/docs`.
- El backend solo permite CORS desde `http://localhost:4200`.
- Para levantarlo: desde `../backend/`, `uv sync` y `uv run uvicorn main:app --reload`. Requiere SQL Server, `backend/.env` y los scripts de `backend/database/` aplicados; el detalle está en `../backend/AGENTS.md`.

## Estado actual

Estructura completa, funcional y con estilos:

- Rutas lazy con `authGuard`: `/login`, `/dashboard`, `/categorias`, `/productos`, `/entradas`, `/salidas`, `/movimientos`, `/indicadores`.
- `AuthService` guarda el usuario en `localStorage` bajo la clave `hospital-sg-usuario` (el backend no emite token).
- Todos los componentes son standalone, con `.ts` + `.html` + `.css` y `styleUrl` declarado (incluido `App`).
- `src/styles.css` concentra los tokens de marca (`--hsg-*`), los overrides de Bootstrap 5.3 y los patrones compartidos: `.page-header`, `.stat-card`, `.list-card`, `.sticky-card`, `.filters-card`, tablas, botones, formularios y alertas.
- Cada `.component.css` solo contiene ajustes propios de su pantalla (densidad de tablas, columnas que no deben partirse, alturas de scroll interno).
- `npm run build` y `npm test` pasan.

## Convenciones del backend reflejadas en el frontend

- Los decimales del backend llegan como **string** (`"25.50"`); en las interfaces se tipan como `string` y se convierten con `Number()` solo para mostrar/calcular.
- `POST /api/auth/login` devuelve el objeto `Usuario`, no un JWT.
- No inventes rutas: los endpoints usados son los de `../backend/AGENTS.md`.
