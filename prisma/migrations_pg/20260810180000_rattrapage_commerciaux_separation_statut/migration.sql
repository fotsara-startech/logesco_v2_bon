-- ============================================================
-- LOGESCO - Rattrapage migrations Neon manquantes
-- Cible : bases clients dont le schéma Neon a pris du retard sur
-- schema.postgresql.prisma. Regroupe :
--   1) Commerciaux terrain (villes / zones / commerciaux + snapshot
--      sur ventes) — migration locale 20260810185100_add_commerciaux
--      et 20260811093000_snapshot_zone_ville_sur_ventes
--   2) Séparation commande/encaissement — add_separation_commande_visibilite_ventes
--   3) financial_movements.statut — add_financial_movements_statut
--
-- Idempotent : peut être exécuté plusieurs fois sans risque.
-- ============================================================

CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1) Commerciaux terrain -----------------------------------------------

CREATE TABLE IF NOT EXISTS "villes" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "villes_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "zones" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "ville_id" INTEGER NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "zones_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "commerciaux" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "prenom" TEXT,
    "telephone" TEXT,
    "zone_id" INTEGER NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "commerciaux_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "commercial_id" INTEGER;
ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "zone_id" INTEGER;
ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "ville_id" INTEGER;

DO $$ BEGIN
    ALTER TABLE "villes" ADD CONSTRAINT "villes_nom_key" UNIQUE ("nom");
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "zones" ADD CONSTRAINT "zones_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "villes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "zones" ADD CONSTRAINT "zones_ville_id_nom_key" UNIQUE ("ville_id", "nom");
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "commerciaux" ADD CONSTRAINT "commerciaux_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "ventes" ADD CONSTRAINT "ventes_commercial_id_fkey" FOREIGN KEY ("commercial_id") REFERENCES "commerciaux"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "ventes" ADD CONSTRAINT "ventes_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE "ventes" ADD CONSTRAINT "ventes_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "villes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "idx_villes_nom" ON "villes"("nom");
CREATE INDEX IF NOT EXISTS "idx_zones_ville" ON "zones"("ville_id");
CREATE INDEX IF NOT EXISTS "idx_commerciaux_zone" ON "commerciaux"("zone_id");
CREATE INDEX IF NOT EXISTS "idx_commerciaux_actif" ON "commerciaux"("is_active");
CREATE INDEX IF NOT EXISTS "idx_ventes_commercial" ON "ventes"("commercial_id");
CREATE INDEX IF NOT EXISTS "idx_ventes_zone" ON "ventes"("zone_id");
CREATE INDEX IF NOT EXISTS "idx_ventes_ville" ON "ventes"("ville_id");

DROP TRIGGER IF EXISTS update_villes_date_modification ON villes;
CREATE TRIGGER update_villes_date_modification
    BEFORE UPDATE ON villes
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_zones_date_modification ON zones;
CREATE TRIGGER update_zones_date_modification
    BEFORE UPDATE ON zones
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_commerciaux_date_modification ON commerciaux;
CREATE TRIGGER update_commerciaux_date_modification
    BEFORE UPDATE ON commerciaux
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- 2) Séparation commande / encaissement ---------------------------------

ALTER TABLE "parametres_entreprise" ADD COLUMN IF NOT EXISTS "separer_commande_encaissement" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "parametres_entreprise" ADD COLUMN IF NOT EXISTS "vendeurs_voient_toutes_ventes" BOOLEAN NOT NULL DEFAULT false;

-- 3) financial_movements.statut ------------------------------------------

ALTER TABLE "financial_movements" ADD COLUMN IF NOT EXISTS "statut" TEXT NOT NULL DEFAULT 'actif';
