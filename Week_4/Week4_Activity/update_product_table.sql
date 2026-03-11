use prod_sql_week2;
ALTER TABLE products
ADD COLUMN stock INT NOT NULL DEFAULT 0;
SET SQL_SAFE_UPDATES = 0;

UPDATE products 
SET stock = CASE 
    WHEN RAND() < 0.3 THEN FLOOR(1 + RAND() * 10)    -- 30% chance: low stock (1-10)
    WHEN RAND() < 0.6 THEN FLOOR(11 + RAND() * 40)   -- 30% chance: medium stock (11-50)
    ELSE FLOOR(51 + RAND() * 450)                     -- 40% chance: high stock (51-500)
END;

select * from products;