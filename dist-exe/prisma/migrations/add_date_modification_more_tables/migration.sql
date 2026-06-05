-- Add date_modification column to mouvements_stock table
ALTER TABLE mouvements_stock ADD COLUMN date_modification DATETIME;

-- Add date_modification column to transferts_stock table
ALTER TABLE transferts_stock ADD COLUMN date_modification DATETIME;

-- Create indices for better query performance
CREATE INDEX IF NOT EXISTS idx_mouvements_stock_date_modification ON mouvements_stock(date_modification);
CREATE INDEX IF NOT EXISTS idx_transferts_stock_date_modification ON transferts_stock(date_modification);
