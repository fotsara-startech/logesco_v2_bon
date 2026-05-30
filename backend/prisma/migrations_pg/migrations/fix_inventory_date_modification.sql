-- ============================================================
-- Migration : Ajout date_modification à stock_inventories et inventory_items
-- À exécuter sur Neon via SQL Editor ou psql
-- ============================================================

-- Vérifier que la fonction update_date_modification existe
-- (elle devrait déjà exister si add_update_triggers.sql a été exécuté)
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ajouter la colonne date_modification à stock_inventories
ALTER TABLE stock_inventories
    ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Initialiser avec date_creation pour les enregistrements existants
UPDATE stock_inventories
SET date_modification = date_creation
WHERE date_modification IS NULL;

-- Créer le trigger pour stock_inventories
DROP TRIGGER IF EXISTS update_stock_inventories_date_modification ON stock_inventories;
CREATE TRIGGER update_stock_inventories_date_modification
    BEFORE UPDATE ON stock_inventories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- Ajouter la colonne date_modification à inventory_items
ALTER TABLE inventory_items
    ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Initialiser avec CURRENT_TIMESTAMP pour les enregistrements existants
UPDATE inventory_items
SET date_modification = CURRENT_TIMESTAMP
WHERE date_modification IS NULL;

-- Créer le trigger pour inventory_items
DROP TRIGGER IF EXISTS update_inventory_items_date_modification ON inventory_items;
CREATE TRIGGER update_inventory_items_date_modification
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- Vérification
SELECT 
    'stock_inventories' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification
FROM stock_inventories
UNION ALL
SELECT 
    'inventory_items' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification
FROM inventory_items;
