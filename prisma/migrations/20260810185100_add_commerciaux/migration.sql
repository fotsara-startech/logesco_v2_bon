-- Ajoute la gestion des commerciaux terrain : villes, zones (quartiers) et
-- commerciaux, plus l'attribution optionnelle d'une vente à un commercial.
-- Le commercial n'est pas un compte utilisateur — c'est une fiche de
-- référence saisie par la caissière qui encaisse le versement en magasin.

-- CreateTable
CREATE TABLE IF NOT EXISTS "villes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "zones" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "ville_id" INTEGER NOT NULL,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    CONSTRAINT "zones_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "villes" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "commerciaux" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "prenom" TEXT,
    "telephone" TEXT,
    "zone_id" INTEGER NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    CONSTRAINT "commerciaux_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- AlterTable
ALTER TABLE "ventes" ADD COLUMN "commercial_id" INTEGER;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "villes_nom_key" ON "villes"("nom");
CREATE INDEX IF NOT EXISTS "idx_villes_nom" ON "villes"("nom");

CREATE UNIQUE INDEX IF NOT EXISTS "zones_ville_id_nom_key" ON "zones"("ville_id", "nom");
CREATE INDEX IF NOT EXISTS "idx_zones_ville" ON "zones"("ville_id");

CREATE INDEX IF NOT EXISTS "idx_commerciaux_zone" ON "commerciaux"("zone_id");
CREATE INDEX IF NOT EXISTS "idx_commerciaux_actif" ON "commerciaux"("is_active");

CREATE INDEX IF NOT EXISTS "idx_ventes_commercial" ON "ventes"("commercial_id");
