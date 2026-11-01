import uuid
from datetime import date, timedelta
from fastapi.testclient import TestClient

from main import app
from repositories.database import get_db_connection

client = TestClient(app)


def test_health_and_root():
    r_root = client.get("/")
    assert r_root.status_code == 200
    assert r_root.json()["estado"] == "operativo"

    r_health = client.get("/api/health")
    assert r_health.status_code == 200
    assert r_health.json()["status"] == "ok"


def test_categorias_endpoints():
    r_list = client.get("/api/categorias")
    assert r_list.status_code == 200
    categorias = r_list.json()
    assert len(categorias) >= 4
    nombres = [c["nombre"] for c in categorias]
    assert "Medicamentos" in nombres
    assert "Material Médico" in nombres


def test_autenticacion_roles_hospitalarios():
    credenciales = [
        ("admin", "admin123", "Administrador"),
        ("farmacia", "farmacia123", "Farmacia"),
        ("almacen", "almacen123", "Almacén"),
    ]
    for username, password, rol_esperado in credenciales:
        r = client.post("/api/auth/login", json={"username": username, "password": password})
        assert r.status_code == 200, r.text
        data = r.json()
        assert data["username"] == username
        assert data["rol"] == rol_esperado
        assert data["activo"] is True


def test_flujo_completo_y_reglas_de_negocio():
    sufijo = uuid.uuid4().hex[:6].upper()
    codigo_test = f"TEST-{sufijo}"

    try:
        # 1. Registrar producto válido (RF01)
        payload_prod = {
            "codigo": codigo_test,
            "nombre": f"Cefalexina 500mg Test {sufijo}",
            "descripcion": "Producto de prueba automatizada",
            "id_categoria": 1,
            "unidad_medida": "Caja x 100",
            "precio_unitario": 25.50,
            "stock_minimo": 10,
            "fecha_vencimiento": None,
            "maneja_lotes": True,
        }
        r_create = client.post("/api/productos", json=payload_prod)
        assert r_create.status_code == 201, r_create.text
        prod = r_create.json()
        id_prod = prod["id_producto"]
        assert prod["stock_actual"] == 0
        assert prod["activo"] is True

        # Regla 1: Código único de producto -> debe fallar con 409 Conflict
        r_dup = client.post("/api/productos", json=payload_prod)
        assert r_dup.status_code == 409

        # Regla 2: Precio unitario mayor que cero -> debe fallar con 422
        payload_precio_invalido = {**payload_prod, "codigo": f"INV-{sufijo}", "precio_unitario": 0}
        r_precio = client.post("/api/productos", json=payload_precio_invalido)
        assert r_precio.status_code in (400, 422)

        # Regla 3: Cantidad de entrada debe ser entero > 0 -> falla con 422
        r_ent_invalida = client.post(
            "/api/entradas",
            json={
                "id_producto": id_prod,
                "cantidad": 0,
                "motivo": "Compra",
                "numero_lote": f"LOT-VIG-{sufijo}",
            },
        )
        assert r_ent_invalida.status_code in (400, 422)

        # RF03, Regla 5, 6 y 10: Registrar entrada válida con lote vigente
        venc_futuro = (date.today() + timedelta(days=120)).isoformat()
        lote_vigente = f"LOT-VIG-{sufijo}"
        r_ent = client.post(
            "/api/entradas",
            json={
                "id_producto": id_prod,
                "cantidad": 25,
                "motivo": "Compra licitación hospitalaria",
                "numero_lote": lote_vigente,
                "fecha_vencimiento": venc_futuro,
            },
        )
        assert r_ent.status_code == 201, r_ent.text
        ent_data = r_ent.json()
        assert ent_data["stock_anterior"] == 0
        assert ent_data["stock_posterior"] == 25
        assert ent_data["numero_lote"] == lote_vigente

        # Regla 4: No permitir salida que genere stock negativo (solicitar 30 > 25 disponibles)
        r_sal_exceso = client.post(
            "/api/salidas",
            json={
                "id_producto": id_prod,
                "cantidad": 30,
                "motivo": "Consumo excesivo prueba",
                "area_destino": "Emergencia",
                "numero_lote": lote_vigente,
            },
        )
        assert r_sal_exceso.status_code == 400
        assert "insuficiente" in r_sal_exceso.json()["detail"].lower()

        # RF04, Reglas 5, 6, 10, 11: Registrar salida válida hacia área hospitalaria
        r_sal = client.post(
            "/api/salidas",
            json={
                "id_producto": id_prod,
                "cantidad": 10,
                "motivo": "Dispensación hospitalaria",
                "area_destino": "Emergencia",
                "numero_lote": lote_vigente,
            },
        )
        assert r_sal.status_code == 201, r_sal.text
        sal_data = r_sal.json()
        assert sal_data["stock_anterior"] == 25
        assert sal_data["stock_posterior"] == 15
        assert sal_data["area_destino"] == "Emergencia"

        # Regla 9: Productos/lotes vencidos no pueden salir para uso hospitalario
        venc_pasado = (date.today() - timedelta(days=5)).isoformat()
        lote_vencido = f"LOT-EXP-{sufijo}"
        r_ent_venc = client.post(
            "/api/entradas",
            json={
                "id_producto": id_prod,
                "cantidad": 5,
                "motivo": "Devolución lote vencido",
                "numero_lote": lote_vencido,
                "fecha_vencimiento": venc_pasado,
            },
        )
        assert r_ent_venc.status_code == 201

        r_sal_venc = client.post(
            "/api/salidas",
            json={
                "id_producto": id_prod,
                "cantidad": 2,
                "motivo": "Intento retiro vencido",
                "area_destino": "Laboratorio",
                "numero_lote": lote_vencido,
            },
        )
        assert r_sal_venc.status_code == 400
        assert "vencido" in r_sal_venc.json()["detail"].lower()

        # RF05: Consultar historial de movimientos del producto
        r_movs = client.get(f"/api/movimientos?id_producto={id_prod}")
        assert r_movs.status_code == 200
        movs = r_movs.json()
        assert len(movs) == 3  # 2 entradas + 1 salida

        # Regla 7: Desactivar producto sin eliminar su historial de movimientos
        r_desact = client.patch(f"/api/productos/{id_prod}/desactivar")
        assert r_desact.status_code == 200
        assert r_desact.json()["activo"] is False

        # Verificar que el historial de movimientos se conserva intacto tras desactivar
        r_movs_post = client.get(f"/api/movimientos?id_producto={id_prod}")
        assert r_movs_post.status_code == 200
        assert len(r_movs_post.json()) == 3

        # RF06 y Regla 12: Indicadores y consultas en tiempo real
        r_resumen = client.get("/api/indicadores/resumen")
        assert r_resumen.status_code == 200
        resumen = r_resumen.json()
        assert resumen["total_productos_activos"] >= 1
        assert float(resumen["valor_referencial_inventario"]) > 0

        r_stock_bajo = client.get("/api/indicadores/stock-bajo")
        assert r_stock_bajo.status_code == 200
        assert isinstance(r_stock_bajo.json(), list)

        r_venc = client.get("/api/indicadores/vencimientos?dias_alerta=30")
        assert r_venc.status_code == 200
        assert len(r_venc.json()) >= 1

        r_top = client.get("/api/indicadores/mayores-salidas")
        assert r_top.status_code == 200
        assert len(r_top.json()) >= 1

    finally:
        # Limpieza de datos temporales del test para no ensuciar la base de datos de demostración
        with get_db_connection(autocommit=True) as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                DECLARE @id INT = (SELECT id_producto FROM dbo.Productos WHERE codigo = ?);
                IF @id IS NOT NULL
                BEGIN
                    DELETE FROM dbo.MovimientosInventario WHERE id_producto = @id;
                    DELETE FROM dbo.Salidas WHERE id_producto = @id;
                    DELETE FROM dbo.Entradas WHERE id_producto = @id;
                    DELETE FROM dbo.Lotes WHERE id_producto = @id;
                    DELETE FROM dbo.Productos WHERE id_producto = @id;
                END
                """,
                (codigo_test,),
            )
