# AGENTS.md - Backend (Hospital San Gabriel)

## Estado Actual del Proyecto
El repositorio se encuentra en su etapa inicial. Todavía **no** se ha inicializado el proyecto con `uv`, ni se han creado los endpoints de FastAPI, la base de datos en SQL Server ni el frontend en Angular.

## Tecnologías del Backend
- **Lenguaje:** Python 3.13+
- **Gestor de proyecto y paquetes:** `uv`
- **Framework Web:** FastAPI + Uvicorn
- **Base de Datos:** SQL Server (acceso exclusivo mediante Procedimientos Almacenados, **sin ORM**)
- **Entorno:** Windows (PowerShell)

## Arquitectura por Capas Requerida
El backend dentro de `backend/` debe seguir estrictamente esta estructura y flujo de dependencias:

`main.py → api/ → services/ → repositories/ → SQL Server (Stored Procedures)`

- `main.py`: Punto de entrada y configuración de la aplicación FastAPI (CORS, routers, manejo de errores).
- `api/`: Definición de rutas y endpoints HTTP. **Prohibido** incluir consultas SQL o lógica de negocio aquí.
- `services/`: Lógica de aplicación y validación de reglas de negocio.
- `repositories/`: Conexión a SQL Server y ejecución exclusiva de procedimientos almacenados (`EXEC ...`).
- `schemas/`: Modelos Pydantic para validación de datos de entrada y estructuración de salida.
- `database/` (o scripts SQL): Scripts de creación de tablas, restricciones, índices y procedimientos almacenados.

## Comandos del Proyecto (Windows / UV)
Una vez inicializado el entorno en `backend/`:
- Inicializar proyecto: `uv init`
- Agregar dependencias: `uv add fastapi uvicorn pyodbc python-dotenv pydantic`
- Ejecutar servidor de desarrollo: `uv run uvicorn main:app --reload`

## Reglas de Negocio Obligatorias
1. **Código único:** Cada producto tiene un código único.
2. **Precios válidos:** El precio unitario debe ser estrictamente mayor que cero (`> 0`).
3. **Cantidades válidas:** Las cantidades en entradas y salidas deben ser enteros positivos (`> 0`).
4. **Stock no negativo:** Ninguna salida puede dejar el stock en negativo ni superar el stock disponible.
5. **Trazabilidad e historial:** Toda entrada o salida válida debe generar un registro histórico de movimiento indicando stock anterior y stock posterior.
6. **Atomicidad:** La actualización de stock y el registro del movimiento deben ejecutarse dentro de una **misma transacción** en el procedimiento almacenado.
7. **Baja lógica:** Los productos con movimientos registrados **no** se eliminan físicamente; solo se desactivan.
8. **Control de vencimiento:** Los productos vencidos no pueden registrarse en salidas para uso hospitalario.
9. **Control de lotes:** Conservar trazabilidad de lote y fecha de vencimiento en entradas, salidas y movimientos cuando corresponda.
10. **Área de destino:** Toda salida debe registrar obligatoriamente el área hospitalaria de destino (Emergencia, Hospitalización, Consultorios Externos, Laboratorio, etc.).
11. **Datos en tiempo real:** Los indicadores y consultas deben reflejar siempre los datos actuales de SQL Server.

## Restricciones de Desarrollo y Flujo Git
- **No hacer commits automáticos:** El usuario gestiona todos los commits y ramas desde GitHub Desktop.
- **No crear ni fusionar Pull Requests** sin autorización explícita.
- **Aislamiento de ramas:**
  - En `main`: Solo la estructura básica inicial de `backend` y `frontend`.
  - En `feature/backend`: Todo el desarrollo del backend y base de datos. **No modificar la carpeta `frontend/`** mientras se trabaje en `feature/backend`.
- **Seguridad:** Nunca exponer credenciales en el código fuente. Usar `.env` (ignorado en Git) y proveer `.env.example`.
- **Trabajo incremental:** Avanzar etapa por etapa y detenerse para revisión del usuario antes de pasar a la siguiente.
