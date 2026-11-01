/* ============================================================================
   SISTEMA DE INVENTARIO HOSPITALARIO - HOSPITAL SAN GABRIEL
   Script 01: Creación de Base de Datos, Tablas, Restricciones e Índices
   Motor: Microsoft SQL Server
   ============================================================================ */

IF DB_ID(N'HospitalSanGabrielDB') IS NULL
BEGIN
    CREATE DATABASE HospitalSanGabrielDB;
END
GO

USE HospitalSanGabrielDB;
GO

-- ============================================================================
-- 1. TABLA: Categorias (RF02)
-- ============================================================================
IF OBJECT_ID(N'dbo.Categorias', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categorias (
        id_categoria INT IDENTITY(1,1) NOT NULL,
        nombre NVARCHAR(100) NOT NULL,
        descripcion NVARCHAR(255) NULL,
        activo BIT NOT NULL CONSTRAINT DF_Categorias_Activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Categorias_FechaCreacion DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_Categorias PRIMARY KEY CLUSTERED (id_categoria),
        CONSTRAINT UQ_Categorias_Nombre UNIQUE (nombre),
        CONSTRAINT CK_Categorias_Nombre_NoVacio CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
    );
END
GO

-- ============================================================================
-- 2. TABLA: Productos (RF01, Reglas 1, 2, 4, 7)
-- ============================================================================
IF OBJECT_ID(N'dbo.Productos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Productos (
        id_producto INT IDENTITY(1,1) NOT NULL,
        codigo NVARCHAR(50) NOT NULL,
        nombre NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(500) NULL,
        id_categoria INT NOT NULL,
        unidad_medida NVARCHAR(50) NOT NULL,
        precio_unitario DECIMAL(12,2) NOT NULL,
        stock_actual INT NOT NULL CONSTRAINT DF_Productos_StockActual DEFAULT (0),
        stock_minimo INT NOT NULL CONSTRAINT DF_Productos_StockMinimo DEFAULT (0),
        fecha_vencimiento DATE NULL,
        maneja_lotes BIT NOT NULL CONSTRAINT DF_Productos_ManejaLotes DEFAULT (1),
        activo BIT NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Productos_FechaCreacion DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT PK_Productos PRIMARY KEY CLUSTERED (id_producto),
        CONSTRAINT UQ_Productos_Codigo UNIQUE (codigo),
        CONSTRAINT FK_Productos_Categorias FOREIGN KEY (id_categoria)
            REFERENCES dbo.Categorias (id_categoria),
        CONSTRAINT CK_Productos_Codigo_NoVacio CHECK (LEN(LTRIM(RTRIM(codigo))) > 0),
        CONSTRAINT CK_Productos_Nombre_NoVacio CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
        CONSTRAINT CK_Productos_Precio_Positivo CHECK (precio_unitario > 0),
        CONSTRAINT CK_Productos_StockActual_NoNegativo CHECK (stock_actual >= 0),
        CONSTRAINT CK_Productos_StockMinimo_NoNegativo CHECK (stock_minimo >= 0)
    );

    CREATE NONCLUSTERED INDEX IX_Productos_Categoria ON dbo.Productos (id_categoria);
    CREATE NONCLUSTERED INDEX IX_Productos_Nombre ON dbo.Productos (nombre);
    CREATE NONCLUSTERED INDEX IX_Productos_FechaVencimiento ON dbo.Productos (fecha_vencimiento);
    CREATE NONCLUSTERED INDEX IX_Productos_Activo_Stock ON dbo.Productos (activo, stock_actual, stock_minimo);
END
GO

-- ============================================================================
-- 3. TABLA: Lotes (RF03, RF04, RF05, Reglas 9, 10)
-- ============================================================================
IF OBJECT_ID(N'dbo.Lotes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Lotes (
        id_lote INT IDENTITY(1,1) NOT NULL,
        id_producto INT NOT NULL,
        numero_lote NVARCHAR(60) NOT NULL,
        fecha_vencimiento DATE NULL,
        cantidad_inicial INT NOT NULL,
        stock_disponible INT NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_Lotes_Activo DEFAULT (1),
        fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_Lotes_FechaRegistro DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_Lotes PRIMARY KEY CLUSTERED (id_lote),
        CONSTRAINT UQ_Lotes_Producto_Numero UNIQUE (id_producto, numero_lote),
        CONSTRAINT FK_Lotes_Productos FOREIGN KEY (id_producto)
            REFERENCES dbo.Productos (id_producto),
        CONSTRAINT CK_Lotes_CantidadInicial_Positiva CHECK (cantidad_inicial > 0),
        CONSTRAINT CK_Lotes_StockDisponible_NoNegativo CHECK (stock_disponible >= 0)
    );

    CREATE NONCLUSTERED INDEX IX_Lotes_Producto_Vencimiento
        ON dbo.Lotes (id_producto, fecha_vencimiento, stock_disponible);
END
GO

-- ============================================================================
-- 4. TABLA: Entradas (RF03, Reglas 3, 5, 6, 10)
-- ============================================================================
IF OBJECT_ID(N'dbo.Entradas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Entradas (
        id_entrada INT IDENTITY(1,1) NOT NULL,
        id_producto INT NOT NULL,
        id_lote INT NULL,
        cantidad INT NOT NULL,
        fecha DATETIME2 NOT NULL CONSTRAINT DF_Entradas_Fecha DEFAULT (SYSDATETIME()),
        motivo NVARCHAR(150) NOT NULL,
        numero_lote NVARCHAR(60) NULL,
        fecha_vencimiento DATE NULL,
        CONSTRAINT PK_Entradas PRIMARY KEY CLUSTERED (id_entrada),
        CONSTRAINT FK_Entradas_Productos FOREIGN KEY (id_producto)
            REFERENCES dbo.Productos (id_producto),
        CONSTRAINT FK_Entradas_Lotes FOREIGN KEY (id_lote)
            REFERENCES dbo.Lotes (id_lote),
        CONSTRAINT CK_Entradas_Cantidad_Positiva CHECK (cantidad > 0),
        CONSTRAINT CK_Entradas_Motivo_NoVacio CHECK (LEN(LTRIM(RTRIM(motivo))) > 0)
    );

    CREATE NONCLUSTERED INDEX IX_Entradas_Producto_Fecha ON dbo.Entradas (id_producto, fecha DESC);
END
GO

-- ============================================================================
-- 5. TABLA: Salidas (RF04, Reglas 3, 4, 5, 6, 9, 10, 11)
-- ============================================================================
IF OBJECT_ID(N'dbo.Salidas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Salidas (
        id_salida INT IDENTITY(1,1) NOT NULL,
        id_producto INT NOT NULL,
        id_lote INT NULL,
        cantidad INT NOT NULL,
        fecha DATETIME2 NOT NULL CONSTRAINT DF_Salidas_Fecha DEFAULT (SYSDATETIME()),
        motivo NVARCHAR(150) NOT NULL,
        area_destino NVARCHAR(100) NOT NULL,
        numero_lote NVARCHAR(60) NULL,
        CONSTRAINT PK_Salidas PRIMARY KEY CLUSTERED (id_salida),
        CONSTRAINT FK_Salidas_Productos FOREIGN KEY (id_producto)
            REFERENCES dbo.Productos (id_producto),
        CONSTRAINT FK_Salidas_Lotes FOREIGN KEY (id_lote)
            REFERENCES dbo.Lotes (id_lote),
        CONSTRAINT CK_Salidas_Cantidad_Positiva CHECK (cantidad > 0),
        CONSTRAINT CK_Salidas_Motivo_NoVacio CHECK (LEN(LTRIM(RTRIM(motivo))) > 0),
        CONSTRAINT CK_Salidas_AreaDestino_NoVacia CHECK (LEN(LTRIM(RTRIM(area_destino))) > 0)
    );

    CREATE NONCLUSTERED INDEX IX_Salidas_Producto_Fecha ON dbo.Salidas (id_producto, fecha DESC);
    CREATE NONCLUSTERED INDEX IX_Salidas_AreaDestino ON dbo.Salidas (area_destino);
END
GO

-- ============================================================================
-- 6. TABLA: MovimientosInventario (RF05, Reglas 5, 6, 10, 11)
-- ============================================================================
IF OBJECT_ID(N'dbo.MovimientosInventario', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MovimientosInventario (
        id_movimiento INT IDENTITY(1,1) NOT NULL,
        id_producto INT NOT NULL,
        id_lote INT NULL,
        id_entrada INT NULL,
        id_salida INT NULL,
        tipo_movimiento NVARCHAR(20) NOT NULL,
        cantidad INT NOT NULL,
        fecha DATETIME2 NOT NULL CONSTRAINT DF_Movimientos_Fecha DEFAULT (SYSDATETIME()),
        motivo NVARCHAR(150) NOT NULL,
        area_destino NVARCHAR(100) NULL,
        numero_lote NVARCHAR(60) NULL,
        fecha_vencimiento_lote DATE NULL,
        stock_anterior INT NOT NULL,
        stock_posterior INT NOT NULL,
        CONSTRAINT PK_MovimientosInventario PRIMARY KEY CLUSTERED (id_movimiento),
        CONSTRAINT FK_Movimientos_Productos FOREIGN KEY (id_producto)
            REFERENCES dbo.Productos (id_producto),
        CONSTRAINT FK_Movimientos_Lotes FOREIGN KEY (id_lote)
            REFERENCES dbo.Lotes (id_lote),
        CONSTRAINT FK_Movimientos_Entradas FOREIGN KEY (id_entrada)
            REFERENCES dbo.Entradas (id_entrada),
        CONSTRAINT FK_Movimientos_Salidas FOREIGN KEY (id_salida)
            REFERENCES dbo.Salidas (id_salida),
        CONSTRAINT CK_Movimientos_Tipo CHECK (tipo_movimiento IN (N'ENTRADA', N'SALIDA')),
        CONSTRAINT CK_Movimientos_Cantidad_Positiva CHECK (cantidad > 0),
        CONSTRAINT CK_Movimientos_StockAnterior_NoNegativo CHECK (stock_anterior >= 0),
        CONSTRAINT CK_Movimientos_StockPosterior_NoNegativo CHECK (stock_posterior >= 0)
    );

    CREATE NONCLUSTERED INDEX IX_Movimientos_Filtros
        ON dbo.MovimientosInventario (id_producto, tipo_movimiento, area_destino, fecha DESC);
    CREATE NONCLUSTERED INDEX IX_Movimientos_Fecha
        ON dbo.MovimientosInventario (fecha DESC);
END
GO

-- ============================================================================
-- 7. TABLA: Usuarios (Soporte para inicio de sesión del sistema)
-- ============================================================================
IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Usuarios (
        id_usuario INT IDENTITY(1,1) NOT NULL,
        username NVARCHAR(50) NOT NULL,
        password_hash NVARCHAR(255) NOT NULL,
        nombre_completo NVARCHAR(120) NOT NULL,
        rol NVARCHAR(50) NOT NULL CONSTRAINT DF_Usuarios_Rol DEFAULT (N'Administrador'),
        activo BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
        CONSTRAINT PK_Usuarios PRIMARY KEY CLUSTERED (id_usuario),
        CONSTRAINT UQ_Usuarios_Username UNIQUE (username)
    );
END
GO

-- ============================================================================
-- DATOS INICIALES BASE (Categorías Hospitalarias y Usuario por defecto)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Categorias)
BEGIN
    INSERT INTO dbo.Categorias (nombre, descripcion) VALUES
    (N'Medicamentos', N'Fármacos, antibióticos, analgésicos y soluciones parenterales'),
    (N'Material Médico', N'Jeringas, gasas, guantes quirúrgicos, catéteres y suturas'),
    (N'Material de Laboratorio', N'Reactivos, tubos de ensayo, placas y consumibles de diagnóstico'),
    (N'Productos de Limpieza Hospitalaria', N'Desinfectantes de alto nivel, antisépticos y esterilizantes');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE username = N'admin')
BEGIN
    INSERT INTO dbo.Usuarios (username, password_hash, nombre_completo, rol)
    VALUES (N'admin', N'admin123', N'Administrador Hospital San Gabriel', N'Administrador');
END
GO
