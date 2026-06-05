-- Fix NULL values in date_modification columns before making them NOT NULL

-- Update transferts_stock
UPDATE transferts_stock SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Update mouvements_stock
UPDATE mouvements_stock SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Update transactions_comptes
UPDATE transactions_comptes SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Update stock_inventories
UPDATE stock_inventories SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Update inventory_items
UPDATE inventory_items SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
