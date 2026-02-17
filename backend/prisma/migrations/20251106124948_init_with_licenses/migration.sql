-- CreateTable
CREATE TABLE "utilisateurs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom_utilisateur" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "mot_de_passe_hash" TEXT NOT NULL,
    "role_id" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    "date_derniere_connexion" DATETIME,
    CONSTRAINT "utilisateurs_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "user_roles" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "fournisseurs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "personne_contact" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "adresse" TEXT,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "clients" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "prenom" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "adresse" TEXT,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "comptes_fournisseurs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "fournisseur_id" INTEGER NOT NULL,
    "solde_actuel" REAL NOT NULL DEFAULT 0.00,
    "limite_credit" REAL NOT NULL DEFAULT 0.00,
    "date_derniere_maj" DATETIME NOT NULL,
    CONSTRAINT "comptes_fournisseurs_fournisseur_id_fkey" FOREIGN KEY ("fournisseur_id") REFERENCES "fournisseurs" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "comptes_clients" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "client_id" INTEGER NOT NULL,
    "solde_actuel" REAL NOT NULL DEFAULT 0.00,
    "limite_credit" REAL NOT NULL DEFAULT 0.00,
    "date_derniere_maj" DATETIME NOT NULL,
    CONSTRAINT "comptes_clients_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "categories" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "produits" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "reference" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "prix_unitaire" REAL NOT NULL,
    "prix_achat" REAL,
    "code_barre" TEXT,
    "categorie_id" INTEGER,
    "seuil_stock_minimum" INTEGER NOT NULL DEFAULT 0,
    "est_actif" BOOLEAN NOT NULL DEFAULT true,
    "est_service" BOOLEAN NOT NULL DEFAULT false,
    "remise_max_autorisee" REAL NOT NULL DEFAULT 0,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    CONSTRAINT "produits_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "categories" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "stock" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "produit_id" INTEGER NOT NULL,
    "quantite_disponible" INTEGER NOT NULL DEFAULT 0,
    "quantite_reservee" INTEGER NOT NULL DEFAULT 0,
    "derniere_maj" DATETIME NOT NULL,
    CONSTRAINT "stock_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "commandes_approvisionnement" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "numero_commande" TEXT NOT NULL,
    "fournisseur_id" INTEGER NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'en_attente',
    "date_commande" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_livraison_prevue" DATETIME,
    "montant_total" REAL,
    "mode_paiement" TEXT NOT NULL DEFAULT 'credit',
    "notes" TEXT,
    CONSTRAINT "commandes_approvisionnement_fournisseur_id_fkey" FOREIGN KEY ("fournisseur_id") REFERENCES "fournisseurs" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "details_commandes_approvisionnement" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "commande_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_commandee" INTEGER NOT NULL,
    "quantite_recue" INTEGER NOT NULL DEFAULT 0,
    "cout_unitaire" REAL NOT NULL,
    CONSTRAINT "details_commandes_approvisionnement_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "details_commandes_approvisionnement_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes_approvisionnement" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ventes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "numero_vente" TEXT NOT NULL,
    "client_id" INTEGER,
    "vendeur_id" INTEGER,
    "date_vente" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sous_total" REAL NOT NULL,
    "montant_remise" REAL NOT NULL DEFAULT 0,
    "montant_total" REAL NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'terminee',
    "mode_paiement" TEXT NOT NULL DEFAULT 'comptant',
    "montant_paye" REAL NOT NULL DEFAULT 0,
    "montant_restant" REAL NOT NULL DEFAULT 0,
    CONSTRAINT "ventes_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "ventes_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "utilisateurs" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "details_ventes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "vente_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" REAL NOT NULL,
    "prix_affiche" REAL NOT NULL,
    "remise_appliquee" REAL NOT NULL DEFAULT 0,
    "justification_remise" TEXT,
    "prix_total" REAL NOT NULL,
    CONSTRAINT "details_ventes_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "details_ventes_vente_id_fkey" FOREIGN KEY ("vente_id") REFERENCES "ventes" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "transactions_comptes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "type_compte" TEXT NOT NULL,
    "compte_id" INTEGER NOT NULL,
    "type_transaction" TEXT NOT NULL,
    "montant" REAL NOT NULL,
    "description" TEXT,
    "reference_id" INTEGER,
    "reference_type" TEXT,
    "date_transaction" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "solde_apres" REAL NOT NULL
);

-- CreateTable
CREATE TABLE "mouvements_stock" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "produit_id" INTEGER NOT NULL,
    "type_mouvement" TEXT NOT NULL,
    "changement_quantite" INTEGER NOT NULL,
    "reference_id" INTEGER,
    "type_reference" TEXT,
    "date_mouvement" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,
    CONSTRAINT "mouvements_stock_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "parametres_entreprise" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom_entreprise" TEXT NOT NULL,
    "adresse" TEXT NOT NULL,
    "localisation" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "nui_rccm" TEXT,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "historique_recus" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "vente_id" INTEGER NOT NULL,
    "numero_recu" TEXT NOT NULL,
    "format_impression" TEXT NOT NULL DEFAULT 'thermal',
    "contenu_recu" TEXT NOT NULL,
    "date_generation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,
    CONSTRAINT "historique_recus_vente_id_fkey" FOREIGN KEY ("vente_id") REFERENCES "ventes" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "reimpressions_recus" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "historique_recu_id" INTEGER NOT NULL,
    "format_impression" TEXT NOT NULL,
    "date_reimpression" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,
    "motif_reimpression" TEXT,
    CONSTRAINT "reimpressions_recus_historique_recu_id_fkey" FOREIGN KEY ("historique_recu_id") REFERENCES "historique_recus" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "user_roles" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "privileges" TEXT,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "cash_registers" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "solde_initial" REAL NOT NULL DEFAULT 0,
    "solde_actuel" REAL NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "utilisateur_id" INTEGER,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    "date_ouverture" DATETIME,
    "date_fermeture" DATETIME,
    CONSTRAINT "cash_registers_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "cash_movements" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "caisse_id" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "montant" REAL NOT NULL,
    "description" TEXT,
    "utilisateur_id" INTEGER,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "metadata" TEXT,
    CONSTRAINT "cash_movements_caisse_id_fkey" FOREIGN KEY ("caisse_id") REFERENCES "cash_registers" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "cash_movements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "stock_inventories" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'BROUILLON',
    "categorie_id" INTEGER,
    "utilisateur_id" INTEGER NOT NULL,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_debut" DATETIME,
    "date_fin" DATETIME,
    CONSTRAINT "stock_inventories_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "categories" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "stock_inventories_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "inventory_items" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "inventaire_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_systeme" REAL NOT NULL,
    "quantite_comptee" REAL,
    "ecart" REAL,
    "prix_unitaire" REAL DEFAULT 0,
    "prix_achat" REAL DEFAULT 0,
    "commentaire" TEXT,
    "date_comptage" DATETIME,
    "utilisateur_comptage_id" INTEGER,
    CONSTRAINT "inventory_items_inventaire_id_fkey" FOREIGN KEY ("inventaire_id") REFERENCES "stock_inventories" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "inventory_items_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "inventory_items_utilisateur_comptage_id_fkey" FOREIGN KEY ("utilisateur_comptage_id") REFERENCES "utilisateurs" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "movement_categories" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nom" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#6B7280',
    "icon" TEXT NOT NULL DEFAULT 'receipt',
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "financial_movements" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "reference" TEXT NOT NULL,
    "montant" REAL NOT NULL,
    "categorie_id" INTEGER NOT NULL,
    "description" TEXT NOT NULL,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER NOT NULL,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL,
    "notes" TEXT,
    CONSTRAINT "financial_movements_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "movement_categories" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "financial_movements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "movement_attachments" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "mouvement_id" INTEGER NOT NULL,
    "file_name" TEXT NOT NULL,
    "original_name" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "file_path" TEXT NOT NULL,
    "uploaded_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "movement_attachments_mouvement_id_fkey" FOREIGN KEY ("mouvement_id") REFERENCES "financial_movements" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "licenses" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "license_key" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "subscription_type" TEXT NOT NULL,
    "device_fingerprint" TEXT,
    "issued_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" DATETIME NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_revoked" BOOLEAN NOT NULL DEFAULT false,
    "revoked_at" DATETIME,
    "revoked_reason" TEXT,
    "activated_at" DATETIME,
    "last_validated_at" DATETIME,
    "validation_count" INTEGER NOT NULL DEFAULT 0,
    "metadata" TEXT,
    "signature" TEXT NOT NULL,
    "date_creation" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "license_activations" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "license_id" INTEGER NOT NULL,
    "device_fingerprint" TEXT NOT NULL,
    "device_info" TEXT,
    "activated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "is_successful" BOOLEAN NOT NULL DEFAULT true,
    "error_message" TEXT,
    CONSTRAINT "license_activations_license_id_fkey" FOREIGN KEY ("license_id") REFERENCES "licenses" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "license_audit_logs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "license_id" INTEGER NOT NULL,
    "action" TEXT NOT NULL,
    "details" TEXT,
    "performed_by" TEXT,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "license_audit_logs_license_id_fkey" FOREIGN KEY ("license_id") REFERENCES "licenses" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_nom_utilisateur_key" ON "utilisateurs"("nom_utilisateur");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_email_key" ON "utilisateurs"("email");

-- CreateIndex
CREATE INDEX "idx_utilisateurs_email" ON "utilisateurs"("email");

-- CreateIndex
CREATE INDEX "idx_utilisateurs_nom" ON "utilisateurs"("nom_utilisateur");

-- CreateIndex
CREATE INDEX "idx_utilisateurs_role" ON "utilisateurs"("role_id");

-- CreateIndex
CREATE INDEX "idx_fournisseurs_email" ON "fournisseurs"("email");

-- CreateIndex
CREATE INDEX "idx_fournisseurs_telephone" ON "fournisseurs"("telephone");

-- CreateIndex
CREATE INDEX "idx_clients_nom_prenom" ON "clients"("nom", "prenom");

-- CreateIndex
CREATE INDEX "idx_clients_email" ON "clients"("email");

-- CreateIndex
CREATE INDEX "idx_clients_telephone" ON "clients"("telephone");

-- CreateIndex
CREATE UNIQUE INDEX "comptes_fournisseurs_fournisseur_id_key" ON "comptes_fournisseurs"("fournisseur_id");

-- CreateIndex
CREATE UNIQUE INDEX "comptes_clients_client_id_key" ON "comptes_clients"("client_id");

-- CreateIndex
CREATE UNIQUE INDEX "categories_nom_key" ON "categories"("nom");

-- CreateIndex
CREATE INDEX "idx_categories_nom" ON "categories"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "produits_reference_key" ON "produits"("reference");

-- CreateIndex
CREATE INDEX "idx_produits_stock_minimum" ON "produits"("seuil_stock_minimum");

-- CreateIndex
CREATE INDEX "idx_produits_nom_actif" ON "produits"("nom", "est_actif");

-- CreateIndex
CREATE INDEX "idx_produits_actif" ON "produits"("est_actif");

-- CreateIndex
CREATE INDEX "idx_produits_categorie" ON "produits"("categorie_id");

-- CreateIndex
CREATE INDEX "idx_produits_code_barre" ON "produits"("code_barre");

-- CreateIndex
CREATE INDEX "idx_produits_service" ON "produits"("est_service");

-- CreateIndex
CREATE UNIQUE INDEX "stock_produit_id_key" ON "stock"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "commandes_approvisionnement_numero_commande_key" ON "commandes_approvisionnement"("numero_commande");

-- CreateIndex
CREATE INDEX "idx_commandes_statut" ON "commandes_approvisionnement"("statut");

-- CreateIndex
CREATE INDEX "idx_commandes_fournisseur_date" ON "commandes_approvisionnement"("fournisseur_id", "date_commande");

-- CreateIndex
CREATE INDEX "idx_details_commandes_commande" ON "details_commandes_approvisionnement"("commande_id");

-- CreateIndex
CREATE UNIQUE INDEX "ventes_numero_vente_key" ON "ventes"("numero_vente");

-- CreateIndex
CREATE INDEX "idx_ventes_mode_paiement" ON "ventes"("mode_paiement");

-- CreateIndex
CREATE INDEX "idx_ventes_statut" ON "ventes"("statut");

-- CreateIndex
CREATE INDEX "idx_ventes_client_date" ON "ventes"("client_id", "date_vente");

-- CreateIndex
CREATE INDEX "idx_ventes_vendeur_date" ON "ventes"("vendeur_id", "date_vente");

-- CreateIndex
CREATE INDEX "idx_details_ventes_vente" ON "details_ventes"("vente_id");

-- CreateIndex
CREATE INDEX "idx_transactions_reference" ON "transactions_comptes"("reference_type", "reference_id");

-- CreateIndex
CREATE INDEX "idx_transactions_date" ON "transactions_comptes"("date_transaction");

-- CreateIndex
CREATE INDEX "idx_mouvements_reference" ON "mouvements_stock"("type_reference", "reference_id");

-- CreateIndex
CREATE INDEX "idx_mouvements_type" ON "mouvements_stock"("type_mouvement");

-- CreateIndex
CREATE UNIQUE INDEX "historique_recus_numero_recu_key" ON "historique_recus"("numero_recu");

-- CreateIndex
CREATE INDEX "idx_historique_recu_vente" ON "historique_recus"("vente_id");

-- CreateIndex
CREATE INDEX "idx_historique_recu_numero" ON "historique_recus"("numero_recu");

-- CreateIndex
CREATE INDEX "idx_historique_recu_date" ON "historique_recus"("date_generation");

-- CreateIndex
CREATE INDEX "idx_reimpression_historique" ON "reimpressions_recus"("historique_recu_id");

-- CreateIndex
CREATE INDEX "idx_reimpression_date" ON "reimpressions_recus"("date_reimpression");

-- CreateIndex
CREATE UNIQUE INDEX "user_roles_nom_key" ON "user_roles"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "cash_registers_nom_key" ON "cash_registers"("nom");

-- CreateIndex
CREATE INDEX "idx_cash_registers_nom" ON "cash_registers"("nom");

-- CreateIndex
CREATE INDEX "idx_cash_registers_utilisateur" ON "cash_registers"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_cash_movements_caisse" ON "cash_movements"("caisse_id");

-- CreateIndex
CREATE INDEX "idx_cash_movements_date" ON "cash_movements"("date_creation");

-- CreateIndex
CREATE INDEX "idx_cash_movements_type" ON "cash_movements"("type");

-- CreateIndex
CREATE UNIQUE INDEX "stock_inventories_nom_key" ON "stock_inventories"("nom");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_status" ON "stock_inventories"("status");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_type" ON "stock_inventories"("type");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_utilisateur" ON "stock_inventories"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_date" ON "stock_inventories"("date_creation");

-- CreateIndex
CREATE INDEX "idx_inventory_items_inventaire" ON "inventory_items"("inventaire_id");

-- CreateIndex
CREATE INDEX "idx_inventory_items_produit" ON "inventory_items"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "movement_categories_nom_key" ON "movement_categories"("nom");

-- CreateIndex
CREATE INDEX "idx_movement_categories_nom" ON "movement_categories"("nom");

-- CreateIndex
CREATE INDEX "idx_movement_categories_active" ON "movement_categories"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "financial_movements_reference_key" ON "financial_movements"("reference");

-- CreateIndex
CREATE INDEX "idx_financial_movements_reference" ON "financial_movements"("reference");

-- CreateIndex
CREATE INDEX "idx_financial_movements_categorie" ON "financial_movements"("categorie_id");

-- CreateIndex
CREATE INDEX "idx_financial_movements_utilisateur" ON "financial_movements"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_financial_movements_date" ON "financial_movements"("date");

-- CreateIndex
CREATE INDEX "idx_financial_movements_montant" ON "financial_movements"("montant");

-- CreateIndex
CREATE INDEX "idx_movement_attachments_mouvement" ON "movement_attachments"("mouvement_id");

-- CreateIndex
CREATE UNIQUE INDEX "licenses_license_key_key" ON "licenses"("license_key");

-- CreateIndex
CREATE INDEX "idx_licenses_key" ON "licenses"("license_key");

-- CreateIndex
CREATE INDEX "idx_licenses_user" ON "licenses"("user_id");

-- CreateIndex
CREATE INDEX "idx_licenses_type" ON "licenses"("subscription_type");

-- CreateIndex
CREATE INDEX "idx_licenses_status" ON "licenses"("is_active", "is_revoked");

-- CreateIndex
CREATE INDEX "idx_licenses_expiry" ON "licenses"("expires_at");

-- CreateIndex
CREATE INDEX "idx_licenses_device" ON "licenses"("device_fingerprint");

-- CreateIndex
CREATE INDEX "idx_license_activations_license" ON "license_activations"("license_id");

-- CreateIndex
CREATE INDEX "idx_license_activations_device" ON "license_activations"("device_fingerprint");

-- CreateIndex
CREATE INDEX "idx_license_activations_date" ON "license_activations"("activated_at");

-- CreateIndex
CREATE INDEX "idx_license_audit_license" ON "license_audit_logs"("license_id");

-- CreateIndex
CREATE INDEX "idx_license_audit_action" ON "license_audit_logs"("action");

-- CreateIndex
CREATE INDEX "idx_license_audit_timestamp" ON "license_audit_logs"("timestamp");
