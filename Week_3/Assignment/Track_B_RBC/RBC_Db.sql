/* =========================================================
   Track B: RBC Mini Banking Backend
   Schema + Seed Data (MySQL 8+)
   ========================================================= */

DROP DATABASE IF EXISTS rbc_banking_week3;
CREATE DATABASE rbc_banking_week3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rbc_banking_week3;

/* -------------------------
   Tables
   ------------------------- */

CREATE TABLE customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(140) NOT NULL,
  email VARCHAR(180) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_email (email),
  KEY idx_customers_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  account_type ENUM('checking','savings') NOT NULL,
  balance DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  status ENUM('active','frozen') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_accounts_customer (customer_id),
  KEY idx_accounts_status_type (status, account_type),
  KEY idx_accounts_created_at_id (created_at, id),
  CONSTRAINT fk_accounts_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transfers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  from_account_id BIGINT UNSIGNED NOT NULL,
  to_account_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  status ENUM('created','completed','failed') NOT NULL DEFAULT 'created',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_transfers_created_at_id (created_at, id),
  KEY idx_transfers_from_created (from_account_id, created_at),
  KEY idx_transfers_to_created (to_account_id, created_at),
  CONSTRAINT fk_transfers_from_account
    FOREIGN KEY (from_account_id) REFERENCES accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_transfers_to_account
    FOREIGN KEY (to_account_id) REFERENCES accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_transfer_positive_amount
    CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE ledger_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  transfer_id BIGINT UNSIGNED NULL,
  entry_type ENUM('credit','debit') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  description VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ledger_account_created (account_id, created_at, id),
  KEY idx_ledger_transfer (transfer_id),
  CONSTRAINT fk_ledger_account
    FOREIGN KEY (account_id) REFERENCES accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ledger_transfer
    FOREIGN KEY (transfer_id) REFERENCES transfers(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_ledger_positive_amount
    CHECK (amount > 0)
) ENGINE=InnoDB;

/* -------------------------
   Seed Data
   ------------------------- */

INSERT INTO customers (full_name, email) VALUES
('Amir Rezaei', 'amir.rezaei@example.com'),
('Charlotte Nguyen', 'charlotte.nguyen@example.com'),
('Daniel O''Connor', 'daniel.oconnor@example.com'),
('Priya Singh', 'priya.singh@example.com'),
('Lucas Martin', 'lucas.martin@example.com'),
('Fatima Ali', 'fatima.ali@example.com'),
('Henry Zhao', 'henry.zhao@example.com'),
('Emma Thompson', 'emma.thompson@example.com');

INSERT INTO accounts (customer_id, account_type, balance, status) VALUES
(1, 'checking', 2500.00, 'active'),
(1, 'savings',  8000.00, 'active'),
(2, 'checking', 1200.00, 'active'),
(2, 'savings',  3000.00, 'active'),
(3, 'checking', 400.00,  'active'),
(4, 'checking', 950.00,  'active'),
(5, 'savings',  15000.00,'active'),
(6, 'checking', 100.00,  'frozen'),
(7, 'checking', 2200.00, 'active'),
(8, 'savings',  500.00,  'active');

/* Create a few completed transfers */
INSERT INTO transfers (from_account_id, to_account_id, amount, status) VALUES
(1, 3, 150.00, 'completed'),
(3, 4, 200.00, 'completed'),
(2, 5, 500.00, 'completed'),
(4, 7, 1000.00, 'completed'),
(9, 10, 75.50, 'completed');

/* Ledger entries for each transfer */
INSERT INTO ledger_entries (account_id, transfer_id, entry_type, amount, description) VALUES
(1, 1, 'debit',  150.00, 'Transfer to account#3'),
(3, 1, 'credit', 150.00, 'Transfer from account#1'),

(3, 2, 'debit',  200.00, 'Transfer to account#4'),
(4, 2, 'credit', 200.00, 'Transfer from account#3'),

(2, 3, 'debit',  500.00, 'Transfer to account#5'),
(5, 3, 'credit', 500.00, 'Transfer from account#2'),

(4, 4, 'debit',  1000.00, 'Transfer to account#7'),
(7, 4, 'credit', 1000.00, 'Transfer from account#4'),

(9, 5, 'debit',  75.50, 'Transfer to account#10'),
(10,5, 'credit', 75.50, 'Transfer from account#9');

/* Optional: also adjust balances to match completed transfers (makes data consistent) */
UPDATE accounts SET balance = balance - 150.00 WHERE id = 1;
UPDATE accounts SET balance = balance + 150.00 WHERE id = 3;

UPDATE accounts SET balance = balance - 200.00 WHERE id = 3;
UPDATE accounts SET balance = balance + 200.00 WHERE id = 4;

UPDATE accounts SET balance = balance - 500.00 WHERE id = 2;
UPDATE accounts SET balance = balance + 500.00 WHERE id = 5;

UPDATE accounts SET balance = balance - 1000.00 WHERE id = 4;
UPDATE accounts SET balance = balance + 1000.00 WHERE id = 7;

UPDATE accounts SET balance = balance - 75.50 WHERE id = 9;
UPDATE accounts SET balance = balance + 75.50 WHERE id = 10;

/* Add some extra ledger activity for analytics */
INSERT INTO ledger_entries (account_id, transfer_id, entry_type, amount, description) VALUES
(1, NULL, 'debit',  40.00, 'Coffee shop'),
(1, NULL, 'debit',  120.00,'Grocery'),
(3, NULL, 'credit', 900.00,'Paycheque'),
(4, NULL, 'debit',  60.00, 'Subscription'),
(7, NULL, 'debit',  35.00, 'Transit pass'),
(9, NULL, 'credit', 300.00,'Refund'),
(10,NULL, 'debit',  15.00, 'Online purchase');