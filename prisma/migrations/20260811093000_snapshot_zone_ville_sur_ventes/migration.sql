-- Fige la zone/ville du commercial sur chaque vente au moment où elle est
-- créée, au lieu de recalculer via Commercial.zoneId à la lecture.
--
-- Sans ça, réaffecter un commercial à une autre zone réécrit silencieusement
-- l'historique du rapport « ventes par zone/ville » : toutes ses ventes
-- passées, y compris celles faites dans son ancien secteur, se retrouvent
-- attribuées à sa zone ACTUELLE. Voir commercial-report.js pour le
-- comportement de repli sur les ventes déjà existantes (zone_id NULL, car
-- créées avant cette migration).

-- AlterTable
ALTER TABLE "ventes" ADD COLUMN "zone_id" INTEGER;
ALTER TABLE "ventes" ADD COLUMN "ville_id" INTEGER;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_ventes_zone" ON "ventes"("zone_id");
CREATE INDEX IF NOT EXISTS "idx_ventes_ville" ON "ventes"("ville_id");
