/** Schéma Neon des immobilisations (miroir de prisma/migrations/add_compta_immobilisations). Idempotent. */
module.exports = `
CREATE TABLE IF NOT EXISTS "compta_immobilisations" (
    "id" SERIAL NOT NULL,
    "libelle" TEXT NOT NULL,
    "compte_numero" TEXT NOT NULL,
    "compte_amort_numero" TEXT NOT NULL,
    "compte_dotation_numero" TEXT NOT NULL DEFAULT '681',
    "date_acquisition" TIMESTAMP(3) NOT NULL,
    "valeur" INTEGER NOT NULL,
    "valeur_residuelle" INTEGER NOT NULL DEFAULT 0,
    "duree_mois" INTEGER NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'en_service',
    "date_cession" TIMESTAMP(3),
    "prix_cession" INTEGER,
    "boutique_id" INTEGER,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_immobilisations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "idx_compta_immobilisations_statut" ON "compta_immobilisations"("statut");
`;
