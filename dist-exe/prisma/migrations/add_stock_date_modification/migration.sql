-- Add date_modification column to stock table
ALTER TABLE stock ADD COLUMN date_modification DATETIME;

-- Populate existing rows with current timestamp
UPDATE stock SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_stock_date_modification ON stock(date_modification);
