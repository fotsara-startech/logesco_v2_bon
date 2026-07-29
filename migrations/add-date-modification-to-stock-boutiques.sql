-- Migration: Ajout de la colonne date_modification à stock_boutiques
-- Date: 2026-07-16

-- Ajouter la colonne date_modification
ALTER TABLE stock_boutiques ADD COLUMN date_modification TEXT;

-- Créer l'index
CREATE INDEX IF NOT EXISTS idx_stock_boutique_date_modification ON stock_boutiques(date_modification);

-- Initialiser avec la valeur de derniere_maj
UPDATE stock_boutiques SET date_modification = derniere_maj WHERE date_modification IS NULL;
