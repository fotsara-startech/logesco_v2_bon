-- Ajouter les champs soldeAttendu et ecart à la table cash_sessions
ALTER TABLE `cash_sessions` ADD COLUMN `solde_attendu` REAL;
ALTER TABLE `cash_sessions` ADD COLUMN `ecart` REAL;
