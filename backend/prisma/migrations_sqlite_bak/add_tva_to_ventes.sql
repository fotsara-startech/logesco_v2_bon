-- Migration: Ajout des colonnes TVA dans la table ventes
ALTER TABLE ventes ADD COLUMN montant_tva REAL NOT NULL DEFAULT 0;
ALTER TABLE ventes ADD COLUMN taux_tva REAL;
