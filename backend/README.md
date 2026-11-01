# Backend - Sistema de Inventario Hospitalario (Hospital San Gabriel)

API REST desarrollada con **Python 3.13**, **UV**, **FastAPI**, **Uvicorn** y **SQL Server** empleando **arquitectura por capas** y **procedimientos almacenados** (sin ORM).

## Estructura de Capas

```text
backend/
├── main.py                      # Punto de entrada FastAPI y configuración CORS
├── api/                         # Capa de rutas y endpoints HTTP
│   ├── router.py
│   ├── auth.py
│   ├── categorias.py
│   ├── productos.py
│   ├── entradas.py
│   ├── salidas.py
│   ├── movimientos.py
│   └── indicadores.py
├── services/                    # Capa de lógica de aplicación y reglas de negocio
│   ├── exceptions.py
│   ├── auth_service.py
│   ├── categoria_service.py
│   ├── producto_service.py
│   ├── entrada_service.py
│   ├── salida_service.py
│   ├── movimiento_service.py
│   └── indicador_service.py
├── repositories/                # Capa de persistencia exclusiva mediante Stored Procedures
│   ├── database.py
│   ├── auth_repository.py
│   ├── categoria_repository.py
│   ├── producto_repository.py
│   ├── entrada_repository.py
│   ├── salida_repository.py
│   ├── movimiento_repository.py
│   └── indicador_repository.py
├── schemas/                     # Validaciones y esquemas Pydantic de entrada y salida
│   ├── auth_schema.py
│   ├── categoria_schema.py
│   ├── producto_schema.py
│   ├── entrada_schema.py
│   ├── salida_schema.py
│   ├── movimiento_schema.py
│   └── indicador_schema.py
├── database/                    # Scripts SQL Server
│   ├── 01_schema.sql
│   ├── 02_stored_procedures.sql
│   └── 03_seed_data.sql
└── tests/                       # Pruebas integrales de endpoints y reglas de negocio
    └── test_inventario_api.py
```

## Ejecución Rápida

```powershell
uv sync
uv run uvicorn main:app --reload
```

## Pruebas

```powershell
uv run pytest -v
```
