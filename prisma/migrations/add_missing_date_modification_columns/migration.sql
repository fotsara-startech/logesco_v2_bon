-- Ajoute les colonnes date_modification déclarées dans schema.prisma mais
-- jamais capturées dans une migration formelle (elles n'existaient que dans
-- le correctif ad-hoc _runProductionMigrations() de server.js).
-- Migration ré-écrite ici pour devenir la source unique de vérité utilisée
-- par le migration-runner.

ALTER TABLE historique_prix_achat ADD COLUMN date_modification DATETIME;
UPDATE historique_prix_achat SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
CREATE INDEX IF NOT EXISTS idx_historique_prix_achat_date_modification ON historique_prix_achat(date_modification);

ALTER TABLE commandes_approvisionnement ADD COLUMN date_modification DATETIME;
UPDATE commandes_approvisionnement SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
CREATE INDEX IF NOT EXISTS idx_commandes_approvisionnement_date_modification ON commandes_approvisionnement(date_modification);

ALTER TABLE details_commandes_approvisionnement ADD COLUMN date_modification DATETIME;
UPDATE details_commandes_approvisionnement SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
CREATE INDEX IF NOT EXISTS idx_details_commandes_date_modification ON details_commandes_approvisionnement(date_modification);

ALTER TABLE ventes ADD COLUMN date_modification DATETIME;
UPDATE ventes SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
CREATE INDEX IF NOT EXISTS idx_ventes_date_modification ON ventes(date_modification);

ALTER TABLE details_ventes ADD COLUMN date_modification DATETIME;
UPDATE details_ventes SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
CREATE INDEX IF NOT EXISTS idx_details_ventes_date_modification ON details_ventes(date_modification);
