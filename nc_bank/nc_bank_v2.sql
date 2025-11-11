-- ============================================
-- NorthCounty Bank - Système Bancaire Complet
-- Version 2.0 - Comptes Personnel & Entreprise
-- ============================================

-- Table des comptes bancaires personnels
CREATE TABLE IF NOT EXISTS `nc_bank_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `iban` VARCHAR(34) NOT NULL UNIQUE,
    `pin_code` VARCHAR(4) NOT NULL,
    `account_type` ENUM('personal', 'business') NOT NULL DEFAULT 'personal',
    `account_name` VARCHAR(100) NULL,
    `balance` INT(11) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_activity` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `iban` (`iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des comptes entreprise
CREATE TABLE IF NOT EXISTS `nc_business_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `account_id` INT(11) NOT NULL,
    `business_name` VARCHAR(100) NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `owner_identifier` VARCHAR(60) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `account_id` (`account_id`),
    KEY `job_name` (`job_name`),
    FOREIGN KEY (`account_id`) REFERENCES `nc_bank_accounts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des employés (pour gestion salaires)
CREATE TABLE IF NOT EXISTS `nc_business_employees` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `business_account_id` INT(11) NOT NULL,
    `employee_identifier` VARCHAR(60) NOT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `job_grade` INT(11) NOT NULL DEFAULT 0,
    `job_grade_name` VARCHAR(50) NOT NULL,
    `salary` INT(11) NOT NULL DEFAULT 0,
    `last_payment` TIMESTAMP NULL DEFAULT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `business_account_id` (`business_account_id`),
    KEY `employee_identifier` (`employee_identifier`),
    FOREIGN KEY (`business_account_id`) REFERENCES `nc_business_accounts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des transactions (améliorée)
CREATE TABLE IF NOT EXISTS `nc_bank_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `account_id` INT(11) NOT NULL,
    `transaction_type` ENUM('deposit', 'withdraw', 'transfer_sent', 'transfer_received', 'salary_paid', 'salary_received', 'interest') NOT NULL,
    `amount` INT(11) NOT NULL,
    `balance_before` INT(11) NOT NULL,
    `balance_after` INT(11) NOT NULL,
    `target_iban` VARCHAR(34) NULL DEFAULT NULL,
    `source_iban` VARCHAR(34) NULL DEFAULT NULL,
    `description` VARCHAR(255) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `account_id` (`account_id`),
    KEY `created_at` (`created_at`),
    KEY `transaction_type` (`transaction_type`),
    FOREIGN KEY (`account_id`) REFERENCES `nc_bank_accounts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des cartes bancaires
CREATE TABLE IF NOT EXISTS `nc_bank_cards` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `account_id` INT(11) NOT NULL,
    `card_number` VARCHAR(16) NOT NULL UNIQUE,
    `cvv` VARCHAR(3) NOT NULL,
    `expiry_date` VARCHAR(5) NOT NULL,
    `card_type` ENUM('debit', 'credit') NOT NULL DEFAULT 'debit',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `account_id` (`account_id`),
    KEY `card_number` (`card_number`),
    FOREIGN KEY (`account_id`) REFERENCES `nc_bank_accounts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des comptes d'épargne (conservée de l'ancien système)
CREATE TABLE IF NOT EXISTS `nc_savings_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `account_id` INT(11) NOT NULL,
    `account_name` VARCHAR(100) NOT NULL DEFAULT 'Compte Épargne',
    `balance` INT(11) NOT NULL DEFAULT 0,
    `interest_rate` DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_interest` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `account_id` (`account_id`),
    FOREIGN KEY (`account_id`) REFERENCES `nc_bank_accounts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vue pour les statistiques
CREATE OR REPLACE VIEW `nc_bank_stats` AS
SELECT
    a.identifier,
    a.iban,
    a.account_type,
    COUNT(t.id) as total_transactions,
    SUM(CASE WHEN t.transaction_type = 'deposit' THEN t.amount ELSE 0 END) as total_deposits,
    SUM(CASE WHEN t.transaction_type = 'withdraw' THEN t.amount ELSE 0 END) as total_withdrawals,
    SUM(CASE WHEN t.transaction_type = 'transfer_sent' THEN t.amount ELSE 0 END) as total_transfers_sent,
    SUM(CASE WHEN t.transaction_type = 'transfer_received' THEN t.amount ELSE 0 END) as total_transfers_received
FROM `nc_bank_accounts` a
LEFT JOIN `nc_bank_transactions` t ON a.id = t.account_id
GROUP BY a.id, a.identifier, a.iban, a.account_type;

-- ============================================
-- MIGRATION : Si vous aviez l'ancienne version
-- ============================================

-- Supprimer les anciennes tables si elles existent
-- DROP TABLE IF EXISTS `nc_pending_transfers`;
-- DROP TABLE IF EXISTS `nc_bank_transactions_old`;

-- ============================================
-- Procédure pour générer un IBAN unique
-- ============================================

DELIMITER //

CREATE FUNCTION IF NOT EXISTS `generate_iban`()
RETURNS VARCHAR(34)
DETERMINISTIC
BEGIN
    DECLARE new_iban VARCHAR(34);
    DECLARE iban_exists INT;

    REPEAT
        SET new_iban = CONCAT(
            'NC',
            LPAD(FLOOR(RAND() * 100), 2, '0'),
            LPAD(FLOOR(RAND() * 10000), 4, '0'),
            LPAD(FLOOR(RAND() * 10000), 4, '0'),
            LPAD(FLOOR(RAND() * 10000), 4, '0'),
            LPAD(FLOOR(RAND() * 10000), 4, '0'),
            LPAD(FLOOR(RAND() * 10000), 4, '0')
        );

        SELECT COUNT(*) INTO iban_exists
        FROM nc_bank_accounts
        WHERE iban = new_iban;

    UNTIL iban_exists = 0 END REPEAT;

    RETURN new_iban;
END//

DELIMITER ;

-- ============================================
-- Index pour optimiser les performances
-- ============================================

CREATE INDEX idx_transactions_date ON nc_bank_transactions(created_at DESC);
CREATE INDEX idx_transactions_amount ON nc_bank_transactions(amount);
CREATE INDEX idx_accounts_type ON nc_bank_accounts(account_type);
CREATE INDEX idx_employees_payment ON nc_business_employees(last_payment);
