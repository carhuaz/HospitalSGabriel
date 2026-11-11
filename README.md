# Sistema de Inventario Hospitalario – Hospital San Gabriel

Aplicación web para centralizar y administrar el inventario de medicamentos, insumos médicos y materiales hospitalarios del **Hospital San Gabriel**. Reemplaza el control manual en hojas de cálculo por un sistema que mantiene el stock actualizado, registra entradas y salidas, conserva el historial de movimientos y alerta sobre productos con stock bajo o próximos a vencer.

**Tecnologías:** Angular 22 con Signal Forms · FastAPI (Python) · SQL Server con procedimientos almacenados.

---

## Funcionalidades

- **Categorías y productos:** registro, edición, búsqueda por código o nombre y filtro por categoría. Los productos se **desactivan** (nunca se eliminan) para conservar su historial.
- **Entradas:** ingreso por compras, donaciones o devoluciones, con número de lote y fecha de vencimiento. Actualiza el stock automáticamente.
- **Salidas:** despacho hacia un área hospitalaria. Impide retirar más que el stock disponible y bloquea productos o lotes vencidos.
- **Movimientos:** historial filtrable por producto, tipo, área y rango de fechas, con stock anterior y posterior.
- **Indicadores:** productos activos, stock bajo, próximos a vencer, vencidos, valor referencial del inventario y productos con mayores salidas.
- **Inicio de sesión y roles:** Administrador (acceso total), Farmacia (consulta y salidas) y Almacén (productos, categorías y entradas).

---

## Arquitectura del Proyecto

```
HospitalSGabriel/
├── backend/     API REST (FastAPI) + scripts SQL
└── frontend/    Interfaz web (Angular 22)
```

**Backend** – arquitectura por capas:
`main.py → api (endpoints) → services (reglas y errores) → repositories (ejecutan los SP) → SQL Server`
Los esquemas de validación (Pydantic) están en `schemas/`. Toda la persistencia se realiza mediante **procedimientos almacenados**.

**Frontend** – organizado en:

- `components/`: una carpeta por pantalla (login, layout, dashboard, categorías, productos, entradas, salidas, movimientos, indicadores).
- `services/`: comunicación HTTP con la API.
- `interfaces/`: tipos de datos.
- `guards/`: `authGuard`, que protege las rutas para que solo accedan usuarios con sesión.
- `app.routes.ts`: mapa de rutas con carga diferida (_lazy loading_).

---

## Requisitos Previos

- **Python** 3.13+ y **uv**
- **Microsoft SQL Server** (Express o Developer) y **ODBC Driver 17** (o 18) para SQL Server
- **Node.js** 22.22+ (o 24.15+) y npm. Angular CLI se ejecuta con `npx`, no requiere instalación global.

---

## Instalación y Ejecución

### 1. Base de datos

Desde la raíz del proyecto, en PowerShell (ajusta `localhost\SQLEXPRESS` si usas otra instancia):

```powershell
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\01_schema.sql"
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\02_stored_procedures.sql"
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\03_seed_data.sql"
```

### 2. Backend (FastAPI)

Copia el archivo de variables de entorno y ajústalo a tu instancia (las credenciales **no** se suben al repositorio):

```powershell
cd backend
Copy-Item .env.example .env
```

```env
DB_DRIVER=ODBC Driver 17 for SQL Server
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HospitalSanGabrielDB
DB_TRUSTED_CONNECTION=yes
DB_USER=
DB_PASSWORD=
DB_TRUST_SERVER_CERTIFICATE=yes
```

Instala las dependencias y levanta el servidor:

```powershell
uv sync
uv run uvicorn main:app --reload
```

- API: http://127.0.0.1:8000
- Documentación interactiva (Swagger): http://127.0.0.1:8000/docs
- Estado del servicio y de la base de datos: http://127.0.0.1:8000/api/health

### 3. Frontend (Angular)

En otra terminal, con el backend ya en ejecución:

```powershell
cd frontend
npm install
npm start
```

Abre **http://localhost:4200** en el navegador. La URL de la API se configura en `frontend/src/environments/environment.development.ts` (por defecto `http://127.0.0.1:8000/api`).

Para generar la versión de producción: `npm run build`.

### 4. Pruebas automatizadas del backend

Requieren SQL Server en ejecución y la base de datos creada:

```powershell
cd backend
uv run pytest -v
```

---

## Usuarios por Defecto y Roles

| Usuario    | Contraseña    | Rol           | Acceso                                                                            |
| ---------- | ------------- | ------------- | --------------------------------------------------------------------------------- |
| `admin`    | `admin123`    | Administrador | Gestión total: categorías, productos, entradas, salidas, historial e indicadores. |
| `farmacia` | `farmacia123` | Farmacia      | Consulta de productos, lotes y vencimientos; registro de **salidas**.             |
| `almacen`  | `almacen123`  | Almacén       | Gestión de productos y categorías; registro de **entradas**.                      |

> Credenciales de demostración para entorno de desarrollo.

---

## Reglas de Negocio Principales

- El código de cada producto es único y el precio debe ser mayor que cero.
- Las cantidades de entrada y salida son enteros mayores que cero.
- No se permiten salidas que dejen el stock en negativo.
- No se permiten salidas de productos o lotes vencidos.
- Cada entrada o salida genera un registro histórico, y la actualización del stock se hace en la **misma transacción** que el registro del movimiento.
- Los productos con movimientos no se eliminan: se desactivan.
- Toda salida debe indicar el área hospitalaria de destino.
- En productos con lotes, las salidas descuentan primero el lote que vence antes (FEFO).

---

## Endpoints Principales del Backend

| Módulo            | Método y Ruta                          | Descripción                                            |
| ----------------- | -------------------------------------- | ------------------------------------------------------ |
| **Autenticación** | `POST /api/auth/login`                 | Inicio de sesión                                       |
| **Categorías**    | `GET /api/categorias`                  | Listar categorías                                      |
|                   | `POST /api/categorias`                 | Registrar categoría                                    |
|                   | `PUT /api/categorias/{id}`             | Actualizar categoría                                   |
| **Productos**     | `GET /api/productos`                   | Listar, buscar y filtrar por categoría                 |
|                   | `GET /api/productos/{id}`              | Detalle de producto                                    |
|                   | `GET /api/productos/{id}/lotes`        | Lotes y trazabilidad                                   |
|                   | `POST /api/productos`                  | Registrar producto                                     |
|                   | `PUT /api/productos/{id}`              | Actualizar producto                                    |
|                   | `PATCH /api/productos/{id}/desactivar` | Desactivar conservando el historial                    |
| **Entradas**      | `GET /api/entradas`                    | Consultar entradas                                     |
|                   | `POST /api/entradas`                   | Registrar entrada con lote y transacción               |
| **Salidas**       | `GET /api/salidas`                     | Consultar salidas                                      |
|                   | `POST /api/salidas`                    | Registrar salida con validación de stock y vencimiento |
| **Movimientos**   | `GET /api/movimientos`                 | Historial filtrable por producto, tipo, área y fechas  |
| **Indicadores**   | `GET /api/indicadores/resumen`         | Resumen general del inventario                         |
|                   | `GET /api/indicadores/stock-bajo`      | Productos con stock igual o inferior al mínimo         |
|                   | `GET /api/indicadores/vencimientos`    | Próximos a vencer y vencidos                           |
|                   | `GET /api/indicadores/mayores-salidas` | Productos con mayores salidas en un periodo            |

---

## Flujo de Trabajo con Git

El desarrollo se gestiona con ramas por funcionalidad y Pull Requests hacia `main`:

- `feature/backend`: API, base de datos y procedimientos almacenados.
- `frontend`: interfaz en Angular.
- Los cambios se integran a `main` mediante Pull Requests.
