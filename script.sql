
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
