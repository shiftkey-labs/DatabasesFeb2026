/* =========================================================
   Track A: Ateko Mini Commerce Backend
   Schema + Seed Data (MySQL 8+)
   ========================================================= */

DROP DATABASE IF EXISTS ateko_commerce_week3;
CREATE DATABASE ateko_commerce_week3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ateko_commerce_week3;

/* -------------------------
   Tables
   ------------------------- */

CREATE TABLE customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_email (email),
  KEY idx_customers_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  stock INT NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_products_active_price (is_active, price),
  KEY idx_products_created_at_id (created_at, id)
) ENGINE=InnoDB;

CREATE TABLE orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  status ENUM('created','paid','cancelled') NOT NULL DEFAULT 'created',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_orders_customer_created (customer_id, created_at, id),
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_items_order_product (order_id, product_id),
  KEY idx_order_items_product (product_id),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

/* Optional but useful for Week 4 discussions */
CREATE TABLE inventory_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  change_amount INT NOT NULL,
  reason VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_inventory_events_product_created (product_id, created_at, id),
  CONSTRAINT fk_inventory_events_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

/* -------------------------
   Seed Data
   ------------------------- */

INSERT INTO customers (name, email) VALUES
('Ava Chen', 'ava.chen@example.com'),
('Noah Patel', 'noah.patel@example.com'),
('Mia Johnson', 'mia.johnson@example.com'),
('Liam Brown', 'liam.brown@example.com'),
('Sophia Martin', 'sophia.martin@example.com'),
('Ethan Wilson', 'ethan.wilson@example.com'),
('Isabella Garcia', 'isabella.garcia@example.com'),
('Oliver Smith', 'oliver.smith@example.com');

INSERT INTO products (name, price, stock, is_active) VALUES
('Wireless Mouse', 24.99, 120, 1),
('Mechanical Keyboard', 109.00, 45, 1),
('USB-C Hub 8-in-1', 59.90, 70, 1),
('1080p Webcam', 49.50, 0, 1),
('Laptop Stand', 34.99, 85, 1),
('Noise Cancelling Headphones', 199.99, 25, 1),
('Portable SSD 1TB', 129.99, 40, 1),
('HDMI Cable 2m', 9.99, 300, 1),
('Ergonomic Chair', 289.00, 10, 0),
('Desk Lamp', 22.49, 65, 1),
('Microphone', 79.99, 30, 1),
('Monitor 27 inch', 219.00, 18, 1);

/* Create a few orders */
INSERT INTO orders (customer_id, status, total_amount) VALUES
(1, 'paid', 0.00),
(2, 'paid', 0.00),
(3, 'created', 0.00),
(1, 'paid', 0.00),
(4, 'cancelled', 0.00);

/* Order items */
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2, 24.99),
(1, 8, 3, 9.99),
(1, 5, 1, 34.99),

(2, 2, 1, 109.00),
(2, 3, 1, 59.90),

(3, 6, 1, 199.99),
(3, 10, 2, 22.49),

(4, 7, 1, 129.99),
(4, 11, 1, 79.99),

(5, 1, 1, 24.99);

/* Update totals from items */
UPDATE orders o
JOIN (
  SELECT order_id, ROUND(SUM(quantity * unit_price), 2) AS total
  FROM order_items
  GROUP BY order_id
) t ON t.order_id = o.id
SET o.total_amount = t.total
WHERE o.id > 0;

/* Inventory events as a starting history */
INSERT INTO inventory_events (product_id, change_amount, reason) VALUES
(1, -2, 'order#1'),
(8, -3, 'order#1'),
(5, -1, 'order#1'),
(2, -1, 'order#2'),
(3, -1, 'order#2'),
(6, -1, 'order#3'),
(10, -2, 'order#3'),
(7, -1, 'order#4'),
(11, -1, 'order#4'),
(1, -1, 'order#5');
