DROP TABLE IF EXISTS order_log CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(100)   NOT NULL,
    email       VARCHAR(100)   UNIQUE NOT NULL,
    balance     NUMERIC(10, 2) DEFAULT 0
);

CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    product_name   VARCHAR(100)   NOT NULL,
    price          NUMERIC(10, 2) NOT NULL,
    stock_quantity INT            NOT NULL
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES customers(customer_id),
    order_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) DEFAULT 0
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT            REFERENCES orders(order_id),
    product_id    INT            REFERENCES products(product_id),
    quantity      INT            NOT NULL,
    price         NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_log (
    log_id      SERIAL PRIMARY KEY,
    order_id    INT,
    customer_id INT,
    action      VARCHAR(50),
    log_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(quantity * price), 0)
    INTO v_total
    FROM order_items
    WHERE order_id = p_order_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE PROCEDURE create_order(p_customer_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists
    FROM customers
    WHERE customer_id = p_customer_id;

    IF v_exists = 0 THEN
        RAISE NOTICE 'Customer with id % does not exist.', p_customer_id;
        RETURN;
    END IF;

    INSERT INTO orders (customer_id, order_date, total_amount)
    VALUES (p_customer_id, CURRENT_TIMESTAMP, 0);
END;
$$;



CREATE OR REPLACE PROCEDURE add_product_to_order(
    p_order_id   INT,
    p_product_id INT,
    p_quantity   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_price         NUMERIC(10, 2);
    v_stock         INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than 0.';
    END IF;

    SELECT price, stock_quantity
    INTO v_price, v_stock
    FROM products
    WHERE product_id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product with id % does not exist.', p_product_id;
    END IF;

    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Not enough stock. Available: %, requested: %.', v_stock, p_quantity;
    END IF;

    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (p_order_id, p_product_id, p_quantity, v_price);

    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;
END;
$$;



CREATE OR REPLACE FUNCTION trg_update_order_total()
RETURNS TRIGGER AS $$
DECLARE
    v_order_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    UPDATE orders
    SET total_amount = calculate_order_total(v_order_id)
    WHERE order_id = v_order_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_order_items_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_update_order_total();



CREATE OR REPLACE FUNCTION trg_log_new_order()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_log (order_id, customer_id, action, log_date)
    VALUES (NEW.order_id, NEW.customer_id, 'ORDER_CREATED', CURRENT_TIMESTAMP);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_orders_audit
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_log_new_order();



INSERT INTO customers (full_name, email, balance) VALUES
('John Smith',      'john.smith@example.com',    150.00),
('Anna Brown',      'anna.brown@example.com',    300.00),
('Michael Johnson', 'michael.johnson@example.com', 75.50),
('Kate Wilson',     'kate.wilson@example.com',   500.00);


INSERT INTO products (product_name, price, stock_quantity) VALUES
('Laptop',     1200.00, 10),
('Mouse',        25.00, 100),
('Keyboard',     70.00, 50),
('Monitor',     250.00, 20),
('USB-C Cable',  15.00, 200);


CALL create_order(1);  
CALL create_order(2);  
CALL create_order(99); 


CALL add_product_to_order(1, 1, 1);  
CALL add_product_to_order(1, 2, 2);  
CALL add_product_to_order(2, 3, 1);  



SELECT order_id, total_amount FROM orders;



SELECT product_id, product_name, stock_quantity FROM products;


SELECT * FROM order_log;

SELECT calculate_order_total(1);  
SELECT calculate_order_total(2); 


EXPLAIN ANALYZE
SELECT
    oi.order_id,
    p.product_name,
    oi.quantity,
    oi.price,
    oi.quantity * oi.price AS item_total
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.order_id = 1;
