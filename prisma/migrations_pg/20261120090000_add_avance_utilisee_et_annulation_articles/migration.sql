-- ============================================================
-- LOGESCO - Colonnes ajoutees apres la migration initiale Postgres
--   1) ventes.avance_utilisee           (avance client consommee par la vente)
--   2) details_ventes.annule            (annulation d'un article de vente)
--   3) details_ventes.date_annulation
--
-- Sans ces colonnes, toute requete Prisma sur les ventes echoue (erreur 500
-- "Erreur lors de la recuperation des ventes") sur les bases Neon qui ne
-- passent pas par un poste desktop en mode hybride (cloud-migration-runner).
--
-- Idempotent : peut etre rejoue sans risque (IF NOT EXISTS).
-- ============================================================

ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "avance_utilisee" DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE "details_ventes" ADD COLUMN IF NOT EXISTS "annule" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "details_ventes" ADD COLUMN IF NOT EXISTS "date_annulation" TIMESTAMPTZ;
