-- ============================================================
-- LOGESCO - Configuration complète pour Neon PostgreSQL
-- ============================================================
-- Ce script regroupe toutes les migrations nécessaires pour
-- configurer une nouvelle base de données Neon pour LOGESCO.
--
-- USAGE:
-- 1. Via Neon Console SQL Editor: Copier/coller et exécuter
-- 2. Via psql: psql "postgresql://..." -f COMPLETE_NEON_SETUP.sql
-- 3. Via Node.js: node setup-neon.js
--
-- CONTENU:
-- 1. Fonction trigger update_date_modification
-- 2. Ajout de date_modification à toutes les tables
-- 3. Création des triggers pour toutes les tables
--
-- Date de création: 2026-04-29
-- Version: 1.0
-- ============================================================

-- ============================================================
-- SECTION 1: FONCTION TRIGGER
-- ============================================================

-- Créer ou remplacer la fonction trigger pour mettre à jour automatiquement date_modification
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- SECTION 2: TABLES DE BASE (déjà avec date_modification dans le schéma)
-- ============================================================

-- clients
DROP TRIGGER IF EXISTS update_clients_date_modification ON clients;
CREATE TRIGGER update_clients_date_modification
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- utilisateurs
DROP TRIGGER IF EXISTS update_utilisateurs_date_modification ON utilisateurs;
CREATE TRIGGER update_utilisateurs_date_modification
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- boutiques
DROP TRIGGER IF EXISTS update_boutiques_date_modification ON boutiques;
CREATE TRIGGER update_boutiques_date_modification
    BEFORE UPDATE ON boutiques
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- categories
DROP TRIGGER IF EXISTS update_categories_date_modification ON categories;
CREATE TRIGGER update_categories_date_modification
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- produits
DROP TRIGGER IF EXISTS update_produits_date_modification ON produits;
CREATE TRIGGER update_produits_date_modification
    BEFORE UPDATE ON produits
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- fournisseurs
DROP TRIGGER IF EXISTS update_fournisseurs_date_modification ON fournisseurs;
CREATE TRIGGER update_fournisseurs_date_modification
    BEFORE UPDATE ON fournisseurs
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- movement_categories
DROP TRIGGER IF EXISTS update_movement_categories_date_modification ON movement_categories;
CREATE TRIGGER update_movement_categories_date_modification
    BEFORE UPDATE ON movement_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ventes_proforma
DROP TRIGGER IF EXISTS update_ventes_proforma_date_modification ON ventes_proforma;
CREATE TRIGGER update_ventes_proforma_date_modification
    BEFORE UPDATE ON ventes_proforma
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- user_roles
DROP TRIGGER IF EXISTS update_user_roles_date_modification ON user_roles;
CREATE TRIGGER update_user_roles_date_modification
    BEFORE UPDATE ON user_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- cash_registers
DROP TRIGGER IF EXISTS update_cash_registers_date_modification ON cash_registers;
CREATE TRIGGER update_cash_registers_date_modification
    BEFORE UPDATE ON cash_registers
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- parametres_entreprise
DROP TRIGGER IF EXISTS update_parametres_entreprise_date_modification ON parametres_entreprise;
CREATE TRIGGER update_parametres_entreprise_date_modification
    BEFORE UPDATE ON parametres_entreprise
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- SECTION 3: TABLES TRANSACTIONNELLES (ajout de date_modification)
-- ============================================================

-- ventes
ALTER TABLE ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE ventes SET date_modification = date_vente WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_ventes_date_modification ON ventes;
CREATE TRIGGER update_ventes_date_modification
    BEFORE UPDATE ON ventes
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- details_ventes
ALTER TABLE details_ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE details_ventes SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_details_ventes_date_modification ON details_ventes;
CREATE TRIGGER update_details_ventes_date_modification
    BEFORE UPDATE ON details_ventes
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- details_ventes_proforma
ALTER TABLE details_ventes_proforma ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE details_ventes_proforma SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_details_ventes_proforma_date_modification ON details_ventes_proforma;
CREATE TRIGGER update_details_ventes_proforma_date_modification
    BEFORE UPDATE ON details_ventes_proforma
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- commandes_approvisionnement
ALTER TABLE commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE commandes_approvisionnement SET date_modification = date_commande WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_commandes_date_modification ON commandes_approvisionnement;
CREATE TRIGGER update_commandes_date_modification
    BEFORE UPDATE ON commandes_approvisionnement
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- details_commandes_approvisionnement
ALTER TABLE details_commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE details_commandes_approvisionnement SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_details_commandes_date_modification ON details_commandes_approvisionnement;
CREATE TRIGGER update_details_commandes_date_modification
    BEFORE UPDATE ON details_commandes_approvisionnement
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- mouvements_stock
ALTER TABLE mouvements_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE mouvements_stock SET date_modification = date_mouvement WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_mouvements_stock_date_modification ON mouvements_stock;
CREATE TRIGGER update_mouvements_stock_date_modification
    BEFORE UPDATE ON mouvements_stock
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- transferts_stock
ALTER TABLE transferts_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE transferts_stock SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_transferts_stock_date_modification ON transferts_stock;
CREATE TRIGGER update_transferts_stock_date_modification
    BEFORE UPDATE ON transferts_stock
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- cash_sessions
ALTER TABLE cash_sessions ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_sessions SET date_modification = date_ouverture WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_cash_sessions_date_modification ON cash_sessions;
CREATE TRIGGER update_cash_sessions_date_modification
    BEFORE UPDATE ON cash_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- cash_movements
ALTER TABLE cash_movements ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_movements SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_cash_movements_date_modification ON cash_movements;
CREATE TRIGGER update_cash_movements_date_modification
    BEFORE UPDATE ON cash_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- financial_movements
ALTER TABLE financial_movements ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE financial_movements SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_financial_movements_date_modification ON financial_movements;
CREATE TRIGGER update_financial_movements_date_modification
    BEFORE UPDATE ON financial_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- transactions_comptes
ALTER TABLE transactions_comptes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE transactions_comptes SET date_modification = date_transaction WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_transactions_comptes_date_modification ON transactions_comptes;
CREATE TRIGGER update_transactions_comptes_date_modification
    BEFORE UPDATE ON transactions_comptes
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- historique_recus
ALTER TABLE historique_recus ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE historique_recus SET date_modification = date_generation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_historique_recus_date_modification ON historique_recus;
CREATE TRIGGER update_historique_recus_date_modification
    BEFORE UPDATE ON historique_recus
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- reimpressions_recus
ALTER TABLE reimpressions_recus ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE reimpressions_recus SET date_modification = date_reimpression WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_reimpressions_recus_date_modification ON reimpressions_recus;
CREATE TRIGGER update_reimpressions_recus_date_modification
    BEFORE UPDATE ON reimpressions_recus
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- movement_attachments
ALTER TABLE movement_attachments ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE movement_attachments SET date_modification = uploaded_at WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_movement_attachments_date_modification ON movement_attachments;
CREATE TRIGGER update_movement_attachments_date_modification
    BEFORE UPDATE ON movement_attachments
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- SECTION 4: TABLES DE COMPTES
-- ============================================================

-- comptes_clients (utilise date_derniere_maj)
ALTER TABLE comptes_clients ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_clients SET date_modification = date_derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_comptes_clients_date_modification ON comptes_clients;
CREATE TRIGGER update_comptes_clients_date_modification
    BEFORE UPDATE ON comptes_clients
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- comptes_fournisseurs
ALTER TABLE comptes_fournisseurs ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_fournisseurs SET date_modification = date_derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_comptes_fournisseurs_date_modification ON comptes_fournisseurs;
CREATE TRIGGER update_comptes_fournisseurs_date_modification
    BEFORE UPDATE ON comptes_fournisseurs
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- SECTION 5: TABLES DE STOCK
-- ============================================================

-- stock (utilise derniere_maj)
ALTER TABLE stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE stock SET date_modification = derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_stock_date_modification ON stock;
CREATE TRIGGER update_stock_date_modification
    BEFORE UPDATE ON stock
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- stock_boutiques (utilise derniere_maj)
ALTER TABLE stock_boutiques ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE stock_boutiques SET date_modification = derniere_maj WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_stock_boutiques_date_modification ON stock_boutiques;
CREATE TRIGGER update_stock_boutiques_date_modification
    BEFORE UPDATE ON stock_boutiques
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- stock_inventories
ALTER TABLE stock_inventories ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE stock_inventories SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_stock_inventories_date_modification ON stock_inventories;
CREATE TRIGGER update_stock_inventories_date_modification
    BEFORE UPDATE ON stock_inventories
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- inventory_items
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE inventory_items SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_inventory_items_date_modification ON inventory_items;
CREATE TRIGGER update_inventory_items_date_modification
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- dates_peremption
ALTER TABLE dates_peremption ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE dates_peremption SET date_modification = date_entree WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_dates_peremption_date_modification ON dates_peremption;
CREATE TRIGGER update_dates_peremption_date_modification
    BEFORE UPDATE ON dates_peremption
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- SECTION 6: TABLES D'ASSIGNATION
-- ============================================================

-- user_boutique_assignments
ALTER TABLE user_boutique_assignments ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE user_boutique_assignments SET date_modification = date_creation WHERE date_modification IS NULL;
DROP TRIGGER IF EXISTS update_user_boutique_assignments_date_modification ON user_boutique_assignments;
CREATE TRIGGER update_user_boutique_assignments_date_modification
    BEFORE UPDATE ON user_boutique_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- SECTION 7: VÉRIFICATION FINALE
-- ============================================================

-- Afficher un résumé des tables avec date_modification
DO $$
DECLARE
    table_record RECORD;
    total_tables INTEGER := 0;
    tables_with_trigger INTEGER := 0;
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'VÉRIFICATION DE LA CONFIGURATION';
    RAISE NOTICE '============================================================';
    
    -- Compter les tables avec date_modification
    FOR table_record IN 
        SELECT 
            c.relname as table_name,
            EXISTS(
                SELECT 1 
                FROM pg_trigger t 
                WHERE t.tgrelid = c.oid 
                AND t.tgname LIKE '%date_modification%'
            ) as has_trigger
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
        AND n.nspname = 'public'
        AND EXISTS (
            SELECT 1 
            FROM pg_attribute a 
            WHERE a.attrelid = c.oid 
            AND a.attname = 'date_modification'
        )
        ORDER BY c.relname
    LOOP
        total_tables := total_tables + 1;
        IF table_record.has_trigger THEN
            tables_with_trigger := tables_with_trigger + 1;
            RAISE NOTICE '✓ % (trigger actif)', table_record.table_name;
        ELSE
            RAISE NOTICE '✗ % (trigger manquant)', table_record.table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Total: % tables avec date_modification', total_tables;
    RAISE NOTICE 'Triggers actifs: %', tables_with_trigger;
    RAISE NOTICE '============================================================';
    
    IF total_tables = tables_with_trigger THEN
        RAISE NOTICE '✅ Configuration complète réussie !';
    ELSE
        RAISE WARNING '⚠️  Certains triggers sont manquants';
    END IF;
END $$;

-- Afficher les statistiques des tables critiques
SELECT 
    'stock_inventories' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification,
    CASE 
        WHEN COUNT(*) = COUNT(date_modification) THEN '✅'
        ELSE '⚠️'
    END as status
FROM stock_inventories
UNION ALL
SELECT 
    'inventory_items' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification,
    CASE 
        WHEN COUNT(*) = COUNT(date_modification) THEN '✅'
        ELSE '⚠️'
    END as status
FROM inventory_items
UNION ALL
SELECT 
    'ventes' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification,
    CASE 
        WHEN COUNT(*) = COUNT(date_modification) THEN '✅'
        ELSE '⚠️'
    END as status
FROM ventes
UNION ALL
SELECT 
    'cash_sessions' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification,
    CASE 
        WHEN COUNT(*) = COUNT(date_modification) THEN '✅'
        ELSE '⚠️'
    END as status
FROM cash_sessions;

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
