-- Migration pour les nouveaux modules : Utilisateurs, Caisses, Inventaire
-- Date: 2024-10-29

-- =====================================================
-- TABLE DES UTILISATEURS ET RÔLES
-- =====================================================

-- Table des rôles utilisateur
CREATE TABLE IF NOT EXISTS user_roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    privileges TEXT, -- JSON des privilèges
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom_utilisateur VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_derniere_connexion DATETIME,
    FOREIGN KEY (role_id) REFERENCES user_roles(id)
);

-- =====================================================
-- TABLE DES CAISSES
-- =====================================================

-- Table des caisses
CREATE TABLE IF NOT EXISTS cash_registers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    solde_initial DECIMAL(10,2) DEFAULT 0.00,
    solde_actuel DECIMAL(10,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    utilisateur_id INTEGER,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_ouverture DATETIME,
    date_fermeture DATETIME,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id)
);

-- Table des mouvements de caisse
CREATE TABLE IF NOT EXISTS cash_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    caisse_id INTEGER NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'ouverture', 'fermeture', 'entree', 'sortie', 'vente'
    montant DECIMAL(10,2) NOT NULL,
    description TEXT,
    utilisateur_id INTEGER,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT, -- JSON pour données supplémentaires
    FOREIGN KEY (caisse_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES users(id)
);

-- =====================================================
-- TABLES D'INVENTAIRE
-- =====================================================

-- Table des inventaires
CREATE TABLE IF NOT EXISTS stock_inventories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL, -- 'PARTIEL', 'TOTAL'
    status VARCHAR(20) DEFAULT 'BROUILLON', -- 'BROUILLON', 'EN_COURS', 'TERMINE', 'CLOTURE'
    categorie_id INTEGER,
    utilisateur_id INTEGER NOT NULL,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_debut DATETIME,
    date_fin DATETIME,
    FOREIGN KEY (categorie_id) REFERENCES categories(id),
    FOREIGN KEY (utilisateur_id) REFERENCES users(id)
);

-- Table des articles d'inventaire
CREATE TABLE IF NOT EXISTS inventory_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inventaire_id INTEGER NOT NULL,
    produit_id INTEGER NOT NULL,
    quantite_systeme DECIMAL(10,2) NOT NULL,
    quantite_comptee DECIMAL(10,2),
    ecart DECIMAL(10,2),
    commentaire TEXT,
    date_comptage DATETIME,
    utilisateur_comptage_id INTEGER,
    FOREIGN KEY (inventaire_id) REFERENCES stock_inventories(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES products(id),
    FOREIGN KEY (utilisateur_comptage_id) REFERENCES users(id)
);

-- =====================================================
-- INSERTION DES DONNÉES INITIALES
-- =====================================================

-- Insertion des rôles par défaut
INSERT OR IGNORE INTO user_roles (nom, display_name, is_admin, privileges) VALUES
('admin', 'Administrateur', TRUE, '{"canManageUsers":true,"canManageProducts":true,"canManageSales":true,"canManageInventory":true,"canManageReports":true,"canManageCompanySettings":true,"canManageCashRegisters":true,"canViewReports":true,"canMakeSales":true,"canManageStock":true}'),
('manager', 'Gestionnaire', FALSE, '{"canManageUsers":false,"canManageProducts":true,"canManageSales":true,"canManageInventory":true,"canManageReports":true,"canManageCompanySettings":false,"canManageCashRegisters":true,"canViewReports":true,"canMakeSales":true,"canManageStock":true}'),
('cashier', 'Caissier', FALSE, '{"canManageUsers":false,"canManageProducts":false,"canManageSales":true,"canManageInventory":false,"canManageReports":false,"canManageCompanySettings":false,"canManageCashRegisters":false,"canViewReports":false,"canMakeSales":true,"canManageStock":false}'),
('stock_manager', 'Gestionnaire de Stock', FALSE, '{"canManageUsers":false,"canManageProducts":true,"canManageSales":false,"canManageInventory":true,"canManageReports":false,"canManageCompanySettings":false,"canManageCashRegisters":false,"canViewReports":true,"canMakeSales":false,"canManageStock":true}');

-- Insertion de l'utilisateur admin par défaut (mot de passe: admin123)
INSERT OR IGNORE INTO users (nom_utilisateur, email, mot_de_passe_hash, role_id) VALUES
('admin', 'admin@logesco.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1);

-- Insertion de caisses par défaut
INSERT OR IGNORE INTO cash_registers (nom, description, is_active) VALUES
('Caisse Principale', 'Caisse principale du magasin', TRUE),
('Caisse Secondaire', 'Caisse pour les périodes de pointe', TRUE);

-- =====================================================
-- INDEX POUR OPTIMISATION
-- =====================================================

-- Index pour les utilisateurs
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_nom_utilisateur ON users(nom_utilisateur);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);

-- Index pour les caisses
CREATE INDEX IF NOT EXISTS idx_cash_registers_nom ON cash_registers(nom);
CREATE INDEX IF NOT EXISTS idx_cash_registers_utilisateur_id ON cash_registers(utilisateur_id);

-- Index pour les mouvements de caisse
CREATE INDEX IF NOT EXISTS idx_cash_movements_caisse_id ON cash_movements(caisse_id);
CREATE INDEX IF NOT EXISTS idx_cash_movements_date_creation ON cash_movements(date_creation);
CREATE INDEX IF NOT EXISTS idx_cash_movements_type ON cash_movements(type);

-- Index pour les inventaires
CREATE INDEX IF NOT EXISTS idx_stock_inventories_status ON stock_inventories(status);
CREATE INDEX IF NOT EXISTS idx_stock_inventories_type ON stock_inventories(type);
CREATE INDEX IF NOT EXISTS idx_stock_inventories_utilisateur_id ON stock_inventories(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_stock_inventories_date_creation ON stock_inventories(date_creation);

-- Index pour les articles d'inventaire
CREATE INDEX IF NOT EXISTS idx_inventory_items_inventaire_id ON inventory_items(inventaire_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_produit_id ON inventory_items(produit_id);

-- =====================================================
-- TRIGGERS POUR MISE À JOUR AUTOMATIQUE
-- =====================================================

-- Trigger pour mettre à jour date_modification des utilisateurs
CREATE TRIGGER IF NOT EXISTS update_users_date_modification
    AFTER UPDATE ON users
    FOR EACH ROW
BEGIN
    UPDATE users SET date_modification = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger pour mettre à jour date_modification des caisses
CREATE TRIGGER IF NOT EXISTS update_cash_registers_date_modification
    AFTER UPDATE ON cash_registers
    FOR EACH ROW
BEGIN
    UPDATE cash_registers SET date_modification = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger pour calculer automatiquement l'écart dans inventory_items
CREATE TRIGGER IF NOT EXISTS calculate_inventory_ecart
    AFTER UPDATE OF quantite_comptee ON inventory_items
    FOR EACH ROW
    WHEN NEW.quantite_comptee IS NOT NULL
BEGIN
    UPDATE inventory_items 
    SET ecart = NEW.quantite_comptee - NEW.quantite_systeme 
    WHERE id = NEW.id;
END;