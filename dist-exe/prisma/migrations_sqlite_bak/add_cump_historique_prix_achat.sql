-- Migration: Ajout CUMP et table historique_prix_achat
-- Date: 2026

-- 1. Ajouter la colonne cump à la table produits
ALTER TABLE produits ADD COLUMN cump REAL;

-- 2. Créer la table historique_prix_achat
CREATE TABLE IF NOT EXISTS historique_prix_achat (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  produit_id    INTEGER NOT NULL,
  prix_achat    REAL    NOT NULL,
  source        TEXT    NOT NULL DEFAULT 'manuel',
  reference_id  INTEGER,
  date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_historique_prix_achat_produit ON historique_prix_achat(produit_id);
CREATE INDEX IF NOT EXISTS idx_historique_prix_achat_date    ON historique_prix_achat(date_creation);

-- 3. Initialiser l'historique depuis les prix d'achat existants
INSERT INTO historique_prix_achat (produit_id, prix_achat, source)
SELECT id, prix_achat, 'manuel'
FROM produits
WHERE prix_achat IS NOT NULL AND prix_achat > 0;

-- 4. Initialiser le cump = prixAchat actuel pour les produits existants
UPDATE produits SET cump = prix_achat WHERE prix_achat IS NOT NULL AND prix_achat > 0;
