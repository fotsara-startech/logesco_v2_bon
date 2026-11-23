-- Comptabilité SYSCOHADA (phase 4) : registre des immobilisations amortissables.
CREATE TABLE IF NOT EXISTS "compta_immobilisations" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "libelle" TEXT NOT NULL,
    "compte_numero" TEXT NOT NULL,
    "compte_amort_numero" TEXT NOT NULL,
    "compte_dotation_numero" TEXT NOT NULL DEFAULT '681',
    "date_acquisition" DATETIME NOT NULL,
    "valeur" INTEGER NOT NULL,
    "valeur_residuelle" INTEGER NOT NULL DEFAULT 0,
    "duree_mois" INTEGER NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'en_service',
    "date_cession" DATETIME,
    "prix_cession" INTEGER,
    "boutique_id" INTEGER,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "idx_compta_immobilisations_statut" ON "compta_immobilisations"("statut");
