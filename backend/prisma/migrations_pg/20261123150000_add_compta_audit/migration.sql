-- LOGESCO - Journal d'audit comptable (Neon). Idempotent. Source: src/services/compta-schema-pg-audit.js

CREATE TABLE IF NOT EXISTS "compta_audit" (
    "id" SERIAL NOT NULL,
    "date_action" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,
    "action" TEXT NOT NULL,
    "entite_type" TEXT,
    "entite_id" INTEGER,
    "details" TEXT,
    "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "compta_audit_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "idx_compta_audit_date" ON "compta_audit"("date_action");
CREATE INDEX IF NOT EXISTS "idx_compta_audit_action" ON "compta_audit"("action");
