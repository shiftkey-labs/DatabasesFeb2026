DROP TABLE IF EXISTS orders_no_idx;
DROP TABLE IF EXISTS orders_with_idx;

CREATE TABLE orders_no_idx (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    status VARCHAR(20),
    total DECIMAL(10,2),
    created_at DATETIME
);

CREATE TABLE orders_with_idx (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    status VARCHAR(20),
    total DECIMAL(10,2),
    created_at DATETIME
);

CREATE INDEX idx_user_id ON orders_with_idx(user_id);
CREATE INDEX idx_status ON orders_with_idx(status);
CREATE INDEX idx_created_at ON orders_with_idx(created_at);
CREATE INDEX idx_user_status_created ON orders_with_idx(user_id, status, created_at);


DELIMITER //

CREATE PROCEDURE bulk_insert(IN target_table VARCHAR(64), IN n INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    SET @sql = CONCAT(
        'INSERT INTO ', target_table, ' (user_id, status, total, created_at) VALUES (?, ?, ?, ?)'
    );

    PREPARE stmt FROM @sql;

    WHILE i <= n DO
        SET @uid = FLOOR(1 + RAND()*1000);
        SET @st = IF(RAND() > 0.5, 'completed', 'pending');
        SET @tot = RAND()*500;
        SET @dt = NOW() - INTERVAL FLOOR(RAND()*365) DAY;

        EXECUTE stmt USING @uid, @st, @tot, @dt;
        SET i = i + 1;
    END WHILE;

    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;
-- -------------------------------- no index table + write ------------

SET profiling = 1;
SET profiling_history_size = 2000;


CALL bulk_insert('orders_no_idx', 30000);
SHOW PROFILES;

SET @t0 = NOW(6);
CALL bulk_insert('orders_with_idx', 30000);
SET @t1 = NOW(6);


SELECT TIMESTAMPDIFF(MICROSECOND, @t0, @t1)/1000000 AS seconds;

-- --------------------------------------Index effect + Write--------------
SET profiling = 1;

CALL bulk_insert('orders_with_idx', 30000);

SHOW PROFILES;
