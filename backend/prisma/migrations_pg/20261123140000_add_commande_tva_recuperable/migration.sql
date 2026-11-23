-- LOGESCO - TVA récupérable sur les commandes fournisseurs (Neon). Idempotent.
ALTER TABLE "commandes_approvisionnement" ADD COLUMN IF NOT EXISTS "tva_recuperable" BOOLEAN NOT NULL DEFAULT false;
