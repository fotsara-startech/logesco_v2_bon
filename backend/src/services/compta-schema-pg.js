/**
 * Schéma PostgreSQL (Neon) du socle comptable — miroir de
 * prisma/migrations/add_compta_socle (SQLite) et des modèles Compta* de
 * prisma/schema.postgresql.prisma. Idempotent (IF NOT EXISTS) : Neon est
 * partagé par tous les postes, chacun peut rejouer ces instructions.
 */
module.exports = `
CREATE TABLE IF NOT EXISTS "compta_exercices" (
    "id" SERIAL NOT NULL,
    "libelle" TEXT NOT NULL,
    "date_debut" TIMESTAMP(3) NOT NULL,
    "date_fin" TIMESTAMP(3) NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'ouvert',
    "date_cloture" TIMESTAMP(3),
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_exercices_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "compta_periodes" (
    "id" SERIAL NOT NULL,
    "exercice_id" INTEGER NOT NULL,
    "mois" INTEGER NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'ouverte',
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_periodes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "compta_periodes_exercice_id_fkey" FOREIGN KEY ("exercice_id") REFERENCES "compta_exercices"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "compta_comptes" (
    "id" SERIAL NOT NULL,
    "numero" TEXT NOT NULL,
    "libelle" TEXT NOT NULL,
    "classe" INTEGER NOT NULL,
    "nature" TEXT NOT NULL,
    "sens" TEXT,
    "parent_numero" TEXT,
    "est_collectif" BOOLEAN NOT NULL DEFAULT false,
    "lettrable" BOOLEAN NOT NULL DEFAULT false,
    "systeme" BOOLEAN NOT NULL DEFAULT true,
    "actif" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_comptes_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "compta_journaux" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "libelle" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_journaux_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "compta_ecritures" (
    "id" SERIAL NOT NULL,
    "exercice_id" INTEGER NOT NULL,
    "journal_id" INTEGER NOT NULL,
    "numero_piece" TEXT,
    "date_ecriture" TIMESTAMP(3) NOT NULL,
    "libelle" TEXT NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'brouillon',
    "origine" TEXT NOT NULL,
    "source_type" TEXT,
    "source_id" INTEGER,
    "source_role" TEXT,
    "contrepasse_id" INTEGER,
    "boutique_id" INTEGER,
    "utilisateur_id" INTEGER,
    "date_validation" TIMESTAMP(3),
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_ecritures_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "compta_ecritures_exercice_id_fkey" FOREIGN KEY ("exercice_id") REFERENCES "compta_exercices"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "compta_ecritures_journal_id_fkey" FOREIGN KEY ("journal_id") REFERENCES "compta_journaux"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "compta_lignes" (
    "id" SERIAL NOT NULL,
    "ecriture_id" INTEGER NOT NULL,
    "compte_id" INTEGER NOT NULL,
    "tiers_type" TEXT,
    "tiers_id" INTEGER,
    "libelle" TEXT,
    "debit" INTEGER NOT NULL DEFAULT 0,
    "credit" INTEGER NOT NULL DEFAULT 0,
    "lettrage" TEXT,
    "boutique_id" INTEGER,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_lignes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "compta_lignes_ecriture_id_fkey" FOREIGN KEY ("ecriture_id") REFERENCES "compta_ecritures"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "compta_lignes_compte_id_fkey" FOREIGN KEY ("compte_id") REFERENCES "compta_comptes"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "compta_lignes_montants_check" CHECK ("debit" >= 0 AND "credit" >= 0 AND NOT ("debit" > 0 AND "credit" > 0))
);

CREATE TABLE IF NOT EXISTS "compta_parametres" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "regime" TEXT NOT NULL DEFAULT 'normal',
    "mode_affichage" TEXT NOT NULL DEFAULT 'simple',
    "date_ouverture" TIMESTAMP(3),
    "exercice_defaut_id" INTEGER,
    "taux_tva_defaut" DOUBLE PRECISION NOT NULL DEFAULT 19.25,
    "assujetti_tva" BOOLEAN NOT NULL DEFAULT true,
    "longueur_comptes_tiers" INTEGER NOT NULL DEFAULT 6,
    "ouverture_validee" BOOLEAN NOT NULL DEFAULT false,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_parametres_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "idx_compta_exercices_statut" ON "compta_exercices"("statut");
CREATE UNIQUE INDEX IF NOT EXISTS "compta_periodes_exercice_id_mois_key" ON "compta_periodes"("exercice_id", "mois");
CREATE UNIQUE INDEX IF NOT EXISTS "compta_comptes_numero_key" ON "compta_comptes"("numero");
CREATE INDEX IF NOT EXISTS "idx_compta_comptes_classe" ON "compta_comptes"("classe");
CREATE UNIQUE INDEX IF NOT EXISTS "compta_journaux_code_key" ON "compta_journaux"("code");
CREATE UNIQUE INDEX IF NOT EXISTS "compta_ecritures_numero_piece_key" ON "compta_ecritures"("numero_piece");
CREATE UNIQUE INDEX IF NOT EXISTS "uq_compta_ecriture_source" ON "compta_ecritures"("source_type", "source_id", "source_role");
CREATE INDEX IF NOT EXISTS "idx_compta_ecritures_exercice_date" ON "compta_ecritures"("exercice_id", "date_ecriture");
CREATE INDEX IF NOT EXISTS "idx_compta_ecritures_journal" ON "compta_ecritures"("journal_id");
CREATE INDEX IF NOT EXISTS "idx_compta_ecritures_statut" ON "compta_ecritures"("statut");
CREATE INDEX IF NOT EXISTS "idx_compta_ecritures_boutique" ON "compta_ecritures"("boutique_id");
CREATE INDEX IF NOT EXISTS "idx_compta_lignes_ecriture" ON "compta_lignes"("ecriture_id");
CREATE INDEX IF NOT EXISTS "idx_compta_lignes_compte" ON "compta_lignes"("compte_id");
CREATE INDEX IF NOT EXISTS "idx_compta_lignes_tiers" ON "compta_lignes"("tiers_type", "tiers_id");
`;
