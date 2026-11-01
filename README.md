# Sistema de Inventario Hospitalario – Hospital San Gabriel

Aplicación web para centralizar y administrar el inventario de medicamentos, insumos médicos y materiales hospitalarios del **Hospital San Gabriel**, desarrollada con **FastAPI**, **SQL Server (Procedimientos Almacenados)** y **Angular**.

---

## Arquitectura del Proyecto

- `backend/`: API REST en Python gestionada con `uv`, implementada bajo arquitectura por capas (`main.py → api → services → repositories → SQL Server`) y persistencia exclusiva mediante procedimientos almacenados.
- `frontend/`: Estructura base en Angular para la interfaz de usuario.

---

## Requisitos Previos

- **Python** 3.13+ y **UV** (`uv`)
- **Microsoft SQL Server** (Express o Developer) y `ODBC Driver 17 for SQL Server` (o Driver 18)
- **Node.js** 20+ y **Angular CLI** (para el frontend)

---

## Instalación y Ejecución del Backend (`feature/backend`)

### 1. Inicializar la Base de Datos en SQL Server

Desde la raíz del proyecto en PowerShell (reemplazando `localhost\SQLEXPRESS` si utilizas otra instancia):

```powershell
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\01_schema.sql"
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\02_stored_procedures.sql"
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\03_seed_data.sql"
```

### 2. Configurar Variables de Entorno

Dentro de la carpeta `backend/`, copia `.env.example` a `.env` y ajusta los parámetros de tu instancia local:

```powershell
cd backend
Copy-Item .env.example .env
```

Contenido de referencia de `.env`:

```env
DB_DRIVER=ODBC Driver 17 for SQL Server
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HospitalSanGabrielDB
DB_TRUSTED_CONNECTION=yes
DB_USER=
DB_PASSWORD=
DB_TRUST_SERVER_CERTIFICATE=yes
```

### 3. Instalar Dependencias y Ejecutar el Servidor FastAPI

```powershell
cd backend
uv sync
uv run uvicorn main:app --reload
```

- **Servidor API:** http://127.0.0.1:8000
- **Documentación interactiva (Swagger UI):** http://127.0.0.1:8000/docs
- **Estado del servicio y base de datos:** http://127.0.0.1:8000/api/health

### 4. Ejecutar Pruebas Automatizadas

```powershell
cd backend
uv run pytest -v
```

---

## Endpoints Principales del Backend

| Módulo | Método y Ruta | Descripción |
|---|---|---|
| **Autenticación** | `POST /api/auth/login` | Inicio de sesión de usuarios |
| **Categorías** | `GET /api/categorias` | Listar categorías disponibles |
| | `POST /api/categorias` | Registrar nueva categoría |
| | `PUT /api/categorias/{id}` | Actualizar categoría |
| **Productos** | `GET /api/productos` | Listar, buscar por código/nombre y filtrar por categoría |
| | `GET /api/productos/{id}` | Consultar detalle de producto |
| | `GET /api/productos/{id}/lotes` | Consultar lotes y trazabilidad del producto |
| | `POST /api/productos` | Registrar producto hospitalario |
| | `PUT /api/productos/{id}` | Actualizar producto hospitalario |
| | `PATCH /api/productos/{id}/desactivar` | Desactivar producto conservando su historial |
| **Entradas** | `GET /api/entradas` | Consultar entradas registradas |
| | `POST /api/entradas` | Registrar entrada (compra, donación, devolución) con lote y transacción |
| **Salidas** | `GET /api/salidas` | Consultar salidas registradas |
| | `POST /api/salidas` | Registrar salida hacia área hospitalaria con validación de stock y vencimiento |
| **Movimientos** | `GET /api/movimientos` | Historial filtrable por producto, tipo, área y rango de fechas |
| **Indicadores** | `GET /api/indicadores/resumen` | Resumen de activos, stock bajo, vencidos, próximos a vencer y valor referencial |
| | `GET /api/indicadores/stock-bajo` | Productos con stock igual o inferior al stock mínimo |
| | `GET /api/indicadores/vencimientos` | Productos y lotes próximos a vencer y vencidos |
| | `GET /api/indicadores/mayores-salidas` | Productos con mayores salidas en un periodo |

---

## Usuarios por Defecto y Roles del Sistema (`dbo.Usuarios`)

| Usuario (`username`) | Contraseña (`password`) | Rol (`rol`) | Responsabilidad en el Sistema |
|---|---|---|---|
| `admin` | `admin123` | `Administrador` | Gestión total (categorías, productos, entradas, salidas, bajas lógicas, historial e indicadores). |
| `farmacia` | `farmacia123` | `Farmacia` | Dispensación hospitalaria: consulta de catálogo/lotes, alertas de vencimientos y registro de **Salidas** hacia áreas del hospital. |
| `almacen` | `almacen123` | `Almacén` | Abastecimiento: gestión de productos/categorías y registro de **Entradas** por compras, donaciones o devoluciones. |
