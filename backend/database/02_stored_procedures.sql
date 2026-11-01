/* ============================================================================
   SISTEMA DE INVENTARIO HOSPITALARIO - HOSPITAL SAN GABRIEL
   Script 02: Procedimientos Almacenados (Categorías, Productos, Lotes,
              Entradas, Salidas, Movimientos, Consultas e Indicadores)
   Motor: Microsoft SQL Server
   ============================================================================ */

USE HospitalSanGabrielDB;
GO

-- ============================================================================
-- 1. CATEGORÍAS (RF02)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Categorias_Listar
    @solo_activas BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id_categoria,
        c.nombre,
        c.descripcion,
        c.activo,
        c.fecha_creacion,
        COUNT(p.id_producto) AS total_productos
    FROM dbo.Categorias c
    LEFT JOIN dbo.Productos p
        ON p.id_categoria = c.id_categoria AND p.activo = 1
    WHERE (@solo_activas = 0 OR c.activo = 1)
    GROUP BY
        c.id_categoria,
        c.nombre,
        c.descripcion,
        c.activo,
        c.fecha_creacion
    ORDER BY c.nombre ASC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categorias_ObtenerPorId
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id_categoria,
        c.nombre,
        c.descripcion,
        c.activo,
        c.fecha_creacion
    FROM dbo.Categorias c
    WHERE c.id_categoria = @id_categoria;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categorias_Registrar
    @nombre NVARCHAR(100),
    @descripcion NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF @nombre IS NULL OR LEN(@nombre) = 0
        THROW 50001, 'El nombre de la categoría es obligatorio.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Categorias WHERE UPPER(nombre) = UPPER(@nombre))
        THROW 50002, 'Ya existe una categoría registrada con ese nombre.', 1;

    INSERT INTO dbo.Categorias (nombre, descripcion)
    VALUES (@nombre, @descripcion);

    DECLARE @nuevo_id INT = SCOPE_IDENTITY();

    SELECT
        id_categoria,
        nombre,
        descripcion,
        activo,
        fecha_creacion
    FROM dbo.Categorias
    WHERE id_categoria = @nuevo_id;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categorias_Actualizar
    @id_categoria INT,
    @nombre NVARCHAR(100),
    @descripcion NVARCHAR(255) = NULL,
    @activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SET @nombre = LTRIM(RTRIM(@nombre));

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id_categoria = @id_categoria)
        THROW 50003, 'La categoría indicada no existe.', 1;

    IF @nombre IS NULL OR LEN(@nombre) = 0
        THROW 50001, 'El nombre de la categoría es obligatorio.', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.Categorias
        WHERE UPPER(nombre) = UPPER(@nombre)
          AND id_categoria <> @id_categoria
    )
        THROW 50002, 'Ya existe otra categoría con ese nombre.', 1;

    UPDATE dbo.Categorias
    SET
        nombre = @nombre,
        descripcion = @descripcion,
        activo = @activo
    WHERE id_categoria = @id_categoria;

    SELECT
        id_categoria,
        nombre,
        descripcion,
        activo,
        fecha_creacion
    FROM dbo.Categorias
    WHERE id_categoria = @id_categoria;
END
GO

-- ============================================================================
-- 2. PRODUCTOS Y LOTES (RF01, Reglas 1, 2, 7, 9, 10)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Productos_Registrar
    @codigo NVARCHAR(50),
    @nombre NVARCHAR(150),
    @descripcion NVARCHAR(500) = NULL,
    @id_categoria INT,
    @unidad_medida NVARCHAR(50),
    @precio_unitario DECIMAL(12,2),
    @stock_minimo INT = 0,
    @fecha_vencimiento DATE = NULL,
    @maneja_lotes BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SET @codigo = LTRIM(RTRIM(@codigo));
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @unidad_medida = LTRIM(RTRIM(@unidad_medida));

    IF @codigo IS NULL OR LEN(@codigo) = 0
        THROW 50010, 'El código del producto es obligatorio.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Productos WHERE UPPER(codigo) = UPPER(@codigo))
        THROW 50011, 'El código del producto ya se encuentra registrado. Debe ser único.', 1;

    IF @nombre IS NULL OR LEN(@nombre) = 0
        THROW 50012, 'El nombre del producto es obligatorio.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id_categoria = @id_categoria AND activo = 1)
        THROW 50013, 'La categoría seleccionada no existe o está inactiva.', 1;

    IF @precio_unitario IS NULL OR @precio_unitario <= 0
        THROW 50014, 'El precio unitario debe ser mayor que cero.', 1;

    IF @stock_minimo IS NULL OR @stock_minimo < 0
        THROW 50015, 'El stock mínimo no puede ser negativo.', 1;

    INSERT INTO dbo.Productos (
        codigo,
        nombre,
        descripcion,
        id_categoria,
        unidad_medida,
        precio_unitario,
        stock_actual,
        stock_minimo,
        fecha_vencimiento,
        maneja_lotes,
        activo
    )
    VALUES (
        @codigo,
        @nombre,
        @descripcion,
        @id_categoria,
        @unidad_medida,
        @precio_unitario,
        0,
        @stock_minimo,
        @fecha_vencimiento,
        @maneja_lotes,
        1
    );

    DECLARE @nuevo_id INT = SCOPE_IDENTITY();

    EXEC dbo.sp_Productos_ObtenerPorId @id_producto = @nuevo_id;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Productos_ObtenerPorId
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);

    SELECT
        p.id_producto,
        p.codigo,
        p.nombre,
        p.descripcion,
        p.id_categoria,
        c.nombre AS nombre_categoria,
        p.unidad_medida,
        p.precio_unitario,
        p.stock_actual,
        p.stock_minimo,
        p.fecha_vencimiento,
        p.maneja_lotes,
        p.activo,
        p.fecha_creacion,
        p.fecha_actualizacion,
        CAST(CASE WHEN p.stock_actual <= p.stock_minimo THEN 1 ELSE 0 END AS BIT) AS stock_bajo,
        CASE
            WHEN p.fecha_vencimiento IS NULL THEN N'SIN_VENCIMIENTO'
            WHEN p.fecha_vencimiento < @hoy THEN N'VENCIDO'
            WHEN p.fecha_vencimiento <= DATEADD(DAY, 30, @hoy) THEN N'PROXIMO_A_VENCER'
            ELSE N'VIGENTE'
        END AS estado_vencimiento,
        CASE
            WHEN p.fecha_vencimiento IS NULL THEN NULL
            ELSE DATEDIFF(DAY, @hoy, p.fecha_vencimiento)
        END AS dias_para_vencer
    FROM dbo.Productos p
    INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
    WHERE p.id_producto = @id_producto;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Productos_Listar
    @busqueda NVARCHAR(150) = NULL,
    @id_categoria INT = NULL,
    @solo_activos BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);
    SET @busqueda = NULLIF(LTRIM(RTRIM(@busqueda)), N'');

    SELECT
        p.id_producto,
        p.codigo,
        p.nombre,
        p.descripcion,
        p.id_categoria,
        c.nombre AS nombre_categoria,
        p.unidad_medida,
        p.precio_unitario,
        p.stock_actual,
        p.stock_minimo,
        p.fecha_vencimiento,
        p.maneja_lotes,
        p.activo,
        p.fecha_creacion,
        p.fecha_actualizacion,
        CAST(CASE WHEN p.stock_actual <= p.stock_minimo THEN 1 ELSE 0 END AS BIT) AS stock_bajo,
        CASE
            WHEN p.fecha_vencimiento IS NULL THEN N'SIN_VENCIMIENTO'
            WHEN p.fecha_vencimiento < @hoy THEN N'VENCIDO'
            WHEN p.fecha_vencimiento <= DATEADD(DAY, 30, @hoy) THEN N'PROXIMO_A_VENCER'
            ELSE N'VIGENTE'
        END AS estado_vencimiento,
        CASE
            WHEN p.fecha_vencimiento IS NULL THEN NULL
            ELSE DATEDIFF(DAY, @hoy, p.fecha_vencimiento)
        END AS dias_para_vencer
    FROM dbo.Productos p
    INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
    WHERE (@busqueda IS NULL OR p.codigo LIKE N'%' + @busqueda + N'%' OR p.nombre LIKE N'%' + @busqueda + N'%')
      AND (@id_categoria IS NULL OR p.id_categoria = @id_categoria)
      AND (@solo_activos IS NULL OR p.activo = @solo_activos)
    ORDER BY p.nombre ASC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Productos_Actualizar
    @id_producto INT,
    @codigo NVARCHAR(50),
    @nombre NVARCHAR(150),
    @descripcion NVARCHAR(500) = NULL,
    @id_categoria INT,
    @unidad_medida NVARCHAR(50),
    @precio_unitario DECIMAL(12,2),
    @stock_minimo INT,
    @fecha_vencimiento DATE = NULL,
    @maneja_lotes BIT = 1,
    @activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SET @codigo = LTRIM(RTRIM(@codigo));
    SET @nombre = LTRIM(RTRIM(@nombre));
    SET @unidad_medida = LTRIM(RTRIM(@unidad_medida));

    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE id_producto = @id_producto)
        THROW 50016, 'El producto indicado no existe.', 1;

    IF @codigo IS NULL OR LEN(@codigo) = 0
        THROW 50010, 'El código del producto es obligatorio.', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.Productos
        WHERE UPPER(codigo) = UPPER(@codigo)
          AND id_producto <> @id_producto
    )
        THROW 50011, 'El código ya pertenece a otro producto registrado.', 1;

    IF @nombre IS NULL OR LEN(@nombre) = 0
        THROW 50012, 'El nombre del producto es obligatorio.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id_categoria = @id_categoria AND activo = 1)
        THROW 50013, 'La categoría seleccionada no existe o está inactiva.', 1;

    IF @precio_unitario IS NULL OR @precio_unitario <= 0
        THROW 50014, 'El precio unitario debe ser mayor que cero.', 1;

    IF @stock_minimo IS NULL OR @stock_minimo < 0
        THROW 50015, 'El stock mínimo no puede ser negativo.', 1;

    UPDATE dbo.Productos
    SET
        codigo = @codigo,
        nombre = @nombre,
        descripcion = @descripcion,
        id_categoria = @id_categoria,
        unidad_medida = @unidad_medida,
        precio_unitario = @precio_unitario,
        stock_minimo = @stock_minimo,
        fecha_vencimiento = @fecha_vencimiento,
        maneja_lotes = @maneja_lotes,
        activo = @activo,
        fecha_actualizacion = SYSDATETIME()
    WHERE id_producto = @id_producto;

    EXEC dbo.sp_Productos_ObtenerPorId @id_producto = @id_producto;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Productos_Desactivar
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE id_producto = @id_producto)
        THROW 50016, 'El producto indicado no existe.', 1;

    -- Regla 7: Los productos con movimientos registrados no se eliminan físicamente; se desactivan
    UPDATE dbo.Productos
    SET
        activo = 0,
        fecha_actualizacion = SYSDATETIME()
    WHERE id_producto = @id_producto;

    EXEC dbo.sp_Productos_ObtenerPorId @id_producto = @id_producto;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Lotes_ListarPorProducto
    @id_producto INT,
    @solo_con_stock BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);

    SELECT
        l.id_lote,
        l.id_producto,
        p.codigo AS codigo_producto,
        p.nombre AS nombre_producto,
        l.numero_lote,
        l.fecha_vencimiento,
        l.cantidad_inicial,
        l.stock_disponible,
        l.activo,
        l.fecha_registro,
        CASE
            WHEN l.fecha_vencimiento IS NULL THEN N'SIN_VENCIMIENTO'
            WHEN l.fecha_vencimiento < @hoy THEN N'VENCIDO'
            WHEN l.fecha_vencimiento <= DATEADD(DAY, 30, @hoy) THEN N'PROXIMO_A_VENCER'
            ELSE N'VIGENTE'
        END AS estado_vencimiento,
        CASE
            WHEN l.fecha_vencimiento IS NULL THEN NULL
            ELSE DATEDIFF(DAY, @hoy, l.fecha_vencimiento)
        END AS dias_para_vencer
    FROM dbo.Lotes l
    INNER JOIN dbo.Productos p ON p.id_producto = l.id_producto
    WHERE l.id_producto = @id_producto
      AND (@solo_con_stock = 0 OR l.stock_disponible > 0)
    ORDER BY
        CASE WHEN l.fecha_vencimiento IS NULL THEN 1 ELSE 0 END ASC,
        l.fecha_vencimiento ASC,
        l.id_lote ASC;
END
GO

-- ============================================================================
-- 3. REGISTRO DE ENTRADAS CON TRANSACCIÓN (RF03, Reglas 3, 5, 6, 10)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Entradas_Registrar
    @id_producto INT,
    @cantidad INT,
    @motivo NVARCHAR(150),
    @numero_lote NVARCHAR(60) = NULL,
    @fecha_vencimiento DATE = NULL,
    @fecha DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @motivo = LTRIM(RTRIM(@motivo));
    SET @numero_lote = NULLIF(LTRIM(RTRIM(@numero_lote)), N'');
    IF @fecha IS NULL SET @fecha = SYSDATETIME();

    IF @cantidad IS NULL OR @cantidad <= 0
        THROW 50020, 'La cantidad de entrada debe ser un número entero mayor que cero.', 1;

    IF @motivo IS NULL OR LEN(@motivo) = 0
        THROW 50021, 'El motivo de la entrada (Compra, Donación, Devolución, etc.) es obligatorio.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @stock_anterior INT;
        DECLARE @stock_posterior INT;
        DECLARE @maneja_lotes BIT;
        DECLARE @activo BIT;
        DECLARE @id_lote INT = NULL;
        DECLARE @fecha_venc_producto DATE;

        SELECT
            @stock_anterior = stock_actual,
            @maneja_lotes = maneja_lotes,
            @activo = activo,
            @fecha_venc_producto = fecha_vencimiento
        FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK)
        WHERE id_producto = @id_producto;

        IF @stock_anterior IS NULL
            THROW 50016, 'El producto especificado no existe.', 1;

        IF @activo = 0
            THROW 50022, 'No se pueden registrar entradas para un producto inactivo.', 1;

        IF @maneja_lotes = 1 AND @numero_lote IS NULL
            THROW 50023, 'Este producto requiere indicar el número de lote en la entrada.', 1;

        -- Gestión del lote cuando se proporciona número de lote
        IF @numero_lote IS NOT NULL
        BEGIN
            SELECT
                @id_lote = id_lote,
                @fecha_vencimiento = COALESCE(@fecha_vencimiento, fecha_vencimiento)
            FROM dbo.Lotes WITH (UPDLOCK, HOLDLOCK)
            WHERE id_producto = @id_producto
              AND UPPER(numero_lote) = UPPER(@numero_lote);

            IF @id_lote IS NULL
            BEGIN
                INSERT INTO dbo.Lotes (
                    id_producto,
                    numero_lote,
                    fecha_vencimiento,
                    cantidad_inicial,
                    stock_disponible,
                    activo
                )
                VALUES (
                    @id_producto,
                    @numero_lote,
                    @fecha_vencimiento,
                    @cantidad,
                    @cantidad,
                    1
                );

                SET @id_lote = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE dbo.Lotes
                SET
                    cantidad_inicial = cantidad_inicial + @cantidad,
                    stock_disponible = stock_disponible + @cantidad,
                    fecha_vencimiento = COALESCE(@fecha_vencimiento, fecha_vencimiento),
                    activo = 1
                WHERE id_lote = @id_lote;
            END
        END

        SET @stock_posterior = @stock_anterior + @cantidad;

        -- Actualizar stock del producto y fecha de vencimiento referencial si aplica
        UPDATE dbo.Productos
        SET
            stock_actual = @stock_posterior,
            fecha_vencimiento = CASE
                WHEN @fecha_vencimiento IS NOT NULL AND (@fecha_venc_producto IS NULL OR @fecha_vencimiento < @fecha_venc_producto)
                    THEN @fecha_vencimiento
                ELSE COALESCE(@fecha_venc_producto, @fecha_vencimiento)
            END,
            fecha_actualizacion = SYSDATETIME()
        WHERE id_producto = @id_producto;

        -- Registrar la entrada
        INSERT INTO dbo.Entradas (
            id_producto,
            id_lote,
            cantidad,
            fecha,
            motivo,
            numero_lote,
            fecha_vencimiento
        )
        VALUES (
            @id_producto,
            @id_lote,
            @cantidad,
            @fecha,
            @motivo,
            @numero_lote,
            @fecha_vencimiento
        );

        DECLARE @id_entrada INT = SCOPE_IDENTITY();

        -- Registrar el movimiento histórico en la misma transacción (Regla 5 y 6)
        INSERT INTO dbo.MovimientosInventario (
            id_producto,
            id_lote,
            id_entrada,
            id_salida,
            tipo_movimiento,
            cantidad,
            fecha,
            motivo,
            area_destino,
            numero_lote,
            fecha_vencimiento_lote,
            stock_anterior,
            stock_posterior
        )
        VALUES (
            @id_producto,
            @id_lote,
            @id_entrada,
            NULL,
            N'ENTRADA',
            @cantidad,
            @fecha,
            @motivo,
            NULL,
            @numero_lote,
            @fecha_vencimiento,
            @stock_anterior,
            @stock_posterior
        );

        DECLARE @id_movimiento INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            e.id_entrada,
            m.id_movimiento,
            e.id_producto,
            p.codigo AS codigo_producto,
            p.nombre AS nombre_producto,
            e.id_lote,
            e.numero_lote,
            e.fecha_vencimiento,
            e.cantidad,
            e.fecha,
            e.motivo,
            m.stock_anterior,
            m.stock_posterior
        FROM dbo.Entradas e
        INNER JOIN dbo.Productos p ON p.id_producto = e.id_producto
        INNER JOIN dbo.MovimientosInventario m ON m.id_movimiento = @id_movimiento
        WHERE e.id_entrada = @id_entrada;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Entradas_Listar
    @id_producto INT = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.id_entrada,
        e.id_producto,
        p.codigo AS codigo_producto,
        p.nombre AS nombre_producto,
        e.id_lote,
        e.numero_lote,
        e.fecha_vencimiento,
        e.cantidad,
        e.fecha,
        e.motivo,
        m.id_movimiento,
        m.stock_anterior,
        m.stock_posterior
    FROM dbo.Entradas e
    INNER JOIN dbo.Productos p ON p.id_producto = e.id_producto
    LEFT JOIN dbo.MovimientosInventario m ON m.id_entrada = e.id_entrada
    WHERE (@id_producto IS NULL OR e.id_producto = @id_producto)
      AND (@fecha_inicio IS NULL OR CAST(e.fecha AS DATE) >= @fecha_inicio)
      AND (@fecha_fin IS NULL OR CAST(e.fecha AS DATE) <= @fecha_fin)
    ORDER BY e.fecha DESC, e.id_entrada DESC;
END
GO

-- ============================================================================
-- 4. REGISTRO DE SALIDAS CON TRANSACCIÓN (RF04, Reglas 3, 4, 5, 6, 9, 10, 11)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Salidas_Registrar
    @id_producto INT,
    @cantidad INT,
    @motivo NVARCHAR(150),
    @area_destino NVARCHAR(100),
    @id_lote INT = NULL,
    @numero_lote NVARCHAR(60) = NULL,
    @fecha DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @motivo = LTRIM(RTRIM(@motivo));
    SET @area_destino = LTRIM(RTRIM(@area_destino));
    SET @numero_lote = NULLIF(LTRIM(RTRIM(@numero_lote)), N'');
    IF @fecha IS NULL SET @fecha = SYSDATETIME();
    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);

    IF @cantidad IS NULL OR @cantidad <= 0
        THROW 50030, 'La cantidad de salida debe ser un número entero mayor que cero.', 1;

    IF @motivo IS NULL OR LEN(@motivo) = 0
        THROW 50031, 'El motivo de la salida es obligatorio.', 1;

    IF @area_destino IS NULL OR LEN(@area_destino) = 0
        THROW 50032, 'El área hospitalaria de destino es obligatoria para toda salida.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @stock_anterior INT;
        DECLARE @stock_posterior INT;
        DECLARE @maneja_lotes BIT;
        DECLARE @activo BIT;
        DECLARE @fecha_venc_producto DATE;
        DECLARE @fecha_venc_lote DATE = NULL;
        DECLARE @stock_lote INT = NULL;

        SELECT
            @stock_anterior = stock_actual,
            @maneja_lotes = maneja_lotes,
            @activo = activo,
            @fecha_venc_producto = fecha_vencimiento
        FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK)
        WHERE id_producto = @id_producto;

        IF @stock_anterior IS NULL
            THROW 50016, 'El producto especificado no existe.', 1;

        IF @activo = 0
            THROW 50033, 'No se pueden registrar salidas de un producto inactivo.', 1;

        -- Regla 4: Impedir que se retire una cantidad superior al stock disponible
        IF @cantidad > @stock_anterior
            THROW 50004, 'Stock insuficiente: no se puede retirar una cantidad superior al stock disponible.', 1;

        -- Gestión y validación de lote y fecha de vencimiento (Reglas 9 y 10)
        IF @id_lote IS NOT NULL OR @numero_lote IS NOT NULL
        BEGIN
            SELECT
                @id_lote = id_lote,
                @numero_lote = numero_lote,
                @fecha_venc_lote = fecha_vencimiento,
                @stock_lote = stock_disponible
            FROM dbo.Lotes WITH (UPDLOCK, HOLDLOCK)
            WHERE id_producto = @id_producto
              AND (@id_lote IS NULL OR id_lote = @id_lote)
              AND (@numero_lote IS NULL OR UPPER(numero_lote) = UPPER(@numero_lote));

            IF @id_lote IS NULL
                THROW 50034, 'El lote indicado no existe para este producto.', 1;

            IF @fecha_venc_lote IS NOT NULL AND @fecha_venc_lote < @hoy
                THROW 50009, 'No se permite la salida: el lote seleccionado se encuentra vencido.', 1;

            IF @stock_lote < @cantidad
                THROW 50004, 'Stock insuficiente en el lote seleccionado para cubrir la salida.', 1;

            UPDATE dbo.Lotes
            SET stock_disponible = stock_disponible - @cantidad
            WHERE id_lote = @id_lote;
        END
        ELSE IF EXISTS (SELECT 1 FROM dbo.Lotes WHERE id_producto = @id_producto AND stock_disponible > 0)
        BEGIN
            -- Selección automática FEFO (First Expired, First Out) entre lotes NO vencidos con stock suficiente
            SELECT TOP 1
                @id_lote = id_lote,
                @numero_lote = numero_lote,
                @fecha_venc_lote = fecha_vencimiento,
                @stock_lote = stock_disponible
            FROM dbo.Lotes WITH (UPDLOCK, HOLDLOCK)
            WHERE id_producto = @id_producto
              AND stock_disponible >= @cantidad
              AND (fecha_vencimiento IS NULL OR fecha_vencimiento >= @hoy)
            ORDER BY
                CASE WHEN fecha_vencimiento IS NULL THEN 1 ELSE 0 END ASC,
                fecha_vencimiento ASC,
                id_lote ASC;

            IF @id_lote IS NULL
            BEGIN
                -- Comprobar si falló porque los lotes con stock están vencidos
                IF EXISTS (
                    SELECT 1
                    FROM dbo.Lotes
                    WHERE id_producto = @id_producto
                      AND stock_disponible > 0
                      AND fecha_vencimiento < @hoy
                )
                    THROW 50009, 'No se permite la salida: las existencias por lote del producto están vencidas.', 1;
                ELSE
                    THROW 50004, 'Ningún lote individual vigente dispone de stock suficiente; especifique el lote o divida la salida.', 1;
            END

            UPDATE dbo.Lotes
            SET stock_disponible = stock_disponible - @cantidad
            WHERE id_lote = @id_lote;
        END
        ELSE
        BEGIN
            -- Producto sin lotes registrados: validar fecha de vencimiento directa del producto (Regla 9)
            IF @fecha_venc_producto IS NOT NULL AND @fecha_venc_producto < @hoy
                THROW 50009, 'No se permite la salida para uso hospitalario: el producto se encuentra vencido.', 1;
        END

        SET @stock_posterior = @stock_anterior - @cantidad;

        UPDATE dbo.Productos
        SET
            stock_actual = @stock_posterior,
            fecha_actualizacion = SYSDATETIME()
        WHERE id_producto = @id_producto;

        INSERT INTO dbo.Salidas (
            id_producto,
            id_lote,
            cantidad,
            fecha,
            motivo,
            area_destino,
            numero_lote
        )
        VALUES (
            @id_producto,
            @id_lote,
            @cantidad,
            @fecha,
            @motivo,
            @area_destino,
            @numero_lote
        );

        DECLARE @id_salida INT = SCOPE_IDENTITY();

        INSERT INTO dbo.MovimientosInventario (
            id_producto,
            id_lote,
            id_entrada,
            id_salida,
            tipo_movimiento,
            cantidad,
            fecha,
            motivo,
            area_destino,
            numero_lote,
            fecha_vencimiento_lote,
            stock_anterior,
            stock_posterior
        )
        VALUES (
            @id_producto,
            @id_lote,
            NULL,
            @id_salida,
            N'SALIDA',
            @cantidad,
            @fecha,
            @motivo,
            @area_destino,
            @numero_lote,
            COALESCE(@fecha_venc_lote, @fecha_venc_producto),
            @stock_anterior,
            @stock_posterior
        );

        DECLARE @id_movimiento INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            s.id_salida,
            m.id_movimiento,
            s.id_producto,
            p.codigo AS codigo_producto,
            p.nombre AS nombre_producto,
            s.id_lote,
            s.numero_lote,
            m.fecha_vencimiento_lote AS fecha_vencimiento,
            s.cantidad,
            s.fecha,
            s.motivo,
            s.area_destino,
            m.stock_anterior,
            m.stock_posterior
        FROM dbo.Salidas s
        INNER JOIN dbo.Productos p ON p.id_producto = s.id_producto
        INNER JOIN dbo.MovimientosInventario m ON m.id_movimiento = @id_movimiento
        WHERE s.id_salida = @id_salida;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Salidas_Listar
    @id_producto INT = NULL,
    @area_destino NVARCHAR(100) = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @area_destino = NULLIF(LTRIM(RTRIM(@area_destino)), N'');

    SELECT
        s.id_salida,
        s.id_producto,
        p.codigo AS codigo_producto,
        p.nombre AS nombre_producto,
        s.id_lote,
        s.numero_lote,
        m.fecha_vencimiento_lote AS fecha_vencimiento,
        s.cantidad,
        s.fecha,
        s.motivo,
        s.area_destino,
        m.id_movimiento,
        m.stock_anterior,
        m.stock_posterior
    FROM dbo.Salidas s
    INNER JOIN dbo.Productos p ON p.id_producto = s.id_producto
    LEFT JOIN dbo.MovimientosInventario m ON m.id_salida = s.id_salida
    WHERE (@id_producto IS NULL OR s.id_producto = @id_producto)
      AND (@area_destino IS NULL OR s.area_destino = @area_destino)
      AND (@fecha_inicio IS NULL OR CAST(s.fecha AS DATE) >= @fecha_inicio)
      AND (@fecha_fin IS NULL OR CAST(s.fecha AS DATE) <= @fecha_fin)
    ORDER BY s.fecha DESC, s.id_salida DESC;
END
GO

-- ============================================================================
-- 5. HISTORIAL DE MOVIMIENTOS (RF05)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Movimientos_Listar
    @id_producto INT = NULL,
    @tipo_movimiento NVARCHAR(20) = NULL,
    @area_destino NVARCHAR(100) = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @tipo_movimiento = NULLIF(UPPER(LTRIM(RTRIM(@tipo_movimiento))), N'');
    SET @area_destino = NULLIF(LTRIM(RTRIM(@area_destino)), N'');

    SELECT
        m.id_movimiento,
        m.id_producto,
        p.codigo AS codigo_producto,
        p.nombre AS nombre_producto,
        c.nombre AS nombre_categoria,
        m.tipo_movimiento,
        m.cantidad,
        m.fecha,
        m.motivo,
        m.area_destino,
        m.id_lote,
        m.numero_lote,
        m.fecha_vencimiento_lote,
        m.stock_anterior,
        m.stock_posterior
    FROM dbo.MovimientosInventario m
    INNER JOIN dbo.Productos p ON p.id_producto = m.id_producto
    INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
    WHERE (@id_producto IS NULL OR m.id_producto = @id_producto)
      AND (@tipo_movimiento IS NULL OR m.tipo_movimiento = @tipo_movimiento)
      AND (@area_destino IS NULL OR m.area_destino = @area_destino)
      AND (@fecha_inicio IS NULL OR CAST(m.fecha AS DATE) >= @fecha_inicio)
      AND (@fecha_fin IS NULL OR CAST(m.fecha AS DATE) <= @fecha_fin)
    ORDER BY m.fecha DESC, m.id_movimiento DESC;
END
GO

-- ============================================================================
-- 6. CONSULTAS E INDICADORES (RF06, Regla 12)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Productos_StockBajo
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id_producto,
        p.codigo,
        p.nombre,
        p.id_categoria,
        c.nombre AS nombre_categoria,
        p.unidad_medida,
        p.precio_unitario,
        p.stock_actual,
        p.stock_minimo,
        (p.stock_minimo - p.stock_actual) AS deficit_stock,
        p.fecha_vencimiento,
        p.activo
    FROM dbo.Productos p
    INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
    WHERE p.activo = 1
      AND p.stock_actual <= p.stock_minimo
    ORDER BY p.stock_actual ASC, p.nombre ASC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Productos_Vencimientos
    @dias_alerta INT = 30,
    @estado NVARCHAR(30) = NULL -- 'VENCIDO', 'PROXIMO_A_VENCER' o NULL (ambos)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);
    DECLARE @fecha_limite DATE = DATEADD(DAY, ISNULL(@dias_alerta, 30), @hoy);
    SET @estado = NULLIF(UPPER(LTRIM(RTRIM(@estado))), N'');

    ;WITH AlertasVencimiento AS (
        -- Productos con lotes que tienen stock y fecha de vencimiento
        SELECT
            p.id_producto,
            p.codigo,
            p.nombre,
            p.id_categoria,
            c.nombre AS nombre_categoria,
            p.unidad_medida,
            p.precio_unitario,
            p.stock_actual,
            l.id_lote,
            l.numero_lote,
            l.stock_disponible AS cantidad_afectada,
            l.fecha_vencimiento,
            DATEDIFF(DAY, @hoy, l.fecha_vencimiento) AS dias_para_vencer,
            CASE
                WHEN l.fecha_vencimiento < @hoy THEN N'VENCIDO'
                ELSE N'PROXIMO_A_VENCER'
            END AS estado_vencimiento
        FROM dbo.Lotes l
        INNER JOIN dbo.Productos p ON p.id_producto = l.id_producto
        INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
        WHERE p.activo = 1
          AND l.stock_disponible > 0
          AND l.fecha_vencimiento IS NOT NULL
          AND l.fecha_vencimiento <= @fecha_limite

        UNION ALL

        -- Productos activos con fecha_vencimiento directa sin lotes con stock
        SELECT
            p.id_producto,
            p.codigo,
            p.nombre,
            p.id_categoria,
            c.nombre AS nombre_categoria,
            p.unidad_medida,
            p.precio_unitario,
            p.stock_actual,
            CAST(NULL AS INT) AS id_lote,
            CAST(NULL AS NVARCHAR(60)) AS numero_lote,
            p.stock_actual AS cantidad_afectada,
            p.fecha_vencimiento,
            DATEDIFF(DAY, @hoy, p.fecha_vencimiento) AS dias_para_vencer,
            CASE
                WHEN p.fecha_vencimiento < @hoy THEN N'VENCIDO'
                ELSE N'PROXIMO_A_VENCER'
            END AS estado_vencimiento
        FROM dbo.Productos p
        INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
        WHERE p.activo = 1
          AND p.fecha_vencimiento IS NOT NULL
          AND p.fecha_vencimiento <= @fecha_limite
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.Lotes l2
              WHERE l2.id_producto = p.id_producto
                AND l2.stock_disponible > 0
                AND l2.fecha_vencimiento IS NOT NULL
          )
    )
    SELECT
        id_producto,
        codigo,
        nombre,
        id_categoria,
        nombre_categoria,
        unidad_medida,
        precio_unitario,
        stock_actual,
        id_lote,
        numero_lote,
        cantidad_afectada,
        fecha_vencimiento,
        dias_para_vencer,
        estado_vencimiento
    FROM AlertasVencimiento
    WHERE (@estado IS NULL OR estado_vencimiento = @estado)
    ORDER BY fecha_vencimiento ASC, nombre ASC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Indicadores_Resumen
    @dias_alerta INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSDATETIME() AS DATE);
    DECLARE @fecha_limite DATE = DATEADD(DAY, ISNULL(@dias_alerta, 30), @hoy);

    SELECT
        (SELECT COUNT(1) FROM dbo.Productos WHERE activo = 1) AS total_productos_activos,
        (SELECT COUNT(1) FROM dbo.Categorias WHERE activo = 1) AS total_categorias_activas,
        (SELECT COUNT(1) FROM dbo.Productos WHERE activo = 1 AND stock_actual <= stock_minimo) AS total_productos_stock_bajo,
        (
            SELECT COUNT(DISTINCT p.id_producto)
            FROM dbo.Productos p
            LEFT JOIN dbo.Lotes l ON l.id_producto = p.id_producto AND l.stock_disponible > 0
            WHERE p.activo = 1
              AND (
                  (l.fecha_vencimiento IS NOT NULL AND l.fecha_vencimiento < @hoy)
                  OR (l.id_lote IS NULL AND p.fecha_vencimiento IS NOT NULL AND p.fecha_vencimiento < @hoy)
              )
        ) AS total_productos_vencidos,
        (
            SELECT COUNT(DISTINCT p.id_producto)
            FROM dbo.Productos p
            LEFT JOIN dbo.Lotes l ON l.id_producto = p.id_producto AND l.stock_disponible > 0
            WHERE p.activo = 1
              AND (
                  (l.fecha_vencimiento IS NOT NULL AND l.fecha_vencimiento BETWEEN @hoy AND @fecha_limite)
                  OR (l.id_lote IS NULL AND p.fecha_vencimiento IS NOT NULL AND p.fecha_vencimiento BETWEEN @hoy AND @fecha_limite)
              )
        ) AS total_productos_proximos_vencer,
        ISNULL((
            SELECT CAST(SUM(CAST(stock_actual AS DECIMAL(18,2)) * precio_unitario) AS DECIMAL(18,2))
            FROM dbo.Productos
            WHERE activo = 1
        ), 0.00) AS valor_referencial_inventario,
        (
            SELECT COUNT(1)
            FROM dbo.MovimientosInventario
            WHERE CAST(fecha AS DATE) = @hoy
        ) AS total_movimientos_hoy;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Indicadores_ProductosMayoresSalidas
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL,
    @top INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @top IS NULL OR @top <= 0 SET @top = 10;

    SELECT TOP (@top)
        p.id_producto,
        p.codigo,
        p.nombre,
        c.nombre AS nombre_categoria,
        p.unidad_medida,
        p.precio_unitario,
        p.stock_actual,
        SUM(s.cantidad) AS total_unidades_salidas,
        COUNT(s.id_salida) AS numero_salidas,
        CAST(SUM(CAST(s.cantidad AS DECIMAL(18,2)) * p.precio_unitario) AS DECIMAL(18,2)) AS valor_estimado_salidas
    FROM dbo.Salidas s
    INNER JOIN dbo.Productos p ON p.id_producto = s.id_producto
    INNER JOIN dbo.Categorias c ON c.id_categoria = p.id_categoria
    WHERE (@fecha_inicio IS NULL OR CAST(s.fecha AS DATE) >= @fecha_inicio)
      AND (@fecha_fin IS NULL OR CAST(s.fecha AS DATE) <= @fecha_fin)
    GROUP BY
        p.id_producto,
        p.codigo,
        p.nombre,
        c.nombre,
        p.unidad_medida,
        p.precio_unitario,
        p.stock_actual
    ORDER BY total_unidades_salidas DESC, numero_salidas DESC;
END
GO

-- ============================================================================
-- 7. AUTENTICACIÓN DE USUARIOS (Soporte inicio de sesión del sistema)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_Usuarios_Autenticar
    @username NVARCHAR(50),
    @password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id_usuario,
        username,
        nombre_completo,
        rol,
        activo
    FROM dbo.Usuarios
    WHERE username = LTRIM(RTRIM(@username))
      AND password_hash = @password
      AND activo = 1;
END
GO
