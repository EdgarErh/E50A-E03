
CREATE VIEW vista_detalle_pedidos AS
SELECT
    p.id_pedido,
    c.nombre AS nombre_cliente,
    pr.nombre AS nombre_producto,
    dp.cantidad,
    pr.precio,
    (dp.cantidad * pr.precio) AS total_linea
FROM
    detalle_pedido dp
JOIN
    pedidos p ON dp.id_pedido = p.id_pedido
JOIN
    clientes c ON p.id_cliente = c.id_cliente
JOIN
    productos pr ON dp.id_producto = pr.id_producto;


CREATE OR REPLACE FUNCTION registrar_pedido(
    p_id_cliente INT,
    p_fecha DATE,
    p_id_producto INT,
    p_cantidad INT
)
RETURNS VOID AS $$
DECLARE
    v_new_pedido_id INT;
BEGIN
    -- Insertar pedido y OBTENER el nuevo ID (PostgreSQL RETURNING)
    INSERT INTO pedidos (id_cliente, fecha)
    VALUES (p_id_cliente, p_fecha)
    RETURNING id_pedido INTO v_new_pedido_id;

    -- Insertar el detalle del pedido
    INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad)
    VALUES (v_new_pedido_id, p_id_producto, p_cantidad);

END;
$$ LANGUAGE plpgsql;
 


CREATE OR REPLACE FUNCTION total_gastado_por_cliente(
    p_id_cliente INT
)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    total_gastado DECIMAL(10, 2);
BEGIN
    -- Utiliza COALESCE para devolver 0.00 si no hay pedidos
    SELECT COALESCE(SUM(dp.cantidad * p.precio), 0.00)
    INTO total_gastado
    FROM detalle_pedido dp
    JOIN pedidos ped ON dp.id_pedido = ped.id_pedido
    JOIN productos p ON dp.id_producto = p.id_producto
    WHERE ped.id_cliente = p_id_cliente;

    RETURN total_gastado;
END;
$$ LANGUAGE plpgsql;


CREATE INDEX idx_cliente_producto ON detalle_pedido (id_producto, cantidad);


CREATE OR REPLACE FUNCTION registrar_auditoria_pedido()
RETURNS TRIGGER AS $$
BEGIN
    -- NEW hace referencia a la fila que se acaba de insertar
    INSERT INTO auditoria_pedidos (id_cliente, fecha_pedido)
    VALUES (NEW.id_cliente, NEW.fecha);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER registrar_auditoria_pedido
AFTER INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria_pedido();

