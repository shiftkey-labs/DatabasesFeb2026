CREATE DATABASE week2_demo;
USE week2_demo;

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    status VARCHAR(20),
    total DECIMAL(10,2),
    created_at DATETIME
);
-- -------------------- insert data------------ 
DELIMITER //

CREATE PROCEDURE insert_orders()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 100000 DO
        INSERT INTO orders (user_id, status, total, created_at)
        VALUES (
            FLOOR(1 + RAND()*1000),
            IF(RAND() > 0.5, 'completed', 'pending'),
            RAND()*500,
            NOW() - INTERVAL FLOOR(RAND()*365) DAY
        );
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;
-- ----------------------------------check Index effect --------------------- 
CALL insert_orders();

EXPLAIN SELECT * FROM orders WHERE user_id = 42;


CREATE INDEX idx_user_id ON orders(user_id);

EXPLAIN SELECT * FROM orders WHERE user_id = 42;
SELECT * FROM orders WHERE user_id = 42;

-- ----------------------------------check Composite Index effect --------------------- 

EXPLAIN 
SELECT * 
FROM orders 
WHERE user_id = 42 
AND status = 'completed' and total> 10;

CREATE INDEX idx_user_status ON orders(user_id, status);

EXPLAIN 
SELECT * 
FROM orders 
WHERE user_id = 42 
AND status = 'completed';
-- ---------------- one more sample (be carefull about the year()function )   ---------------

EXPLAIN 
SELECT * 
FROM orders 
WHERE YEAR(created_at) = 2024;

CREATE INDEX idx_created_at ON orders(created_at);

EXPLAIN 
SELECT * 
FROM orders 
WHERE created_at >= '2024-01-01'
AND created_at < '2025-01-01';
-- ------------------------------------------------




