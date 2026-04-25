-- Fonction trigger pour mettre à jour automatiquement date_modification
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger sur toutes les tables avec date_modification
DROP TRIGGER IF EXISTS update_clients_date_modification ON clients;
CREATE TRIGGER update_clients_date_modification
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_utilisateurs_date_modification ON utilisateurs;
CREATE TRIGGER update_utilisateurs_date_modification
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_boutiques_date_modification ON boutiques;
CREATE TRIGGER update_boutiques_date_modification
    BEFORE UPDATE ON boutiques
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_categories_date_modification ON categories;
CREATE TRIGGER update_categories_date_modification
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_produits_date_modification ON produits;
CREATE TRIGGER update_produits_date_modification
    BEFORE UPDATE ON produits
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_fournisseurs_date_modification ON fournisseurs;
CREATE TRIGGER update_fournisseurs_date_modification
    BEFORE UPDATE ON fournisseurs
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_stock_date_modification ON stock;
CREATE TRIGGER update_stock_date_modification
    BEFORE UPDATE ON stock
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_stock_boutiques_date_modification ON stock_boutiques;
CREATE TRIGGER update_stock_boutiques_date_modification
    BEFORE UPDATE ON stock_boutiques
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_cash_registers_date_modification ON cash_registers;
CREATE TRIGGER update_cash_registers_date_modification
    BEFORE UPDATE ON cash_registers
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_cash_sessions_date_modification ON cash_sessions;
CREATE TRIGGER update_cash_sessions_date_modification
    BEFORE UPDATE ON cash_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_movement_categories_date_modification ON movement_categories;
CREATE TRIGGER update_movement_categories_date_modification
    BEFORE UPDATE ON movement_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_ventes_date_modification ON ventes;
CREATE TRIGGER update_ventes_date_modification
    BEFORE UPDATE ON ventes
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

DROP TRIGGER IF EXISTS update_mouvements_stock_date_modification ON mouvements_stock;
CREATE TRIGGER update_mouvements_stock_date_modification
    BEFORE UPDATE ON mouvements_stock
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();
