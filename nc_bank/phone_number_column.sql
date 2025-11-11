-- ============================================
-- NC Bank - Ajout colonne phone_number
-- Pour le système de virement par téléphone
-- ============================================

-- Vérifier si la colonne existe déjà
-- Si yseries est déjà installé, cette colonne existe probablement déjà

-- Option 1: Ajouter la colonne si elle n'existe pas (MariaDB 10.0.2+)
ALTER TABLE `users`
ADD COLUMN IF NOT EXISTS `phone_number` VARCHAR(20) DEFAULT NULL;

-- Option 2: Si vous utilisez une version plus ancienne de MySQL/MariaDB
-- Décommentez ces lignes et commentez l'option 1:
/*
SET @dbname = DATABASE();
SET @tablename = "users";
SET @columnname = "phone_number";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE ", @tablename, " ADD ", @columnname, " VARCHAR(20) DEFAULT NULL;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;
*/

-- Ajouter un index pour optimiser la recherche par numéro
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- ============================================
-- IMPORTANT: Vérification yseries
-- ============================================

-- Si vous utilisez yseries, vérifiez comment les numéros de téléphone sont stockés:
-- 1. Certaines versions de yseries utilisent `users.phone_number`
-- 2. D'autres utilisent une table séparée comme `phone_users` ou `yseries_contacts`

-- Pour vérifier où yseries stocke les numéros, exécutez:
-- SHOW TABLES LIKE '%phone%';
-- SHOW TABLES LIKE '%yseries%';

-- Si yseries utilise une table différente, vous devrez modifier la requête SQL
-- dans nc_bank/server/main.lua à la ligne 966
