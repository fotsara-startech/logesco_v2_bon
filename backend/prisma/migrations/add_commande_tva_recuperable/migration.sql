-- TVA récupérable sur les commandes fournisseurs (comptabilité : TVA déductible sur achats)
ALTER TABLE "commandes_approvisionnement" ADD COLUMN "tva_recuperable" BOOLEAN NOT NULL DEFAULT false;
