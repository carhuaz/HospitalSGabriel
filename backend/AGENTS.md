# AGENTS.md - Backend (Hospital San Gabriel)

## Estado Actual del Proyecto
El backend en la rama `feature/backend` se encuentra implementado, probado y conectado a SQL Server (`HospitalSanGabrielDB`) mediante procedimientos almacenados y arquitectura por capas.

## Tecnologías del Backend
- **Lenguaje:** Python 3.13+
- **Gestor de proyecto y paquetes:** `uv`
- **Framework Web:** FastAPI + Uvicorn
- **Base de Datos:** SQL Server (`pyodbc` + `python-dotenv`, acceso exclusivo mediante Procedimientos Almacenados, **sin ORM**)
- **Pruebas:** `pytest` + `httpx` (`TestClient`)
- **Entorno:** Windows (PowerShell)

## Arquitectura por Capas Implementada
El backend dentro de `backend/` sigue estrictamente el flujo:

`main.py → api/ → services/ → repositories/ → SQL Server (Stored Procedures)`

- `main.py`: Punto de entrada y configuración de FastAPI y CORS.
- `api/`: Rutas y endpoints (`auth.py`, `categorias.py`, `productos.py`, `entradas.py`, `salidas.py`, `movimientos.py`, `indicadores.py`). No contiene consultas SQL ni lógica de persistencia.
- `services/`: Reglas de negocio, validaciones y traducción de errores (`exceptions.py`).
- `repositories/`: Conexión a SQL Server (`database.py`) y ejecución exclusiva de procedimientos almacenados (`EXEC dbo.sp_...`).
- `schemas/`: Modelos Pydantic para validación de entrada y serialización de salida.
- `database/`:
  - `01_schema.sql`: Tablas (`Categorias`, `Productos`, `Lotes`, `Entradas`, `Salidas`, `MovimientosInventario`, `Usuarios`), claves, restricciones `CHECK`/`UNIQUE` e índices.
  - `02_stored_procedures.sql`: 20 procedimientos almacenados con transacciones explícitas para entradas y salidas.
  - `03_seed_data.sql`: Datos iniciales de prueba para el Hospital San Gabriel.

## Comandos Reales del Proyecto (Windows / UV)
Desde `backend/`:
- Sincronizar dependencias: `uv sync`
- Ejecutar servidor de desarrollo: `uv run uvicorn main:app --reload`
- Ejecutar suite de pruebas: `uv run pytest -v`

Desde la raíz del proyecto (para inicializar SQL Server):
- `sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\01_schema.sql"`
- `sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\02_stored_procedures.sql"`
- `sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i "backend\database\03_seed_data.sql"`

## Reglas de Negocio Verificadas
1. **Código único:** `UQ_Productos_Codigo` y validación en `sp_Productos_Registrar` / `sp_Productos_Actualizar`.
2. **Precios válidos:** `precio_unitario > 0` en Pydantic, servicio y `CK_Productos_Precio_Positivo`.
3. **Cantidades válidas:** Enteros positivos (`> 0`) en entradas y salidas.
4. **Stock no negativo:** Validación de stock disponible antes de retirar en `sp_Salidas_Registrar` y `CK_Productos_StockActual_NoNegativo`.
5. **Trazabilidad e historial:** Toda entrada o salida válida genera su registro en `MovimientosInventario` con `stock_anterior` y `stock_posterior`.
6. **Atomicidad:** Actualización de stock (producto y lote) y registro del movimiento dentro de `BEGIN TRANSACTION ... COMMIT TRANSACTION`.
7. **Baja lógica:** `sp_Productos_Desactivar` marca `activo = 0` conservando todo el historial de movimientos.
8. **Control de vencimiento:** `sp_Salidas_Registrar` impide retirar productos o lotes vencidos (`THROW 50009`).
9. **Control de lotes:** Tabla `Lotes` y selección FEFO o por lote específico en salidas.
10. **Área de destino:** Obligatoria en todas las salidas hospitalarias.
11. **Datos en tiempo real:** Los indicadores (`sp_Indicadores_Resumen`, `sp_Productos_StockBajo`, `sp_Productos_Vencimientos`, `sp_Indicadores_ProductosMayoresSalidas`) consultan el estado actual de SQL Server.

## Restricciones de Rama
- En `feature/backend` no se debe modificar ningún archivo dentro de `frontend/`.
- Nunca subir `.env` al repositorio (usar `.env.example`).
