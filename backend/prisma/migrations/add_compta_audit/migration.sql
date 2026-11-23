-- Journal d'audit de la comptabilité
CREATE TABLE IF NOT EXISTS "compta_audit" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "date_action" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,
    "action" TEXT NOT NULL,
    "entite_type" TEXT,
    "entite_id" INTEGER,
    "details" TEXT,
    "date_modification" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "idx_compta_audit_date" ON "compta_audit"("date_action");
CREATE INDEX IF NOT EXISTS "idx_compta_audit_action" ON "compta_audit"("action");
