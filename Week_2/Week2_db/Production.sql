/* ============================================================
   WEEK 2 – Production SQL & Query Execution Demo
   Databases After Graduation
   ============================================================

   This script demonstrates:
   - Writing production-level SQL
   - Query refactoring
   - EXPLAIN analysis
   - Index optimization
   - Pagination patterns
   - Read-heavy vs write-heavy trade-offs

   Before running:
   1) Execute Create_db_Insert_to_db.sql from Week 2 material.
   2) Make sure all tables (customers, orders, products, etc.)
      are created and populated.
   ============================================================ */


/* ============================================================
   SECTION A: TOP CUSTOMERS BY REVENUE (LAST 30 DAYS)
   ============================================================ */

/* ------------------------------------------------------------
   Version 1 – Correct but heavier than necessary
   Joins customers early before aggregation
   ------------------------------------------------------------ */

EXPLAIN
SELECT c.customer_id, c.email, SUM(o.order_total) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.placed_at >= NOW() - INTERVAL 30 DAY
  AND o.order_status IN ('PAID','SHIPPED')
GROUP BY c.customer_id, c.email
ORDER BY revenue DESC
LIMIT 20;


/* ------------------------------------------------------------
   Version 2 – Better: Filter and aggregate first
   Avoids unnecessary join until needed
   ------------------------------------------------------------ */

EXPLAIN
SELECT o.customer_id, SUM(o.order_total) AS revenue
FROM orders o
WHERE o.placed_at >= NOW() - INTERVAL 30 DAY
  AND o.order_status IN ('PAID','SHIPPED')
GROUP BY o.customer_id
ORDER BY revenue DESC
LIMIT 20;


/* ------------------------------------------------------------
   Final Version – Join only top 20 customers
   ------------------------------------------------------------ */

EXPLAIN
SELECT c.customer_id, c.email, t.revenue
FROM (
  SELECT o.customer_id, SUM(o.order_total) AS revenue
  FROM orders o
  WHERE o.placed_at >= NOW() - INTERVAL 30 DAY
    AND o.order_status IN ('PAID','SHIPPED')
  GROUP BY o.customer_id
  ORDER BY revenue DESC
  LIMIT 20
) t
JOIN customers c ON c.customer_id = t.customer_id
ORDER BY t.revenue DESC;


/* ------------------------------------------------------------
   Index optimization for this query pattern
   Supports WHERE + GROUP BY
   ------------------------------------------------------------ */

CREATE INDEX idx_orders_status_placed_customer
ON orders(order_status, placed_at, customer_id);



/* ============================================================
   SECTION B: CUSTOMERS WHO BOUGHT X BUT NOT Y
   ============================================================ */

/* ------------------------------------------------------------
   Version 1 – Using NOT IN (can behave badly with NULLs)
   ------------------------------------------------------------ */

EXPLAIN
SELECT DISTINCT o.customer_id
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('PAID','SHIPPED')
  AND p.category = 'phone'
  AND o.customer_id NOT IN (
    SELECT o2.customer_id
    FROM orders o2
    JOIN order_items oi2 ON oi2.order_id = o2.order_id
    JOIN products p2 ON p2.product_id = oi2.product_id
    WHERE o2.order_status IN ('PAID','SHIPPED')
      AND p2.category = 'laptop'
  );


/* ------------------------------------------------------------
   Production version – Using NOT EXISTS
   More reliable and usually more efficient
   ------------------------------------------------------------ */

EXPLAIN
SELECT DISTINCT o.customer_id
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('PAID','SHIPPED')
  AND p.category = 'phone'
  AND NOT EXISTS (
    SELECT 1
    FROM orders o2
    JOIN order_items oi2 ON oi2.order_id = o2.order_id
    JOIN products p2 ON p2.product_id = oi2.product_id
    WHERE o2.customer_id = o.customer_id
      AND o2.order_status IN ('PAID','SHIPPED')
      AND p2.category = 'laptop'
  );


/* ------------------------------------------------------------
   Index support for this pattern
   Helps joins and filtering
   ------------------------------------------------------------ */

CREATE INDEX idx_products_category_id
ON products(category, product_id);

CREATE INDEX idx_orders_customer_status
ON orders(customer_id, order_status, order_id);

CREATE INDEX idx_items_order_product
ON order_items(order_id, product_id);



/* ============================================================
   SECTION C: SEARCH ENDPOINT + PAGINATION
   ============================================================ */

/* ------------------------------------------------------------
   BAD pattern – OFFSET gets expensive at large pages
   ------------------------------------------------------------ */

EXPLAIN
SELECT product_id, name, price
FROM products
WHERE is_active = 1
  AND category = 'phone'
ORDER BY price ASC
LIMIT 20 OFFSET 400;


/* ------------------------------------------------------------
   Production pattern – Keyset pagination
   Avoids scanning skipped rows
   ------------------------------------------------------------ */

/* Assume last_seen_price = 199.99
   Assume last_seen_id = 120 */

EXPLAIN
SELECT product_id, name, price
FROM products
WHERE is_active = 1
  AND category = 'phone'
  AND (price > 199.99
       OR (price = 199.99 AND product_id > 120))
ORDER BY price ASC, product_id ASC
LIMIT 20;


/* ------------------------------------------------------------
   Supporting index for keyset pagination
   ------------------------------------------------------------ */

CREATE INDEX idx_products_active_cat_price_id
ON products(is_active, category, price, product_id);



/* ============================================================
   SECTION D: EXECUTION PLAN ANALYSIS
   ============================================================ */

/* ------------------------------------------------------------
   Simple ordered query – observe type, key, rows, Extra
   ------------------------------------------------------------ */

EXPLAIN FORMAT=TRADITIONAL
SELECT o.order_id, o.placed_at, o.order_total
FROM orders o
WHERE o.customer_id = 123
ORDER BY o.placed_at DESC
LIMIT 10;


/* ------------------------------------------------------------
   Force a filesort situation
   No composite index for (order_status, order_total)
   ------------------------------------------------------------ */

EXPLAIN
SELECT *
FROM orders
WHERE order_status = 'PAID'
ORDER BY order_total DESC
LIMIT 20;


/* ------------------------------------------------------------
   Fix filesort using composite index
   ------------------------------------------------------------ */

CREATE INDEX idx_orders_status_total
ON orders(order_status, order_total);



/* ============================================================
   SECTION E: READ-HEAVY VS WRITE-HEAVY TRADE-OFF
   ============================================================ */

/* ------------------------------------------------------------
   Baseline insert into write-heavy table
   ------------------------------------------------------------ */

INSERT INTO page_views(customer_id, product_id, path, viewed_at)
VALUES (10, 20, '/product', NOW());


/* ------------------------------------------------------------
   Add additional index (simulating over-indexing)
   ------------------------------------------------------------ */

CREATE INDEX idx_pv_path_viewed
ON page_views(path, viewed_at);


/* ------------------------------------------------------------
   Insert many rows to observe write cost
   Assumes a helper table "nums" exists with column n
   ------------------------------------------------------------ */

INSERT INTO page_views(customer_id, product_id, path, viewed_at)
SELECT
  1 + (n % 2000),
  1 + (n % 800),
  '/search',
  NOW() - INTERVAL (n % 10) MINUTE
FROM nums
WHERE n <= 3000;


/* ============================================================
   SECTION F: STUDENT PRACTICE QUERIES
   ============================================================ */

/* Top 10 customers by revenue last 14 days (only SHIPPED) */

SELECT customer_id, SUM(order_total) AS revenue
FROM orders
WHERE placed_at >= NOW() - INTERVAL 14 DAY
  AND order_status = 'SHIPPED'
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 10;


/* Customers who viewed product pages but never purchased */

SELECT DISTINCT pv.customer_id
FROM page_views pv
WHERE pv.customer_id IS NOT NULL
  AND pv.path = '/product'
  AND NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = pv.customer_id
      AND o.order_status IN ('PAID','SHIPPED')
  );


/* ============================================================
   END OF WEEK 2 PRODUCTION SQL DEMO
   ============================================================ */
