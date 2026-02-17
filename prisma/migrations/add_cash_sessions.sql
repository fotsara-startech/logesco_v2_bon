-- Migration pour ajouter les sessions de caisse
-- Créé le: $(date)

-- Créer la table des sessions de caisse
CREATE TABLE IF NOT EXISTS cash_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    caisse_id INTEGER NOT NULL,
    utilisateur_id INTEGER NOT NULL,
    solde_ouverture REAL NOT NULL DEFAULT 0,
    solde_fermeture REAL,
    date_ouverture DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_fermeture DATETIME,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    metadata TEXT,
    
    FOREIGN KEY (caisse_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_cash_sessions_caisse ON cash_sessions(caisse_id);
CREATE INDEX IF NOT EXISTS idx_cash_sessions_utilisateur ON cash_sessions(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_cash_sessions_date_ouverture ON cash_sessions(date_ouverture);
CREATE INDEX IF NOT EXISTS idx_cash_sessions_active ON cash_sessions(is_active);

-- Ajouter des types de mouvements pour les sessions
UPDATE cash_movements SET type = 'ouverture_session' WHERE type = 'ouverture' AND description LIKE '%session%';
UPDATE cash_movements SET type = 'fermeture_session' WHERE type = 'fermeture' AND description LIKE '%session%';