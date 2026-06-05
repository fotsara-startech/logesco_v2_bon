-- Add date_modification column to remaining tables for Event Sourcing V2 delta sync

-- stock_boutiques table
ALTER TABLE stock_boutiques ADD COLUMN date_modification DATETIME;

-- comptes_fournisseurs table
ALTER TABLE comptes_fournisseurs ADD COLUMN date_modification DATETIME;

-- comptes_clients table
ALTER TABLE comptes_clients ADD COLUMN date_modification DATETIME;

-- cash_sessions table
ALTER TABLE cash_sessions ADD COLUMN date_modification DATETIME;

-- cash_movements table
ALTER TABLE cash_movements ADD COLUMN date_modification DATETIME;

-- Populate existing rows with current timestamp
UPDATE stock_boutiques SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
UPDATE comptes_fournisseurs SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
UPDATE comptes_clients SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
UPDATE cash_sessions SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
UPDATE cash_movements SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Create indices for better query performance
CREATE INDEX IF NOT EXISTS idx_stock_boutiques_date_modification ON stock_boutiques(date_modification);
CREATE INDEX IF NOT EXISTS idx_comptes_fournisseurs_date_modification ON comptes_fournisseurs(date_modification);
CREATE INDEX IF NOT EXISTS idx_comptes_clients_date_modification ON comptes_clients(date_modification);
CREATE INDEX IF NOT EXISTS idx_cash_sessions_date_modification ON cash_sessions(date_modification);
CREATE INDEX IF NOT EXISTS idx_cash_movements_date_modification ON cash_movements(date_modification);
