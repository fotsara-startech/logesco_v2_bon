-- CreateTable
CREATE TABLE "utilisateurs" (
    "id" SERIAL NOT NULL,
    "nom_utilisateur" TEXT NOT NULL,
    "email" TEXT,
    "mot_de_passe_hash" TEXT NOT NULL,
    "role_id" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,
    "date_derniere_connexion" TIMESTAMP(3),

    CONSTRAINT "utilisateurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "boutiques" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "adresse" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "description" TEXT,
    "est_principale" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_boutique_assignments" (
    "id" SERIAL NOT NULL,
    "utilisateur_id" INTEGER NOT NULL,
    "boutique_id" INTEGER NOT NULL,
    "role_id" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_boutique_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_boutiques" (
    "id" SERIAL NOT NULL,
    "boutique_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_disponible" INTEGER NOT NULL DEFAULT 0,
    "quantite_reservee" INTEGER NOT NULL DEFAULT 0,
    "derniere_maj" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stock_boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transferts_stock" (
    "id" SERIAL NOT NULL,
    "reference" TEXT NOT NULL,
    "source_boutique_id" INTEGER NOT NULL,
    "dest_boutique_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite" INTEGER NOT NULL,
    "notes" TEXT,
    "utilisateur_id" INTEGER NOT NULL,
    "date_transfert" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transferts_stock_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fournisseurs" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "personne_contact" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "adresse" TEXT,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fournisseurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clients" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "prenom" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "adresse" TEXT,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comptes_fournisseurs" (
    "id" SERIAL NOT NULL,
    "fournisseur_id" INTEGER NOT NULL,
    "solde_actuel" DOUBLE PRECISION NOT NULL DEFAULT 0.00,
    "limite_credit" DOUBLE PRECISION NOT NULL DEFAULT 0.00,
    "date_derniere_maj" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "comptes_fournisseurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comptes_clients" (
    "id" SERIAL NOT NULL,
    "client_id" INTEGER NOT NULL,
    "solde_actuel" DOUBLE PRECISION NOT NULL DEFAULT 0.00,
    "limite_credit" DOUBLE PRECISION NOT NULL DEFAULT 0.00,
    "date_derniere_maj" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "comptes_clients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "produits" (
    "id" SERIAL NOT NULL,
    "reference" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "prix_unitaire" DOUBLE PRECISION NOT NULL,
    "prix_achat" DOUBLE PRECISION,
    "code_barre" TEXT,
    "categorie_id" INTEGER,
    "seuil_stock_minimum" INTEGER NOT NULL DEFAULT 0,
    "est_actif" BOOLEAN NOT NULL DEFAULT true,
    "est_service" BOOLEAN NOT NULL DEFAULT false,
    "remise_max_autorisee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "gestion_peremption" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock" (
    "id" SERIAL NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_disponible" INTEGER NOT NULL DEFAULT 0,
    "quantite_reservee" INTEGER NOT NULL DEFAULT 0,
    "derniere_maj" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stock_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commandes_approvisionnement" (
    "id" SERIAL NOT NULL,
    "numero_commande" TEXT NOT NULL,
    "fournisseur_id" INTEGER NOT NULL,
    "boutique_id" INTEGER,
    "statut" TEXT NOT NULL DEFAULT 'en_attente',
    "date_commande" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_livraison_prevue" TIMESTAMP(3),
    "montant_total" DOUBLE PRECISION,
    "montant_paye" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "montant_restant" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "mode_paiement" TEXT NOT NULL DEFAULT 'credit',
    "notes" TEXT,

    CONSTRAINT "commandes_approvisionnement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "details_commandes_approvisionnement" (
    "id" SERIAL NOT NULL,
    "commande_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_commandee" INTEGER NOT NULL,
    "quantite_recue" INTEGER NOT NULL DEFAULT 0,
    "cout_unitaire" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "details_commandes_approvisionnement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ventes" (
    "id" SERIAL NOT NULL,
    "numero_vente" TEXT NOT NULL,
    "client_id" INTEGER,
    "vendeur_id" INTEGER,
    "session_id" INTEGER,
    "boutique_id" INTEGER,
    "date_vente" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sous_total" DOUBLE PRECISION NOT NULL,
    "montant_remise" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "montant_tva" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "taux_tva" DOUBLE PRECISION,
    "montant_total" DOUBLE PRECISION NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'terminee',
    "mode_paiement" TEXT NOT NULL DEFAULT 'comptant',
    "montant_paye" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "montant_restant" DOUBLE PRECISION NOT NULL DEFAULT 0,

    CONSTRAINT "ventes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "details_ventes" (
    "id" SERIAL NOT NULL,
    "vente_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" DOUBLE PRECISION NOT NULL,
    "prix_affiche" DOUBLE PRECISION NOT NULL,
    "remise_appliquee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "justification_remise" TEXT,
    "prix_total" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "details_ventes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions_comptes" (
    "id" SERIAL NOT NULL,
    "type_compte" TEXT NOT NULL,
    "compte_id" INTEGER NOT NULL,
    "type_transaction" TEXT NOT NULL,
    "montant" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "reference_id" INTEGER,
    "reference_type" TEXT,
    "date_transaction" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "solde_apres" DOUBLE PRECISION NOT NULL,
    "type_transaction_detail" TEXT,
    "vente_id" INTEGER,
    "vente_reference" TEXT,
    "boutique_id" INTEGER,

    CONSTRAINT "transactions_comptes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mouvements_stock" (
    "id" SERIAL NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "boutique_id" INTEGER,
    "type_mouvement" TEXT NOT NULL,
    "changement_quantite" INTEGER NOT NULL,
    "reference_id" INTEGER,
    "type_reference" TEXT,
    "date_mouvement" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,

    CONSTRAINT "mouvements_stock_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "parametres_entreprise" (
    "id" SERIAL NOT NULL,
    "nom_entreprise" TEXT NOT NULL,
    "adresse" TEXT NOT NULL,
    "localisation" TEXT,
    "telephone" TEXT,
    "email" TEXT,
    "nui_rccm" TEXT,
    "logo" TEXT,
    "slogan" TEXT,
    "langue_facture" TEXT NOT NULL DEFAULT 'fr',
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,
    "taux_tva" DOUBLE PRECISION,

    CONSTRAINT "parametres_entreprise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historique_recus" (
    "id" SERIAL NOT NULL,
    "vente_id" INTEGER NOT NULL,
    "numero_recu" TEXT NOT NULL,
    "format_impression" TEXT NOT NULL DEFAULT 'thermal',
    "contenu_recu" TEXT NOT NULL,
    "date_generation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,

    CONSTRAINT "historique_recus_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reimpressions_recus" (
    "id" SERIAL NOT NULL,
    "historique_recu_id" INTEGER NOT NULL,
    "format_impression" TEXT NOT NULL,
    "date_reimpression" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER,
    "motif_reimpression" TEXT,

    CONSTRAINT "reimpressions_recus_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "privileges" TEXT,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cash_registers" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "solde_initial" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "solde_actuel" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "utilisateur_id" INTEGER,
    "boutique_id" INTEGER,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,
    "date_ouverture" TIMESTAMP(3),
    "date_fermeture" TIMESTAMP(3),

    CONSTRAINT "cash_registers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cash_movements" (
    "id" SERIAL NOT NULL,
    "caisse_id" INTEGER NOT NULL,
    "session_id" INTEGER,
    "boutique_id" INTEGER,
    "type" TEXT NOT NULL,
    "montant" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "utilisateur_id" INTEGER,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "metadata" TEXT,

    CONSTRAINT "cash_movements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cash_sessions" (
    "id" SERIAL NOT NULL,
    "caisse_id" INTEGER NOT NULL,
    "utilisateur_id" INTEGER NOT NULL,
    "boutique_id" INTEGER,
    "solde_ouverture" DOUBLE PRECISION NOT NULL,
    "solde_fermeture" DOUBLE PRECISION,
    "date_ouverture" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_fermeture" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "metadata" TEXT,
    "solde_attendu" DOUBLE PRECISION,
    "ecart" DOUBLE PRECISION,

    CONSTRAINT "cash_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_inventories" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'BROUILLON',
    "categorie_id" INTEGER,
    "boutique_id" INTEGER,
    "utilisateur_id" INTEGER NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_debut" TIMESTAMP(3),
    "date_fin" TIMESTAMP(3),

    CONSTRAINT "stock_inventories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_items" (
    "id" SERIAL NOT NULL,
    "inventaire_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite_systeme" DOUBLE PRECISION NOT NULL,
    "quantite_comptee" DOUBLE PRECISION,
    "ecart" DOUBLE PRECISION,
    "prix_unitaire" DOUBLE PRECISION DEFAULT 0,
    "prix_achat" DOUBLE PRECISION DEFAULT 0,
    "commentaire" TEXT,
    "date_comptage" TIMESTAMP(3),
    "utilisateur_comptage_id" INTEGER,

    CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "movement_categories" (
    "id" SERIAL NOT NULL,
    "nom" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#6B7280',
    "icon" TEXT NOT NULL DEFAULT 'receipt',
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "movement_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "financial_movements" (
    "id" SERIAL NOT NULL,
    "reference" TEXT NOT NULL,
    "session_id" INTEGER,
    "boutique_id" INTEGER,
    "montant" DOUBLE PRECISION NOT NULL,
    "categorie_id" INTEGER NOT NULL,
    "description" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "utilisateur_id" INTEGER NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,

    CONSTRAINT "financial_movements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "movement_attachments" (
    "id" SERIAL NOT NULL,
    "mouvement_id" INTEGER NOT NULL,
    "file_name" TEXT NOT NULL,
    "original_name" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "file_path" TEXT NOT NULL,
    "uploaded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movement_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dates_peremption" (
    "id" SERIAL NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "date_peremption" TIMESTAMP(3) NOT NULL,
    "quantite" INTEGER NOT NULL DEFAULT 0,
    "numero_lot" TEXT,
    "date_entree" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,
    "est_epuise" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,
    "boutique_id" INTEGER,

    CONSTRAINT "dates_peremption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ventes_proforma" (
    "id" SERIAL NOT NULL,
    "numero_proforma" TEXT NOT NULL,
    "client_id" INTEGER,
    "vendeur_id" INTEGER,
    "boutique_id" INTEGER,
    "date_vente" TIMESTAMP(3),
    "sous_total" DOUBLE PRECISION NOT NULL,
    "montant_remise" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "montant_tva" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "taux_tva" DOUBLE PRECISION,
    "montant_total" DOUBLE PRECISION NOT NULL,
    "statut" TEXT NOT NULL DEFAULT 'brouillon',
    "mode_paiement" TEXT NOT NULL DEFAULT 'comptant',
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ventes_proforma_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "details_ventes_proforma" (
    "id" SERIAL NOT NULL,
    "proforma_id" INTEGER NOT NULL,
    "produit_id" INTEGER NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" DOUBLE PRECISION NOT NULL,
    "prix_affiche" DOUBLE PRECISION NOT NULL,
    "remise_appliquee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "justification_remise" TEXT,
    "prix_total" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "details_ventes_proforma_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "licenses" (
    "id" SERIAL NOT NULL,
    "license_key" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "subscription_type" TEXT NOT NULL,
    "device_fingerprint" TEXT,
    "issued_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_revoked" BOOLEAN NOT NULL DEFAULT false,
    "revoked_at" TIMESTAMP(3),
    "revoked_reason" TEXT,
    "activated_at" TIMESTAMP(3),
    "last_validated_at" TIMESTAMP(3),
    "validation_count" INTEGER NOT NULL DEFAULT 0,
    "metadata" TEXT,
    "signature" TEXT NOT NULL,
    "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "licenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "license_activations" (
    "id" SERIAL NOT NULL,
    "license_id" INTEGER NOT NULL,
    "device_fingerprint" TEXT NOT NULL,
    "device_info" TEXT,
    "activated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "is_successful" BOOLEAN NOT NULL DEFAULT true,
    "error_message" TEXT,

    CONSTRAINT "license_activations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "license_audit_logs" (
    "id" SERIAL NOT NULL,
    "license_id" INTEGER NOT NULL,
    "action" TEXT NOT NULL,
    "details" TEXT,
    "performed_by" TEXT,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "license_audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_nom_utilisateur_key" ON "utilisateurs"("nom_utilisateur");

-- CreateIndex
CREATE INDEX "idx_utilisateurs_nom" ON "utilisateurs"("nom_utilisateur");

-- CreateIndex
CREATE INDEX "idx_utilisateurs_role" ON "utilisateurs"("role_id");

-- CreateIndex
CREATE INDEX "idx_boutiques_principale" ON "boutiques"("est_principale");

-- CreateIndex
CREATE INDEX "idx_boutiques_active" ON "boutiques"("is_active");

-- CreateIndex
CREATE INDEX "idx_user_boutique_utilisateur" ON "user_boutique_assignments"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_user_boutique_boutique" ON "user_boutique_assignments"("boutique_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_boutique_assignments_utilisateur_id_boutique_id_key" ON "user_boutique_assignments"("utilisateur_id", "boutique_id");

-- CreateIndex
CREATE INDEX "idx_stock_boutique_boutique" ON "stock_boutiques"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_stock_boutique_produit" ON "stock_boutiques"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_boutiques_boutique_id_produit_id_key" ON "stock_boutiques"("boutique_id", "produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "transferts_stock_reference_key" ON "transferts_stock"("reference");

-- CreateIndex
CREATE INDEX "idx_transfert_source" ON "transferts_stock"("source_boutique_id");

-- CreateIndex
CREATE INDEX "idx_transfert_dest" ON "transferts_stock"("dest_boutique_id");

-- CreateIndex
CREATE INDEX "idx_transfert_produit" ON "transferts_stock"("produit_id");

-- CreateIndex
CREATE INDEX "idx_transfert_date" ON "transferts_stock"("date_transfert");

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
CREATE INDEX "idx_produits_gestion_peremption" ON "produits"("gestion_peremption");

-- CreateIndex
CREATE UNIQUE INDEX "stock_produit_id_key" ON "stock"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "commandes_approvisionnement_numero_commande_key" ON "commandes_approvisionnement"("numero_commande");

-- CreateIndex
CREATE INDEX "idx_commandes_statut" ON "commandes_approvisionnement"("statut");

-- CreateIndex
CREATE INDEX "idx_commandes_fournisseur_date" ON "commandes_approvisionnement"("fournisseur_id", "date_commande");

-- CreateIndex
CREATE INDEX "idx_commandes_boutique" ON "commandes_approvisionnement"("boutique_id");

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
CREATE INDEX "idx_ventes_session" ON "ventes"("session_id");

-- CreateIndex
CREATE INDEX "idx_ventes_boutique" ON "ventes"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_details_ventes_vente" ON "details_ventes"("vente_id");

-- CreateIndex
CREATE INDEX "idx_transactions_reference" ON "transactions_comptes"("reference_type", "reference_id");

-- CreateIndex
CREATE INDEX "idx_transactions_date" ON "transactions_comptes"("date_transaction");

-- CreateIndex
CREATE INDEX "idx_transactions_vente" ON "transactions_comptes"("vente_id");

-- CreateIndex
CREATE INDEX "idx_transactions_type_detail" ON "transactions_comptes"("type_transaction_detail");

-- CreateIndex
CREATE INDEX "idx_transactions_boutique" ON "transactions_comptes"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_mouvements_reference" ON "mouvements_stock"("type_reference", "reference_id");

-- CreateIndex
CREATE INDEX "idx_mouvements_type" ON "mouvements_stock"("type_mouvement");

-- CreateIndex
CREATE INDEX "idx_mouvements_stock_boutique" ON "mouvements_stock"("boutique_id");

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
CREATE INDEX "idx_cash_registers_boutique" ON "cash_registers"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_cash_movements_caisse" ON "cash_movements"("caisse_id");

-- CreateIndex
CREATE INDEX "idx_cash_movements_session" ON "cash_movements"("session_id");

-- CreateIndex
CREATE INDEX "idx_cash_movements_date" ON "cash_movements"("date_creation");

-- CreateIndex
CREATE INDEX "idx_cash_movements_type" ON "cash_movements"("type");

-- CreateIndex
CREATE INDEX "idx_cash_movements_boutique" ON "cash_movements"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_caisse" ON "cash_sessions"("caisse_id");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_utilisateur" ON "cash_sessions"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_date_ouverture" ON "cash_sessions"("date_ouverture");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_active" ON "cash_sessions"("is_active");

-- CreateIndex
CREATE INDEX "idx_cash_sessions_boutique" ON "cash_sessions"("boutique_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_inventories_nom_key" ON "stock_inventories"("nom");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_status" ON "stock_inventories"("status");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_type" ON "stock_inventories"("type");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_utilisateur" ON "stock_inventories"("utilisateur_id");

-- CreateIndex
CREATE INDEX "idx_stock_inventories_boutique" ON "stock_inventories"("boutique_id");

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
CREATE INDEX "idx_financial_movements_session" ON "financial_movements"("session_id");

-- CreateIndex
CREATE INDEX "idx_financial_movements_boutique" ON "financial_movements"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_financial_movements_date" ON "financial_movements"("date");

-- CreateIndex
CREATE INDEX "idx_financial_movements_montant" ON "financial_movements"("montant");

-- CreateIndex
CREATE INDEX "idx_movement_attachments_mouvement" ON "movement_attachments"("mouvement_id");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_produit" ON "dates_peremption"("produit_id");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_boutique" ON "dates_peremption"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_date" ON "dates_peremption"("date_peremption");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_epuise" ON "dates_peremption"("est_epuise");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_produit_date" ON "dates_peremption"("produit_id", "date_peremption");

-- CreateIndex
CREATE INDEX "idx_dates_peremption_boutique_date" ON "dates_peremption"("boutique_id", "date_peremption");

-- CreateIndex
CREATE UNIQUE INDEX "ventes_proforma_numero_proforma_key" ON "ventes_proforma"("numero_proforma");

-- CreateIndex
CREATE INDEX "idx_proformas_statut" ON "ventes_proforma"("statut");

-- CreateIndex
CREATE INDEX "idx_proformas_client" ON "ventes_proforma"("client_id");

-- CreateIndex
CREATE INDEX "idx_proformas_vendeur" ON "ventes_proforma"("vendeur_id");

-- CreateIndex
CREATE INDEX "idx_proformas_boutique" ON "ventes_proforma"("boutique_id");

-- CreateIndex
CREATE INDEX "idx_proformas_date" ON "ventes_proforma"("date_creation");

-- CreateIndex
CREATE INDEX "idx_details_proforma_proforma" ON "details_ventes_proforma"("proforma_id");

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

-- AddForeignKey
ALTER TABLE "utilisateurs" ADD CONSTRAINT "utilisateurs_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "user_roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_boutique_assignments" ADD CONSTRAINT "user_boutique_assignments_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "user_roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_boutique_assignments" ADD CONSTRAINT "user_boutique_assignments_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_boutique_assignments" ADD CONSTRAINT "user_boutique_assignments_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_boutiques" ADD CONSTRAINT "stock_boutiques_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_boutiques" ADD CONSTRAINT "stock_boutiques_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transferts_stock" ADD CONSTRAINT "transferts_stock_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transferts_stock" ADD CONSTRAINT "transferts_stock_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transferts_stock" ADD CONSTRAINT "transferts_stock_dest_boutique_id_fkey" FOREIGN KEY ("dest_boutique_id") REFERENCES "boutiques"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transferts_stock" ADD CONSTRAINT "transferts_stock_source_boutique_id_fkey" FOREIGN KEY ("source_boutique_id") REFERENCES "boutiques"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comptes_fournisseurs" ADD CONSTRAINT "comptes_fournisseurs_fournisseur_id_fkey" FOREIGN KEY ("fournisseur_id") REFERENCES "fournisseurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comptes_clients" ADD CONSTRAINT "comptes_clients_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "produits" ADD CONSTRAINT "produits_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock" ADD CONSTRAINT "stock_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commandes_approvisionnement" ADD CONSTRAINT "commandes_approvisionnement_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commandes_approvisionnement" ADD CONSTRAINT "commandes_approvisionnement_fournisseur_id_fkey" FOREIGN KEY ("fournisseur_id") REFERENCES "fournisseurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_commandes_approvisionnement" ADD CONSTRAINT "details_commandes_approvisionnement_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes_approvisionnement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_commandes_approvisionnement" ADD CONSTRAINT "details_commandes_approvisionnement_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes" ADD CONSTRAINT "ventes_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes" ADD CONSTRAINT "ventes_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes" ADD CONSTRAINT "ventes_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes" ADD CONSTRAINT "ventes_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "cash_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_ventes" ADD CONSTRAINT "details_ventes_vente_id_fkey" FOREIGN KEY ("vente_id") REFERENCES "ventes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_ventes" ADD CONSTRAINT "details_ventes_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions_comptes" ADD CONSTRAINT "transactions_comptes_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mouvements_stock" ADD CONSTRAINT "mouvements_stock_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mouvements_stock" ADD CONSTRAINT "mouvements_stock_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historique_recus" ADD CONSTRAINT "historique_recus_vente_id_fkey" FOREIGN KEY ("vente_id") REFERENCES "ventes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reimpressions_recus" ADD CONSTRAINT "reimpressions_recus_historique_recu_id_fkey" FOREIGN KEY ("historique_recu_id") REFERENCES "historique_recus"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_registers" ADD CONSTRAINT "cash_registers_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_registers" ADD CONSTRAINT "cash_registers_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_movements" ADD CONSTRAINT "cash_movements_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_movements" ADD CONSTRAINT "cash_movements_caisse_id_fkey" FOREIGN KEY ("caisse_id") REFERENCES "cash_registers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_movements" ADD CONSTRAINT "cash_movements_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "cash_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_movements" ADD CONSTRAINT "cash_movements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_sessions" ADD CONSTRAINT "cash_sessions_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_sessions" ADD CONSTRAINT "cash_sessions_caisse_id_fkey" FOREIGN KEY ("caisse_id") REFERENCES "cash_registers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_sessions" ADD CONSTRAINT "cash_sessions_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_inventories" ADD CONSTRAINT "stock_inventories_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_inventories" ADD CONSTRAINT "stock_inventories_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_inventories" ADD CONSTRAINT "stock_inventories_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_utilisateur_comptage_id_fkey" FOREIGN KEY ("utilisateur_comptage_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_inventaire_id_fkey" FOREIGN KEY ("inventaire_id") REFERENCES "stock_inventories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_movements" ADD CONSTRAINT "financial_movements_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "movement_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_movements" ADD CONSTRAINT "financial_movements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_movements" ADD CONSTRAINT "financial_movements_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_movements" ADD CONSTRAINT "financial_movements_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "cash_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movement_attachments" ADD CONSTRAINT "movement_attachments_mouvement_id_fkey" FOREIGN KEY ("mouvement_id") REFERENCES "financial_movements"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dates_peremption" ADD CONSTRAINT "dates_peremption_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dates_peremption" ADD CONSTRAINT "dates_peremption_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes_proforma" ADD CONSTRAINT "ventes_proforma_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes_proforma" ADD CONSTRAINT "ventes_proforma_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventes_proforma" ADD CONSTRAINT "ventes_proforma_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_ventes_proforma" ADD CONSTRAINT "details_ventes_proforma_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "details_ventes_proforma" ADD CONSTRAINT "details_ventes_proforma_proforma_id_fkey" FOREIGN KEY ("proforma_id") REFERENCES "ventes_proforma"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "license_activations" ADD CONSTRAINT "license_activations_license_id_fkey" FOREIGN KEY ("license_id") REFERENCES "licenses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "license_audit_logs" ADD CONSTRAINT "license_audit_logs_license_id_fkey" FOREIGN KEY ("license_id") REFERENCES "licenses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
