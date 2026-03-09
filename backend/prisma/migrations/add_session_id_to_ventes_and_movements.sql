-- Migration: Ajout de session_id aux tables ventes et cash_movements

-- Ajouter session_id à la table ventes
ALTER TABLE ventes ADD COLUMN session_id INTEGER;

-- Ajouter session_id à la table cash_movements
ALTER TABLE cash_movements ADD COLUMN session_id INTEGER;

-- Créer les index
CREATE INDEX idx_ventes_session ON ventes(session_id);
CREATE INDEX idx_cash_movements_session ON cash_movements(session_id);

-- Ajouter les contraintes de clé étrangère (optionnel, peut être fait plus tard)
-- ALTER TABLE ventes ADD CONSTRAINT fk_ventes_session FOREIGN KEY (session_id) REFERENCES cash_sessions(id);
-- ALTER TABLE cash_movements ADD CONSTRAINT fk_cash_movements_session FOREIGN KEY (session_id) REFERENCES cash_sessions(id);
