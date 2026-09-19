-- Crée les tables ventes_proforma / details_ventes_proforma.
-- Ces tables sont déclarées dans schema.prisma (feature "proforma") mais
-- n'ont jamais eu de migration formelle : elles n'apparaissaient que dans le
-- schéma appliqué via `prisma db push` sur une base neuve. Tout client
-- existant qui a fait sa première installation avant l'ajout de cette
-- fonctionnalité n'a jamais reçu ces tables lors des mises à jour suivantes.

-- CreateTable
CREATE TABLE IF NOT EXISTS "ventes_proforma" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "numero_proforma" TEXT NOT NULL,
    "client_id" INTEGER,
    "vendeur_id" INTEGER,
    "boutique_id" INTEGER,
    "date_vente" DATETIME,
    "sous_total" REAL NOT NULL,
    "montant_remise" REAL NOT NULL DEFAULT 0,
    "montant_tva" REAL NOT NULL DEFAULT 0,
    "taux_tva" REAL,
    "montant_total" REAL NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'brouillon',
    "mode_paiement" TEXT NOT NULL DEFAULT 'comptant',
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    CONSTRAINT "ventes_proforma_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "ventes_proforma_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "utilisateurs" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "ventes_proforma_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "details_ventes_proforma" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "proforma_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" REAL NOT NULL,
    "prix_affiche" REAL NOT NULL,
    "remise_appliquee" REAL NOT NULL DEFAULT 0,
    "justification_remise" TEXT,
    "prix_total" REAL NOT NULL,
    "date_modification" DATETIME,
    CONSTRAINT "details_ventes_proforma_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "details_ventes_proforma_proforma_id_fkey" FOREIGN KEY ("proforma_id") REFERENCES "ventes_proforma" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "ventes_proforma_numero_proforma_key" ON "ventes_proforma"("numero_proforma");
CREATE INDEX IF NOT EXISTS "idx_proformas_statut" ON "ventes_proforma"("statut");
CREATE INDEX IF NOT EXISTS "idx_proformas_client" ON "ventes_proforma"("client_id");
CREATE INDEX IF NOT EXISTS "idx_proformas_vendeur" ON "ventes_proforma"("vendeur_id");
CREATE INDEX IF NOT EXISTS "idx_proformas_boutique" ON "ventes_proforma"("boutique_id");
CREATE INDEX IF NOT EXISTS "idx_proformas_date" ON "ventes_proforma"("date_creation");

CREATE INDEX IF NOT EXISTS "idx_details_proforma_proforma" ON "details_ventes_proforma"("proforma_id");
CREATE INDEX IF NOT EXISTS "idx_details_ventes_proforma_date_modification" ON "details_ventes_proforma"("date_modification");
