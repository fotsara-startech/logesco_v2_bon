-- ============================================================
-- Migration : Tables manquantes + date_modification complète
-- À appliquer sur chaque nouveau client Neon
-- Idempotente — peut être rejouée sans risque
-- ============================================================

-- ============================================================
-- 1. FONCTION TRIGGER (base pour tous les triggers ci-dessous)
-- ============================================================
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 2. TABLE MANQUANTE : historique_prix_achat
-- ============================================================
CREATE TABLE IF NOT EXISTS "historique_prix_achat" (
    "id"           SERIAL NOT NULL,
    "produit_id"   INTEGER NOT NULL,
    "prix_achat"   DOUBLE PRECISION NOT NULL,
    "quantite"     DOUBLE PRECISION NOT NULL DEFAULT 1,
    "source"       TEXT NOT NULL DEFAULT 'manuel',
    "reference_id" INTEGER,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historique_prix_achat_pkey" PRIMARY KEY ("id")
);

-- FK vers produits (idempotente)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'historique_prix_achat_produit_id_fkey'
    ) THEN
        ALTER TABLE "historique_prix_achat"
            ADD CONSTRAINT "historique_prix_achat_produit_id_fkey"
            FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS "idx_historique_prix_achat_produit" ON "historique_prix_achat"("produit_id");
CREATE INDEX IF NOT EXISTS "idx_historique_prix_achat_date"    ON "historique_prix_achat"("date_creation");

DROP TRIGGER IF EXISTS update_historique_prix_achat_date_modification ON historique_prix_achat;
CREATE TRIGGER update_historique_prix_achat_date_modification
    BEFORE UPDATE ON historique_prix_achat
    FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- 3. COLONNES MANQUANTES SUR LES TABLES EXISTANTES
-- ============================================================

-- produits : cump (Coût Unitaire Moyen Pondéré)
ALTER TABLE produits ADD COLUMN IF NOT EXISTS cump DOUBLE PRECISION;

-- mouvements_stock : stock_initial et stock_final
ALTER TABLE mouvements_stock ADD COLUMN IF NOT EXISTS stock_initial INTEGER NOT NULL DEFAULT 0;
ALTER TABLE mouvements_stock ADD COLUMN IF NOT EXISTS stock_final INTEGER NOT NULL DEFAULT 0;

-- ============================================================
-- 4. date_modification MANQUANTE sur les tables transactionnelles
-- ============================================================

-- stock_boutiques
ALTER TABLE stock_boutiques ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE stock_boutiques SET date_modification = derniere_maj WHERE date_modification = CURRENT_TIMESTAMP AND derniere_maj IS NOT NULL;
DROP TRIGGER IF EXISTS update_stock_boutiques_date_modification ON stock_boutiques;
CREATE TRIGGER update_stock_boutiques_date_modification
    BEFORE UPDATE ON stock_boutiques FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- stock
ALTER TABLE stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE stock SET date_modification = derniere_maj WHERE date_modification = CURRENT_TIMESTAMP AND derniere_maj IS NOT NULL;
DROP TRIGGER IF EXISTS update_stock_date_modification ON stock;
CREATE TRIGGER update_stock_date_modification
    BEFORE UPDATE ON stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- transferts_stock
ALTER TABLE transferts_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE transferts_stock SET date_modification = date_creation WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_transferts_stock_date_modification ON transferts_stock;
CREATE TRIGGER update_transferts_stock_date_modification
    BEFORE UPDATE ON transferts_stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- mouvements_stock
ALTER TABLE mouvements_stock ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE mouvements_stock SET date_modification = date_mouvement WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_mouvements_stock_date_modification ON mouvements_stock;
CREATE TRIGGER update_mouvements_stock_date_modification
    BEFORE UPDATE ON mouvements_stock FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- cash_sessions
ALTER TABLE cash_sessions ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_sessions SET date_modification = date_ouverture WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_cash_sessions_date_modification ON cash_sessions;
CREATE TRIGGER update_cash_sessions_date_modification
    BEFORE UPDATE ON cash_sessions FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- cash_movements
ALTER TABLE cash_movements ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE cash_movements SET date_modification = date_creation WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_cash_movements_date_modification ON cash_movements;
CREATE TRIGGER update_cash_movements_date_modification
    BEFORE UPDATE ON cash_movements FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- commandes_approvisionnement
ALTER TABLE commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE commandes_approvisionnement SET date_modification = date_commande WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_commandes_date_modification ON commandes_approvisionnement;
CREATE TRIGGER update_commandes_date_modification
    BEFORE UPDATE ON commandes_approvisionnement FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_commandes_approvisionnement
ALTER TABLE details_commandes_approvisionnement ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_commandes_date_modification ON details_commandes_approvisionnement;
CREATE TRIGGER update_details_commandes_date_modification
    BEFORE UPDATE ON details_commandes_approvisionnement FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_ventes
ALTER TABLE details_ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_ventes_date_modification ON details_ventes;
CREATE TRIGGER update_details_ventes_date_modification
    BEFORE UPDATE ON details_ventes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- details_ventes_proforma
ALTER TABLE details_ventes_proforma ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_details_ventes_proforma_date_modification ON details_ventes_proforma;
CREATE TRIGGER update_details_ventes_proforma_date_modification
    BEFORE UPDATE ON details_ventes_proforma FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- ventes (date_modification absente du init)
ALTER TABLE ventes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE ventes SET date_modification = date_vente WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_ventes_date_modification ON ventes;
CREATE TRIGGER update_ventes_date_modification
    BEFORE UPDATE ON ventes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- transactions_comptes
ALTER TABLE transactions_comptes ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE transactions_comptes SET date_modification = date_transaction WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_transactions_comptes_date_modification ON transactions_comptes;
CREATE TRIGGER update_transactions_comptes_date_modification
    BEFORE UPDATE ON transactions_comptes FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- comptes_clients
ALTER TABLE comptes_clients ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_clients SET date_modification = date_derniere_maj WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_comptes_clients_date_modification ON comptes_clients;
CREATE TRIGGER update_comptes_clients_date_modification
    BEFORE UPDATE ON comptes_clients FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- comptes_fournisseurs
ALTER TABLE comptes_fournisseurs ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE comptes_fournisseurs SET date_modification = date_derniere_maj WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_comptes_fournisseurs_date_modification ON comptes_fournisseurs;
CREATE TRIGGER update_comptes_fournisseurs_date_modification
    BEFORE UPDATE ON comptes_fournisseurs FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- historique_recus
ALTER TABLE historique_recus ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE historique_recus SET date_modification = date_generation WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_historique_recus_date_modification ON historique_recus;
CREATE TRIGGER update_historique_recus_date_modification
    BEFORE UPDATE ON historique_recus FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- stock_inventories
ALTER TABLE stock_inventories ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE stock_inventories SET date_modification = date_creation WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_stock_inventories_date_modification ON stock_inventories;
CREATE TRIGGER update_stock_inventories_date_modification
    BEFORE UPDATE ON stock_inventories FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- inventory_items
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_inventory_items_date_modification ON inventory_items;
CREATE TRIGGER update_inventory_items_date_modification
    BEFORE UPDATE ON inventory_items FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- user_boutique_assignments
ALTER TABLE user_boutique_assignments ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE user_boutique_assignments SET date_modification = date_creation WHERE date_modification = CURRENT_TIMESTAMP;
DROP TRIGGER IF EXISTS update_user_boutique_assignments_date_modification ON user_boutique_assignments;
CREATE TRIGGER update_user_boutique_assignments_date_modification
    BEFORE UPDATE ON user_boutique_assignments FOR EACH ROW EXECUTE FUNCTION update_date_modification();

-- ============================================================
-- 5. PEUPLER stock_boutiques depuis stock (si vide)
-- ============================================================
-- Si stock_boutiques est vide mais stock est peuplé,
-- on copie les quantités pour la boutique principale.
DO $$
DECLARE
  v_boutique_id INTEGER;
  v_stock_count INTEGER;
  v_sb_count    INTEGER;
BEGIN
  SELECT id INTO v_boutique_id FROM boutiques WHERE est_principale = true LIMIT 1;
  IF v_boutique_id IS NULL THEN
    SELECT id INTO v_boutique_id FROM boutiques LIMIT 1;
  END IF;
  IF v_boutique_id IS NULL THEN
    RAISE NOTICE 'Aucune boutique trouvée, skip stock_boutiques';
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_stock_count FROM stock;
  SELECT COUNT(*) INTO v_sb_count    FROM stock_boutiques WHERE boutique_id = v_boutique_id;

  IF v_stock_count > 0 AND v_sb_count = 0 THEN
    INSERT INTO stock_boutiques (boutique_id, produit_id, quantite_disponible, quantite_reservee, derniere_maj)
    SELECT v_boutique_id, s.produit_id, s.quantite_disponible, s.quantite_reservee, s.derniere_maj
    FROM stock s
    ON CONFLICT (boutique_id, produit_id) DO NOTHING;
    RAISE NOTICE 'stock_boutiques peuplé depuis stock pour boutique %', v_boutique_id;
  ELSE
    RAISE NOTICE 'stock_boutiques déjà peuplé (% entrées), skip', v_sb_count;
  END IF;
END$$;
