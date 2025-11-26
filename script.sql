
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


-- ----------------------------------------------------------
-- 03_ADVANCED_DB_OBJECTS.SQL: Procedimientos, Funciones e Índices
-- ----------------------------------------------------------

-- ----------------------------------------------------------
-- 1. PROCEDIMIENTO ALMACENADO: registrar_pedido
-- Registra un nuevo pedido y su detalle en una sola llamada.
-- Nota: En PostgreSQL se usa una FUNCTION con RETURNS VOID.
-- ----------------------------------------------------------
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
    -- 1. Insertar el nuevo pedido en la tabla pedidos
    INSERT INTO pedidos (id_cliente, fecha)
    VALUES (p_id_cliente, p_fecha)
    RETURNING id_pedido INTO v_new_pedido_id;

    -- 2. Insertar el detalle del pedido
    INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad)
    VALUES (v_new_pedido_id, p_id_producto, p_cantidad);

    -- 3. (Opcional) Mensaje de éxito
    RAISE NOTICE 'Pedido #% registrado para el cliente %.', v_new_pedido_id, p_id_cliente;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo de uso (PostgreSQL utiliza SELECT para llamar funciones que devuelven VOID):
-- SELECT registrar_pedido(1, '2025-05-20', 4, 1); -- Cliente Ana compra 1 Monitor

-- ----------------------------------------------------------
-- 2. FUNCIÓN: total_gastado_por_cliente
-- Devuelve el total gastado por un cliente.
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION total_gastado_por_cliente(
    p_id_cliente INT
)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    total_gastado DECIMAL(10, 2);
BEGIN
    SELECT COALESCE(SUM(dp.cantidad * p.precio), 0.00)
    INTO total_gastado
    FROM detalle_pedido dp
    JOIN pedidos ped ON dp.id_pedido = ped.id_pedido
    JOIN productos p ON dp.id_producto = p.id_producto
    WHERE ped.id_cliente = p_id_cliente;

    RETURN total_gastado;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo de uso:
-- SELECT total_gastado_por_cliente(1);

-- ----------------------------------------------------------
-- 3. ÍNDICE COMPUESTO: idx_cliente_producto
-- Índice para optimizar consultas que relacionan clientes y productos
-- ----------------------------------------------------------
CREATE INDEX idx_cliente_producto ON detalle_pedido (id_producto, cantidad);

-- ----------------------------------------------------------
-- 4. DISPARADOR (TRIGGER): registrar_auditoria_pedido
-- Registra cada nuevo pedido en la tabla de auditoría.
-- ----------------------------------------------------------

-- ⚙️ 4a. Crear la función del trigger
CREATE OR REPLACE FUNCTION registrar_auditoria_pedido()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_pedidos (id_cliente, fecha_pedido)
    VALUES (NEW.id_cliente, NEW.fecha);

    RETURN NEW; -- Importante para triggers AFTER INSERT/UPDATE/DELETE
END;
$$ LANGUAGE plpgsql;

-- 🔔 4b. Crear el trigger
CREATE TRIGGER registrar_auditoria_pedido
AFTER INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria_pedido();

-- ✅ 4c. Pruebas del Trigger:
-- Insertar un nuevo pedido
-- INSERT INTO pedidos (id_cliente, fecha) VALUES (1, '2025-05-20');
-- Verificar la auditoría
-- SELECT * FROM auditoria_pedidos;
