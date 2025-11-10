-- Script SQL pour NorthCounty Bank System
-- Installation: Importer ce fichier dans votre base de données

-- Table des comptes d'épargne
CREATE TABLE IF NOT EXISTS `nc_savings_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `account_name` VARCHAR(100) NOT NULL DEFAULT 'Compte Épargne',
    `balance` INT(11) NOT NULL DEFAULT 0,
    `interest_rate` DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_interest` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table de l'historique des transactions
CREATE TABLE IF NOT EXISTS `nc_bank_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `transaction_type` ENUM('deposit', 'withdraw', 'transfer_sent', 'transfer_received', 'interest', 'savings_deposit', 'savings_withdraw') NOT NULL,
    `amount` INT(11) NOT NULL,
    `balance_before` INT(11) NOT NULL,
    `balance_after` INT(11) NOT NULL,
    `receiver` VARCHAR(60) NULL DEFAULT NULL,
    `sender` VARCHAR(60) NULL DEFAULT NULL,
    `description` VARCHAR(255) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des virements en attente (pour le téléphone)
CREATE TABLE IF NOT EXISTS `nc_pending_transfers` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `sender` VARCHAR(60) NOT NULL,
    `receiver` VARCHAR(60) NOT NULL,
    `amount` INT(11) NOT NULL,
    `message` VARCHAR(255) NULL DEFAULT NULL,
    `status` ENUM('pending', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `sender` (`sender`),
    KEY `receiver` (`receiver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ajouter un index sur la table users d'ESX si pas déjà présent (optionnel mais recommandé)
-- ALTER TABLE `users` ADD INDEX IF NOT EXISTS `identifier` (`identifier`);

-- Vue pour les statistiques (optionnel)
CREATE OR REPLACE VIEW `nc_bank_stats` AS
SELECT
    identifier,
    COUNT(*) as total_transactions,
    SUM(CASE WHEN transaction_type = 'deposit' THEN amount ELSE 0 END) as total_deposits,
    SUM(CASE WHEN transaction_type = 'withdraw' THEN amount ELSE 0 END) as total_withdrawals,
    SUM(CASE WHEN transaction_type = 'transfer_sent' THEN amount ELSE 0 END) as total_transfers_sent,
    SUM(CASE WHEN transaction_type = 'transfer_received' THEN amount ELSE 0 END) as total_transfers_received,
    SUM(CASE WHEN transaction_type = 'interest' THEN amount ELSE 0 END) as total_interests
FROM `nc_bank_transactions`
GROUP BY identifier;
