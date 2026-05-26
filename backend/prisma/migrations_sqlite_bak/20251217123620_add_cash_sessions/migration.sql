-- CreateTable
CREATE TABLE "cash_sessions" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "caisse_id" INTEGER NOT NULL,
    "utilisateur_id" INTEGER NOT NULL,
    "solde_ouverture" REAL NOT NULL,
    "solde_fermeture" REAL,
    "date_ouverture" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_fermeture" DATETIME,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "metadata" TEXT,
    CONSTRAINT "cash_sessions_caisse_id_fkey" FOREIGN KEY ("caisse_id") REFERENCES "cash_registers" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "cash_sessions_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "idx_cash_sessions_caisse" ON "cash_sessions"("caisse_id");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_utilisateur" ON "cash_sessions"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_date_ouverture" ON "cash_sessions"("date_ouverture");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_active" ON "cash_sessions"("is_active");
