import psycopg2
from .conftest import db_connection

def test_trigger_auditoria_se_activa():
    conn = db_connection()
    cur = conn.cursor()

    id_cliente_prueba = 2
    fecha_prueba = '2025-12-15'

    cur.execute("SELECT COUNT(*) FROM auditoria_pedidos;")
    count_before = cur.fetchone()[0]

    cur.execute(f"INSERT INTO pedidos (id_cliente, fecha) VALUES ({id_cliente_prueba}, '{fecha_prueba}');")
    
   
    cur.execute("SELECT COUNT(*) FROM auditoria_pedidos;")
    count_after = cur.fetchone()[0]

    
    assert count_after == count_before + 1

   
    cur.execute("SELECT id_cliente, fecha_pedido FROM auditoria_pedidos ORDER BY id_auditoria DESC LIMIT 1;")
    registro_auditoria = cur.fetchone()

    assert registro_auditoria[0] == id_cliente_prueba
  
    assert str(registro_auditoria[1]) == fecha_prueba

    conn.rollback() 
    cur.close()
    conn.close()
