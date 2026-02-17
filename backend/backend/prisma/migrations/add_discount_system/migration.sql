-- Migration pour ajouter le système de remises sécurisées

-- Ajouter la colonne remise_max_autorisee à la table produits
ALTER TABLE produits ADD COLUMN remise_max_autorisee REAL DEFAULT 0 NOT NULL;

-- Ajouter les colonnes de remise à la table details_ventes
ALTER TABLE details_ventes ADD COLUMN prix_affiche REAL NOT NULL DEFAULT 0;
ALTER TABLE details_ventes ADD COLUMN remise_appliquee REAL DEFAULT 0 NOT NULL;
ALTER TABLE details_ventes ADD COLUMN justification_remise TEXT;

-- Ajouter la colonne vendeur_id à la table ventes
ALTER TABLE ventes ADD COLUMN vendeur_id INTEGER;

-- Créer l'index pour les ventes par vendeur
CREATE INDEX idx_ventes_vendeur_date ON ventes(vendeur_id, date_vente);

-- Mettre à jour les données existantes
-- Copier prix_unitaire vers prix_affiche pour les enregistrements existants
UPDATE details_ventes SET prix_affiche = prix_unitaire WHERE prix_affiche = 0;

-- Commentaire pour la documentation
-- Cette migration ajoute :
-- 1. remise_max_autorisee : montant maximum de remise autorisé par produit (en FCFA)
-- 2. prix_affiche : prix de base du produit avant remise
-- 3. remise_appliquee : montant de la remise appliquée (en FCFA)
-- 4. justification_remise : justification textuelle optionnelle
-- 5. vendeur_id : référence vers l'utilisateur qui a effectué la vente