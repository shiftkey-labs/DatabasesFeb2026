-- Helper numbers table to generate rows quickly
DROP DATABASE IF EXISTS prod_sql_week2;
CREATE DATABASE prod_sql_week2;
USE prod_sql_week2;

-- Customers
CREATE TABLE customers (
  customer_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  country_code CHAR(2) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customers_email (email),
  KEY idx_customers_country_created (country_code, created_at)
);

-- Products
CREATE TABLE products (
  product_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  sku VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(80) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_products_sku (sku),
  KEY idx_products_category_price (category, price),
  KEY idx_products_active_category (is_active, category)
);

-- Orders
CREATE TABLE orders (
  order_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id BIGINT NOT NULL,
  order_status ENUM('NEW','PAID','SHIPPED','CANCELLED','REFUNDED') NOT NULL,
  order_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  placed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  KEY idx_orders_customer_placed (customer_id, placed_at),
  KEY idx_orders_status_placed (order_status, placed_at)
);

-- Order items
CREATE TABLE order_items (
  order_item_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  KEY idx_items_order (order_id),
  KEY idx_items_product (product_id)
);

-- Page views (write heavy table)
CREATE TABLE page_views (
  view_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id BIGINT NULL,
  product_id BIGINT NULL,
  path VARCHAR(255) NOT NULL,
  viewed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pv_viewed_at (viewed_at),
  KEY idx_pv_product_viewed (product_id, viewed_at),
  KEY idx_pv_customer_viewed (customer_id, viewed_at)
);


SET GLOBAL cte_max_recursion_depth = 6000;

DROP TABLE IF EXISTS nums;
CREATE TABLE nums (n INT PRIMARY KEY);

INSERT INTO nums(n)
WITH RECURSIVE cte AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM cte WHERE n < 5000
)
SELECT n FROM cte;



-- 2000 customers
INSERT INTO customers(email, full_name, country_code, created_at)
SELECT
  CONCAT('user', n, '@example.com'),
  CONCAT('User ', n),
  ELT(1 + (n % 6), 'CA','US','GB','DE','FR','AU'),
  NOW() - INTERVAL (n % 365) DAY
FROM nums
WHERE n <= 2000;

-- 800 products
INSERT INTO products(sku, name, category, price, is_active, created_at)
SELECT
  CONCAT('SKU-', LPAD(n, 5, '0')),
  CONCAT('Product ', n),
  ELT(1 + (n % 8), 'laptop','phone','camera','audio','gaming','home','books','sports'),
  ROUND(10 + (n % 500) * 1.37, 2),
  IF(n % 12 = 0, 0, 1),
  NOW() - INTERVAL (n % 180) DAY
FROM nums
WHERE n <= 800;

-- 9000 orders
INSERT INTO orders(customer_id, order_status, order_total, placed_at)
SELECT
  1 + (n % 2000),
  ELT(1 + (n % 5), 'NEW','PAID','SHIPPED','CANCELLED','REFUNDED'),
  0.00,
  NOW() - INTERVAL (n % 120) DAY
FROM nums
WHERE n <= 9000;


INSERT INTO order_items(order_id, product_id, quantity, unit_price)
SELECT
  o.order_id,
  1 + (n.n % 800) AS product_id,
  1 + (n.n % 4) AS quantity,
  (SELECT p.price FROM products p WHERE p.product_id = 1 + (n.n % 800)) AS unit_price
FROM orders o
JOIN nums n ON n.n <= 3
WHERE o.order_id <= 9000;


-- Update order totals based on items
UPDATE orders o
JOIN (
  SELECT order_id, SUM(quantity * unit_price) AS total
  FROM order_items
  GROUP BY order_id
) x ON x.order_id = o.order_id
SET o.order_total = x.total;

-- 20000 page views (write heavy events)
INSERT INTO page_views(customer_id, product_id, path, viewed_at)
SELECT
  IF(n % 5 = 0, NULL, 1 + (n % 2000)),
  IF(n % 4 = 0, NULL, 1 + (n % 800)),
  ELT(1 + (n % 5), '/home','/search','/product','/cart','/checkout'),
  NOW() - INTERVAL (n % 72) HOUR
FROM nums
WHERE n <= 20000;
