-- Ajouter les colonnes de snapshot de stock à mouvements_stock
ALTER TABLE "mouvements_stock"
ADD COLUMN IF NOT EXISTS "stock_initial" INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS "stock_final" INTEGER DEFAULT 0;

-- Créer un index pour ces colonnes
CREATE INDEX IF NOT EXISTS "idx_mouvements_stock_initial" ON "mouvements_stock"("stock_initial");
CREATE INDEX IF NOT EXISTS "idx_mouvements_stock_final" ON "mouvements_stock"("stock_final");
