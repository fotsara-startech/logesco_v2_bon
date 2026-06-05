-- Add date_modification column to transactions_comptes table
ALTER TABLE transactions_comptes ADD COLUMN date_modification DATETIME;

-- Add date_modification column to stock_inventories table
ALTER TABLE stock_inventories ADD COLUMN date_modification DATETIME;

-- Add date_modification column to inventory_items table
ALTER TABLE inventory_items ADD COLUMN date_modification DATETIME;

-- Create indices for better query performance
CREATE INDEX IF NOT EXISTS idx_transactions_comptes_date_modification ON transactions_comptes(date_modification);
CREATE INDEX IF NOT EXISTS idx_stock_inventories_date_modification ON stock_inventories(date_modification);
CREATE INDEX IF NOT EXISTS idx_inventory_items_date_modification ON inventory_items(date_modification);
