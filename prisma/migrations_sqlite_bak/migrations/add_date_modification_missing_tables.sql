-- ============================================================
-- Migration : Ajout date_modification aux tables transactionnelles
-- À exécuter sur Neon via SQL Editor
-- ============================================================

-- ventes
ALTER TABLE ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE ventes SET date_modification = date_vente WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_ventes_date_modification ON ventes;
CREATE TRIGGER update_ventes_date_modification
    BEFORE UPDATE ON ventes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_ventes
ALTER TABLE details_ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_ventes_date_modification ON details_ventes;
CREATE TRIGGER update_details_ventes_date_modification
    BEFORE UPDATE ON details_ventes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_ventes_proforma
ALTER TABLE details_ventes_proforma ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_ventes_proforma_date_modification ON details_ventes_proforma;
CREATE TRIGGER update_details_ventes_proforma_date_modification
    BEFORE UPDATE ON details_ventes_proforma FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- commandes_approvisionnement
ALTER TABLE commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE commandes_approvisionnement SET date_modification = date_commande WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_commandes_date_modification ON commandes_approvisionnement;
CREATE TRIGGER update_commandes_date_modification
    BEFORE UPDATE ON commandes_approvisionnement FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_commandes_approvisionnement
ALTER TABLE details_commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_commandes_date_modification ON details_commandes_approvisionnement;
CREATE TRIGGER update_details_commandes_date_modification
    BEFORE UPDATE ON details_commandes_approvisionnement FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- mouvements_stock
ALTER TABLE mouvements_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE mouvements_stock SET date_modification = date_mouvement WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_mouvements_stock_date_modification ON mouvements_stock;
CREATE TRIGGER update_mouvements_stock_date_modification
    BEFORE UPDATE ON mouvements_stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- transferts_stock
ALTER TABLE transferts_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE transferts_stock SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_transferts_stock_date_modification ON transferts_stock;
CREATE TRIGGER update_transferts_stock_date_modification
    BEFORE UPDATE ON transferts_stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- cash_sessions (a un trigger mais pas la colonne)
ALTER TABLE cash_sessions ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_sessions SET date_modification = date_ouverture WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_cash_sessions_date_modification ON cash_sessions;
CREATE TRIGGER update_cash_sessions_date_modification
    BEFORE UPDATE ON cash_sessions FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- cash_movements
ALTER TABLE cash_movements ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_movements SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_cash_movements_date_modification ON cash_movements;
CREATE TRIGGER update_cash_movements_date_modification
    BEFORE UPDATE ON cash_movements FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- transactions_comptes
ALTER TABLE transactions_comptes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE transactions_comptes SET date_modification = date_transaction WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_transactions_comptes_date_modification ON transactions_comptes;
CREATE TRIGGER update_transactions_comptes_date_modification
    BEFORE UPDATE ON transactions_comptes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- historique_recus
ALTER TABLE historique_recus ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE historique_recus SET date_modification = date_generation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_historique_recus_date_modification ON historique_recus;
CREATE TRIGGER update_historique_recus_date_modification
    BEFORE UPDATE ON historique_recus FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- comptes_clients (utilise date_derniere_maj = @updatedAt)
ALTER TABLE comptes_clients ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_clients SET date_modification = date_derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_comptes_clients_date_modification ON comptes_clients;
CREATE TRIGGER update_comptes_clients_date_modification
    BEFORE UPDATE ON comptes_clients FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- comptes_fournisseurs
ALTER TABLE comptes_fournisseurs ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_fournisseurs SET date_modification = date_derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_comptes_fournisseurs_date_modification ON comptes_fournisseurs;
CREATE TRIGGER update_comptes_fournisseurs_date_modification
    BEFORE UPDATE ON comptes_fournisseurs FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- stock (utilise derniere_maj)
ALTER TABLE stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE stock SET date_modification = derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_stock_date_modification2 ON stock;
CREATE TRIGGER update_stock_date_modification2
    BEFORE UPDATE ON stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- stock_boutiques (utilise derniere_maj)
ALTER TABLE stock_boutiques ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE stock_boutiques SET date_modification = derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_stock_boutiques_date_modification2 ON stock_boutiques;
CREATE TRIGGER update_stock_boutiques_date_modification2
    BEFORE UPDATE ON stock_boutiques FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- user_boutique_assignments
ALTER TABLE user_boutique_assignments ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE user_boutique_assignments SET date_modification = date_creation WHERE date_modification IS NULL;
