-- Migration pour créer la table des catégories de produits
-- Date: 2025-01-01
-- Description: Table pour stocker les catégories de produits

CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    dateCreation DATETIME DEFAULT CURRENT_TIMESTAMP,
    dateModification DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Index pour améliorer les performances
    CONSTRAINT categories_nom_unique UNIQUE (nom)
);

-- Index pour les recherches par nom
CREATE INDEX IF NOT EXISTS idx_categories_nom ON categories(nom);

-- Index pour les dates
CREATE INDEX IF NOT EXISTS idx_categories_date_creation ON categories(dateCreation);

-- Trigger pour mettre à jour automatiquement dateModification
CREATE TRIGGER IF NOT EXISTS update_categories_modified_time 
    AFTER UPDATE ON categories
BEGIN
    UPDATE categories 
    SET dateModification = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
END;

-- Insertion de quelques catégories par défaut
INSERT OR IGNORE INTO categories (nom, description) VALUES 
    ('Smartphones', 'Téléphones intelligents et accessoires mobiles'),
    ('Ordinateurs', 'PC, laptops et composants informatiques'),
    ('Accessoires', 'Câbles, chargeurs et autres accessoires électroniques'),
    ('Écrans', 'Moniteurs et écrans pour ordinateurs'),
    ('Audio', 'Casques, écouteurs et équipements audio');

-- Vérification de la création
SELECT 'Table categories créée avec succès' as message;
SELECT COUNT(*) as nb_categories_inserees FROM categories;