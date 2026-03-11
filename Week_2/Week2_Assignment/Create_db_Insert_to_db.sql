/* ---------------------------------------------------------
   Database After Graduation
   Week 2 Dataset (Replacement Script)
   Creates and populates:
   customers, orders, order_items, products, page_views
   MySQL 8+
   --------------------------------------------------------- */

DROP DATABASE IF EXISTS dag_week2;
CREATE DATABASE dag_week2;
USE dag_week2;

/* ---------------------------
   1) Tables
   --------------------------- */

CREATE TABLE customers (
  customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customers_email (email),
  KEY idx_customers_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sku VARCHAR(64) NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(80) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id),
  UNIQUE KEY uq_products_sku (sku),
  KEY idx_products_category (category),
  KEY idx_products_is_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  order_status ENUM('PENDING','PAID','SHIPPED','CANCELLED','REFUNDED') NOT NULL,
  order_total DECIMAL(12,2) NOT NULL,
  placed_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id),
  KEY idx_orders_customer_id (customer_id),
  KEY idx_orders_status (order_status),
  KEY idx_orders_placed_at (placed_at),
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (order_item_id),
  KEY idx_order_items_order_id (order_id),
  KEY idx_order_items_product_id (product_id),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE page_views (
  page_view_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NULL,
  path VARCHAR(255) NOT NULL,
  viewed_at DATETIME NOT NULL,
  user_agent VARCHAR(255) NULL,
  PRIMARY KEY (page_view_id),
  KEY idx_page_views_viewed_at (viewed_at),
  KEY idx_page_views_customer_id (customer_id),
  KEY idx_page_views_product_id (product_id),
  CONSTRAINT fk_page_views_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_page_views_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

/* ---------------------------
   2) Seed Data
   --------------------------- */
   
SET SESSION cte_max_recursion_depth = 100000;  -- Enough for 90,000 rows


INSERT INTO products (sku, name, category, price, is_active, created_at) VALUES
('SKU-1001','Wireless Mouse','Accessories',19.99,1,NOW() - INTERVAL 200 DAY),
('SKU-1002','Mechanical Keyboard','Accessories',89.99,1,NOW() - INTERVAL 180 DAY),
('SKU-2001','USB-C Hub','Accessories',34.99,1,NOW() - INTERVAL 160 DAY),
('SKU-3001','Laptop Stand','Office',29.99,1,NOW() - INTERVAL 150 DAY),
('SKU-3002','Desk Lamp','Office',24.99,1,NOW() - INTERVAL 140 DAY),
('SKU-4001','Noise Cancelling Headphones','Audio',149.99,1,NOW() - INTERVAL 130 DAY),
('SKU-4002','Bluetooth Speaker','Audio',59.99,1,NOW() - INTERVAL 120 DAY),
('SKU-5001','Webcam 1080p','Video',39.99,1,NOW() - INTERVAL 110 DAY),
('SKU-6001','External SSD 1TB','Storage',129.99,1,NOW() - INTERVAL 100 DAY),
('SKU-6002','External HDD 2TB','Storage',79.99,1,NOW() - INTERVAL 90 DAY),
('SKU-7001','Smartwatch','Wearables',199.99,1,NOW() - INTERVAL 80 DAY),
('SKU-8001','Phone Charger','Mobile',14.99,1,NOW() - INTERVAL 70 DAY),
('SKU-8002','Power Bank','Mobile',29.99,1,NOW() - INTERVAL 60 DAY),
('SKU-9001','Monitor 27-inch','Displays',229.99,1,NOW() - INTERVAL 50 DAY),
('SKU-9002','HDMI Cable','Displays',9.99,1,NOW() - INTERVAL 40 DAY);

INSERT INTO customers (email, first_name, last_name, created_at) VALUES
('alice@example.com','Alice','Nguyen',NOW() - INTERVAL 300 DAY),
('bob@example.com','Bob','Singh',NOW() - INTERVAL 250 DAY),
('carol@example.com','Carol','Martin',NOW() - INTERVAL 220 DAY),
('dave@example.com','Dave','Chen',NOW() - INTERVAL 200 DAY),
('eve@example.com','Eve','Johnson',NOW() - INTERVAL 180 DAY),
('farah@example.com','Farah','Yousefi',NOW() - INTERVAL 160 DAY),
('hassan@example.com','Hassan','Karimi',NOW() - INTERVAL 140 DAY),
('ivan@example.com','Ivan','Petrov',NOW() - INTERVAL 120 DAY),
('julia@example.com','Julia','Wong',NOW() - INTERVAL 100 DAY),
('karen@example.com','Karen','Brown',NOW() - INTERVAL 90 DAY);

/* ---------------------------
   3) Bulk-ish Data Generation
   Uses a recursive CTE to generate numbers
   --------------------------- */

-- Insert additional customers using recursive CTE
INSERT INTO customers (email, first_name, last_name, created_at)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 2000
)
SELECT
  CONCAT('user', n, '@example.com') AS email,
  CONCAT('First', n) AS first_name,
  CONCAT('Last', n) AS last_name,
  NOW() - INTERVAL (300 - (n % 300)) DAY AS created_at
FROM seq;

-- Insert orders using recursive CTE
INSERT INTO orders (customer_id, order_status, order_total, placed_at)
WITH RECURSIVE seq2 AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq2 WHERE n < 30000
)
SELECT
  (n % 2010) + 1 AS customer_id,
  CASE
    WHEN n % 20 IN (0,1,2,3,4,5,6,7) THEN 'PAID'
    WHEN n % 20 IN (8,9,10,11,12) THEN 'SHIPPED'
    WHEN n % 20 IN (13,14) THEN 'PENDING'
    WHEN n % 20 IN (15,16,17) THEN 'CANCELLED'
    ELSE 'REFUNDED'
  END AS order_status,
  ROUND( (10 + (n % 400)) + (RAND() * 20), 2 ) AS order_total,
  NOW() - INTERVAL (n % 30) DAY - INTERVAL (n % 1440) MINUTE AS placed_at
FROM seq2;

-- Insert order items using recursive CTE
INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
WITH RECURSIVE seq3 AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq3 WHERE n < 90000
)
SELECT
  (n % 30000) + 1 AS order_id,
  (n % 15) + 1 AS product_id,
  (n % 3) + 1 AS quantity,
  (SELECT price FROM products WHERE product_id = ((n % 15) + 1)) AS unit_price,
  ROUND(
    ((n % 3) + 1) * (SELECT price FROM products WHERE product_id = ((n % 15) + 1)),
    2
  ) AS line_total
FROM seq3;

-- Insert page views using recursive CTE
INSERT INTO page_views (customer_id, product_id, path, viewed_at, user_agent)
WITH RECURSIVE seq4 AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq4 WHERE n < 60000
)
SELECT
  CASE WHEN n % 10 = 0 THEN NULL ELSE (n % 2010) + 1 END AS customer_id,
  CASE WHEN n % 7 = 0 THEN NULL ELSE (n % 15) + 1 END AS product_id,
  CASE
    WHEN n % 5 = 0 THEN '/home'
    WHEN n % 5 = 1 THEN '/search'
    WHEN n % 5 = 2 THEN '/product'
    WHEN n % 5 = 3 THEN '/cart'
    ELSE '/checkout'
  END AS path,
  NOW() - INTERVAL (n % 14) DAY - INTERVAL (n % 1440) MINUTE AS viewed_at,
  'Mozilla/5.0' AS user_agent
FROM seq4;

/* ---------------------------
   4) Recommended optimizer stats
   --------------------------- */

ANALYZE TABLE orders;
ANALYZE TABLE order_items;
ANALYZE TABLE products;
ANALYZE TABLE customers;
ANALYZE TABLE page_views;

/* Quick sanity checks */
SELECT COUNT(*) AS customers_cnt FROM customers;
SELECT COUNT(*) AS orders_cnt FROM orders;
SELECT COUNT(*) AS order_items_cnt FROM order_items;
SELECT COUNT(*) AS products_cnt FROM products;
SELECT COUNT(*) AS page_views_cnt FROM page_views;