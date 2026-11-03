# AGENTS.md — Frontend (Hospital San Gabriel)

App Angular 22 standalone que consume la API FastAPI de `../backend/` (puerto 8000). No hay workspace raíz ni scripts unificados: ejecuta todo desde `frontend/`.

## Comandos

- `npm install`
- `npm start` → http://localhost:4200
- `npm run build` (también valida tipos y templates)
- `npm test` (Vitest + jsdom mediante `@angular/build:unit-test`; specs `*.spec.ts`)
- Formato: `npx prettier --write .` (no hay script npm; configuración en `.prettierrc`)

No hay lint, typecheck separado ni e2e configurados, y no hay CI. La verificación disponible es `npm run build` + `npm test`.

## Arquitectura obligatoria

```text
src/app/
├── components/
│   └── <feature>/
│       ├── <feature>.component.html
│       ├── <feature>.component.ts
│       └── <feature>.component.css
├── services/
│   └── <feature>.service.ts
└── interfaces/
    └── <entidad>.interface.ts

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

## Environments y HTTP

- Crear `src/environments/environment.ts` y `environment.development.ts` con `apiUrl: 'http://127.0.0.1:8000/api'`.
- Configurar `fileReplacements` en `angular.json` para que `npm start` use el environment de desarrollo.
- Registrar `provideHttpClient()` en `src/app/app.config.ts`.
- Importar siempre `environment.apiUrl`; no hardcodear URLs ni duplicar el puerto 8000 en los services.
- Los services solo deben llamar endpoints existentes del backend bajo `/api`; no inventar rutas.

## Bootstrap 5

- Bootstrap 5 se usa **solo por CDN** en `src/index.html`: CSS en `<head>` y bundle JS antes de `</body>`.
- No instalar `bootstrap` por npm ni agregarlo a `styles`/`scripts` de `angular.json`.
- Usar clases de Bootstrap 5 en las plantillas. Los estilos globales propios van en `src/styles.css`; el CSS de cada componente solo para ajustes específicos.

## Integración con el backend

- La API se sirve en `http://127.0.0.1:8000/api`; Swagger en `/docs`.
- El backend solo permite CORS desde `http://localhost:4200`.
- Para levantarlo: desde `../backend/`, `uv sync` y `uv run uvicorn main:app --reload`. Requiere SQL Server, `backend/.env` y los scripts de `backend/database/` aplicados; el detalle está en `../backend/AGENTS.md`.

## Estado actual

Solo existe el shell de la app: `app.routes.ts` vacío, sin rutas, servicios ni interfaces de feature. Al implementar la primera funcionalidad, sigue la estructura y el flujo descritos arriba.
