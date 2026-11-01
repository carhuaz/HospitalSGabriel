/* ============================================================================
   SISTEMA DE INVENTARIO HOSPITALARIO - HOSPITAL SAN GABRIEL
   Script 03: Datos de Prueba Iniciales (Productos, Lotes, Entradas y Salidas)
   Motor: Microsoft SQL Server
   ============================================================================ */

USE HospitalSanGabrielDB;
GO

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE codigo = N'MED-001')
BEGIN
    DECLARE @id_cat_med INT = (SELECT id_categoria FROM dbo.Categorias WHERE nombre = N'Medicamentos');
    DECLARE @id_cat_mat INT = (SELECT id_categoria FROM dbo.Categorias WHERE nombre = N'Material Médico');
    DECLARE @id_cat_lab INT = (SELECT id_categoria FROM dbo.Categorias WHERE nombre = N'Material de Laboratorio');
    DECLARE @id_cat_lim INT = (SELECT id_categoria FROM dbo.Categorias WHERE nombre = N'Productos de Limpieza Hospitalaria');

    -- 1. Paracetamol 500mg (Medicamento vigente con stock normal)
    EXEC dbo.sp_Productos_Registrar
        @codigo = N'MED-001',
        @nombre = N'Paracetamol 500 mg Tableta',
        @descripcion = N'Analgésico y antipirético oral en blíster',
        @id_categoria = @id_cat_med,
        @unidad_medida = N'Caja x 100 tab',
        @precio_unitario = 18.50,
        @stock_minimo = 20,
        @fecha_vencimiento = NULL,
        @maneja_lotes = 1;

    DECLARE @id_prod_med1 INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = N'MED-001');
    DECLARE @venc_vigente DATE = DATEADD(MONTH, 8, CAST(SYSDATETIME() AS DATE));

    EXEC dbo.sp_Entradas_Registrar
        @id_producto = @id_prod_med1,
        @cantidad = 80,
        @motivo = N'Compra orden hospitalaria OC-2026-001',
        @numero_lote = N'LOT-PAR-2026A',
        @fecha_vencimiento = @venc_vigente;

    EXEC dbo.sp_Salidas_Registrar
        @id_producto = @id_prod_med1,
        @cantidad = 15,
        @motivo = N'Abastecimiento semanal de farmacia de emergencia',
        @area_destino = N'Emergencia',
        @numero_lote = N'LOT-PAR-2026A';

    -- 2. Amoxicilina 500mg (Próximo a vencer en 15 días)
    EXEC dbo.sp_Productos_Registrar
        @codigo = N'MED-002',
        @nombre = N'Amoxicilina 500 mg Cápsula',
        @descripcion = N'Antibiótico betalactámico de amplio espectro',
        @id_categoria = @id_cat_med,
        @unidad_medida = N'Caja x 50 cap',
        @precio_unitario = 32.00,
        @stock_minimo = 15,
        @fecha_vencimiento = NULL,
        @maneja_lotes = 1;

    DECLARE @id_prod_med2 INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = N'MED-002');
    DECLARE @venc_proximo DATE = DATEADD(DAY, 15, CAST(SYSDATETIME() AS DATE));

    EXEC dbo.sp_Entradas_Registrar
        @id_producto = @id_prod_med2,
        @cantidad = 30,
        @motivo = N'Compra licitación MINSA',
        @numero_lote = N'LOT-AMO-2026B',
        @fecha_vencimiento = @venc_proximo;

    -- 3. Guantes Quirúrgicos Estériles N° 7.5 (Con Stock Bajo: stock_actual <= stock_minimo)
    EXEC dbo.sp_Productos_Registrar
        @codigo = N'MAT-001',
        @nombre = N'Guantes Quirúrgicos Estériles N° 7.5',
        @descripcion = N'Guantes de látex estériles empaque individual',
        @id_categoria = @id_cat_mat,
        @unidad_medida = N'Caja x 50 pares',
        @precio_unitario = 45.00,
        @stock_minimo = 25,
        @fecha_vencimiento = NULL,
        @maneja_lotes = 1;

    DECLARE @id_prod_mat1 INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = N'MAT-001');
    DECLARE @venc_guantes DATE = DATEADD(YEAR, 2, CAST(SYSDATETIME() AS DATE));

    EXEC dbo.sp_Entradas_Registrar
        @id_producto = @id_prod_mat1,
        @cantidad = 30,
        @motivo = N'Compra directa proveedor médico',
        @numero_lote = N'LOT-GUA-2026',
        @fecha_vencimiento = @venc_guantes;

    EXEC dbo.sp_Salidas_Registrar
        @id_producto = @id_prod_mat1,
        @cantidad = 20,
        @motivo = N'Requerimiento de sala de cirugía y hospitalización',
        @area_destino = N'Hospitalización',
        @numero_lote = N'LOT-GUA-2026';

    -- 4. Reactivo Hemograma Completo (Lote Vencido para demostración de bloqueo Regla 9)
    EXEC dbo.sp_Productos_Registrar
        @codigo = N'LAB-001',
        @nombre = N'Reactivo Lisante para Hematología 500 ml',
        @descripcion = N'Reactivo diagnóstico para analizador hematológico automatizado',
        @id_categoria = @id_cat_lab,
        @unidad_medida = N'Frasco 500 ml',
        @precio_unitario = 180.00,
        @stock_minimo = 5,
        @fecha_vencimiento = NULL,
        @maneja_lotes = 1;

    DECLARE @id_prod_lab1 INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = N'LAB-001');
    DECLARE @venc_pasado DATE = DATEADD(DAY, -10, CAST(SYSDATETIME() AS DATE));

    EXEC dbo.sp_Entradas_Registrar
        @id_producto = @id_prod_lab1,
        @cantidad = 8,
        @motivo = N'Donación lote remanente',
        @numero_lote = N'LOT-REA-VENC',
        @fecha_vencimiento = @venc_pasado;

    -- 5. Amonio Cuaternario 5ta Generación (Limpieza Hospitalaria)
    EXEC dbo.sp_Productos_Registrar
        @codigo = N'LIM-001',
        @nombre = N'Desinfectante Amonio Cuaternario 5ta Gen.',
        @descripcion = N'Desinfectante de superficies críticas hospitalarias',
        @id_categoria = @id_cat_lim,
        @unidad_medida = N'Galón 4 L',
        @precio_unitario = 65.00,
        @stock_minimo = 10,
        @fecha_vencimiento = NULL,
        @maneja_lotes = 0;

    DECLARE @id_prod_lim1 INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = N'LIM-001');

    EXEC dbo.sp_Entradas_Registrar
        @id_producto = @id_prod_lim1,
        @cantidad = 40,
        @motivo = N'Compra mensual insumos de bioseguridad',
        @numero_lote = NULL,
        @fecha_vencimiento = NULL;

    EXEC dbo.sp_Salidas_Registrar
        @id_producto = @id_prod_lim1,
        @cantidad = 12,
        @motivo = N'Desinfección de consultorios y toma de muestras',
        @area_destino = N'Consultorios Externos';
END
GO
