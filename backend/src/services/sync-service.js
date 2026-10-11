/**
 * SyncService V2 — Event Sourcing + Hybrid Mode
 * Synchronisation bidirectionnelle SQLite local <-> Neon cloud avec replay d'événements
 */

const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const installation = require('../utils/installation');
const { computeDrift } = require('./sync-health');

// Fréquence du contrôle d'écart avec le cloud
const DRIFT_CHECK_INTERVAL_MS = 3 * 60 * 60 * 1000;

// Tables à synchroniser depuis Neon vers local (dans l'ordre des dépendances FK)
const PULL_TABLES = [
  'user_roles', 'utilisateurs', 'boutiques', 'user_boutique_assignments',
  'categories', 'produits', 'historique_prix_achat', 'stock', 'stock_boutiques',
  'fournisseurs', 'comptes_fournisseurs', 'clients', 'comptes_clients',
  'cash_registers', 'cash_sessions', 'cash_movements', 'movement_categories',
  'financial_movements', 'commandes_approvisionnement', 'details_commandes_approvisionnement',
  'villes', 'zones', 'commerciaux',
  'ventes', 'details_ventes', 'ventes_proforma', 'details_ventes_proforma',
  'mouvements_stock', 'transferts_stock', 'transactions_comptes', 'dates_peremption',
  'stock_inventories', 'inventory_items', 'historique_recus', 'parametres_entreprise',
];

// Tables that DO NOT have date_modification column
// NOTE: All tables should now have date_modification after migrations
// This is kept for backward compatibility with older installations
const TABLES_WITHOUT_DATE_MODIFICATION = [
  // Legacy list - all these tables now have date_modification column
];

// Lignes filles à supprimer dans Neon AVANT le parent.
//
// SQLite local n'applique pas les mêmes contraintes que PostgreSQL : une
// suppression qui passe en local est rejetée par Neon (violation de clé
// étrangère) et reste bloquée en échec indéfiniment. On reproduit donc
// explicitement la cascade côté cloud.
//
// Ne figurent ici que des données dérivées (stock, inventaire, comptes) : les
// écritures à valeur comptable (ventes, commandes) ne sont jamais supprimées
// en cascade — les routes empêchent déjà la suppression d'un élément qui en
// possède.
const CASCADE_ON_DELETE = {
  produits: [
    ['stock_boutiques',       'produit_id'],
    ['stock',                 'produit_id'],
    ['historique_prix_achat', 'produit_id'],
    ['dates_peremption',      'produit_id'],
    ['inventory_items',       'produit_id'],
    ['mouvements_stock',      'produit_id'],
  ],
  clients:      [['comptes_clients',      'client_id']],
  fournisseurs: [['comptes_fournisseurs', 'fournisseur_id']],
  utilisateurs: [['user_boutique_assignments', 'utilisateur_id']],
  cash_sessions: [['cash_movements', 'session_id']],
  commandes_approvisionnement: [['details_commandes_approvisionnement', 'commande_id']],
};

// Références à neutraliser (et non supprimer) avant la suppression du parent :
// supprimer une catégorie ne doit pas emporter les produits qui la portent.
const NULLIFY_ON_DELETE = {
  categories: [['produits', 'categorie_id']],
};

// Colonnes NOT NULL côté Neon que certaines routes omettent lorsqu'elles
// construisent le payload à la main. Sans valeur de repli, la poussée est
// rejetée ("null value in column ... violates not-null constraint") et
// l'opération reste bloquée en échec.
const COLONNES_OBLIGATOIRES = {
  stock_boutiques: { derniere_maj: () => new Date().toISOString() },
  stock:           { derniere_maj: () => new Date().toISOString() },
};

// Colonne de repli utilisée pour le delta quand date_modification est absente
// (anciennes installations qui n'ont pas reçu les migrations)
const ALT_MODIFICATION_COLUMNS = {
  'mouvements_stock':   'date_mouvement',
  'cash_movements':     'date_creation',
  'historique_recus':   'date_generation',
  'transactions_comptes': 'date_transaction',
  'stock_inventories':  'date_creation',
  'inventory_items':    'date_comptage',
};

// Durée max d'un cycle de synchro avant qu'on le considère bloqué
const SYNC_CYCLE_MAX_MS = 5 * 60 * 1000;

class SyncServiceV2 {
  constructor() {
    this.localPrisma = null;
    this.cloudPool = null;
    this.isCloudAvailable = false;
    this.syncInterval = null;
    this.isSyncing = false;
    this.cloudUrl = process.env.CLOUD_DB_URL;
    this.lastCloudError = null;
    this.consecutiveCloudFailures = 0;
    this.lastSuccessfulSyncAt = null;
    this.syncStartedAt = null;
    this._modColumnCache = {};
    this.driftReport = null;
    this.lastDriftError = null;
    this._driftEnCours = false;
    // Lignes reçues du cloud mais laissées de côté parce qu'une écriture locale était en attente (table → ids)
    this._protegees = new Map();
  }

  /**
   * Compare ce poste et le cloud (lignes présentes d'un seul côté, valeurs de stock/soldes différentes)
   * et garde le rapport. Voir sync-health.js. Lecture seule : ne modifie ni les données ni les envois.
   * @returns {Promise<Object|null>} le dernier rapport (celui-ci, ou le précédent si le cloud est injoignable)
   */
  async checkDrift() {
    if (!this.cloudUrl || !this.cloudPool || !this.localPrisma || !this.isCloudAvailable) return this.driftReport;
    if (this._driftEnCours) return this.driftReport;
    this._driftEnCours = true;
    let client = null;
    let perdue = false;
    try {
      client = await this.cloudPool.connect();
      this.driftReport = await computeDrift({
        prisma: this.localPrisma,
        client,
        tables: PULL_TABLES,
        isConnectionError: (e) => this._isConnectionError(e),
        avecRenvoi: true,
      });
      this.lastDriftError = null;

      // Rattrapage : des lignes du cloud jamais reçues ici sont récupérées, puis le rapport est refait
      const recuperes = await this._recupererManquants(client, this.driftReport);
      if (recuperes > 0) {
        this.driftReport = await computeDrift({
          prisma: this.localPrisma,
          client,
          tables: PULL_TABLES,
          isConnectionError: (e) => this._isConnectionError(e),
          avecRenvoi: true,
        });
        this.driftReport.recuperes = recuperes;
      }
      const r = this.driftReport.resume;
      if (r.inexpliques > 0) {
        console.warn(`⚠️  Contrôle d'écart : ${r.inexpliques} élément(s) non expliqué(s) entre ce poste et le cloud (${r.anciens} depuis plus de ${this.driftReport.seuilAncienHeures} h)`);
      } else {
        console.log('✅ Contrôle d\'écart : ce poste et le cloud concordent');
      }
    } catch (e) {
      perdue = this._isConnectionError(e);
      this.lastDriftError = e.message;
      console.warn('⚠️  Contrôle d\'écart impossible:', e.message);
    } finally {
      if (client) client.release(perdue ? true : undefined);
      this._driftEnCours = false;
    }
    return this.driftReport;
  }

  async initialize(localPrisma) {
    this.localPrisma = localPrisma;
    if (!this.cloudUrl) {
      console.log('☁️  CLOUD_DB_URL non défini — mode 100% local activé');
      return;
    }
    console.log('🔄 SyncService V2: initialisation avec Event Sourcing...');
    
    // Créer la table deleted_records si elle n'existe pas
    await this._ensureDeletedRecordsTable();

    // Créer les tables de suivi du pull (curseur de réception + file de reprise)
    await this._ensurePullStateTables();

    // Créer les tables métier ajoutées après la mise en place initiale de Neon
    // (les anciennes bases clients n'ont reçu que la migration initiale)
    await this._ensureTablesCloud();

    // Aligner le schéma cloud sur les colonnes attendues
    await this._ensureColonnesCloud();

    await this._checkCloudConnection();

    // Garantir que ce poste possède sa plage d'ids (rattrapage si le premier
    // démarrage s'est fait hors ligne)
    await this.ensureInstallationIdentity(localPrisma);

    if (this.isCloudAvailable) {
      console.log('📋 [V2] Replay des opérations en attente...');
      await this._replayPendingOperations();
      console.log('📥 [V2] Pull delta depuis Neon...');
      await this._pullDeltaFromNeon();
    }
    this.syncInterval = setInterval(() => this._syncCycle(), 30000);
    // Contrôle d'écart avec le cloud : peu après le démarrage (le temps du premier pull), puis périodiquement
    this.driftTimeout = setTimeout(() => this.checkDrift(), 2 * 60 * 1000);
    this.driftInterval = setInterval(() => this.checkDrift(), DRIFT_CHECK_INTERVAL_MS);
    console.log('✅ SyncService V2 démarré (Event Sourcing + Hybrid Mode)');
  }

  _createCloudPool() {
    const pool = new Pool({
      connectionString: this.cloudUrl,
      ssl: { rejectUnauthorized: false },
      max: 3,
      idleTimeoutMillis: 10000,
      // Liaisons lentes/instables : 10 s était trop court (Neon met 3 à 8 s à répondre)
      connectionTimeoutMillis: 30000,
      // Évite que routeur/FAI abandonne silencieusement une connexion inactive
      keepAlive: true,
      keepAliveInitialDelayMillis: 10000,
      // Sans ces délais, une requête restée sans réponse (liaison qui "gèle" en
      // plein envoi) n'échoue jamais : le cycle de synchro reste bloqué pour
      // toujours alors que le statut continue d'afficher "connecté".
      query_timeout: 60000,
      statement_timeout: 60000,
    });
    // Sans ce handler, une coupure sur une connexion inactive fait tomber le processus
    pool.on('error', (e) => console.warn('⚠️  Neon: connexion inactive perdue —', e.message));
    return pool;
  }

  /**
   * true si l'erreur vient de la liaison (coupure, délai, DNS) et non des
   * données : dans ce cas l'opération n'est PAS en échec, elle doit simplement
   * rester en attente et repartir au prochain cycle.
   */
  _isConnectionError(e) {
    const code = e && e.code;
    if (['ECONNRESET', 'ETIMEDOUT', 'ECONNREFUSED', 'ENOTFOUND', 'EAI_AGAIN', 'EPIPE', 'ENETUNREACH', 'EHOSTUNREACH', '57P01', '57P02', '57P03', '08000', '08003', '08006'].includes(code)) return true;
    const msg = String((e && e.message) || '').toLowerCase();
    return (
      msg.includes('connection terminated') ||
      msg.includes('timeout') ||
      msg.includes('timed out') ||
      msg.includes('socket') ||
      msg.includes('client has encountered a connection error') ||
      msg.includes('connection closed')
    );
  }

  /**
   * Teste la connexion à Neon. Une micro-coupure ne suffit pas à passer hors
   * ligne : on retente (1 s puis 3 s) avec un pool neuf avant de conclure.
   * L'erreur réelle est conservée dans this.lastCloudError pour l'affichage.
   */
  async _checkCloudConnection() {
    if (!this.cloudUrl) return false;
    const delaisEntreEssais = [0, 1000, 3000];
    let derniereErreur = null;

    for (let i = 0; i < delaisEntreEssais.length; i++) {
      if (delaisEntreEssais[i] > 0) {
        await new Promise((r) => setTimeout(r, delaisEntreEssais[i]));
      }
      try {
        if (!this.cloudPool) this.cloudPool = this._createCloudPool();
        const client = await this.cloudPool.connect();
        try {
          await client.query('SELECT 1');
        } finally {
          client.release();
        }
        if (!this.isCloudAvailable) {
          console.log('☁️  Connexion Neon établie — mode hybride actif');
          this.isCloudAvailable = true;
        }
        this.lastCloudError = null;
        this.consecutiveCloudFailures = 0;
        return true;
      } catch (e) {
        derniereErreur = e;
        // Pool potentiellement porteur de sockets mortes : on repart de zéro
        const ancien = this.cloudPool;
        this.cloudPool = null;
        if (ancien) ancien.end().catch(() => {});
      }
    }

    this.consecutiveCloudFailures = (this.consecutiveCloudFailures || 0) + 1;
    this.lastCloudError = {
      code: derniereErreur.code || null,
      message: derniereErreur.message,
      at: new Date().toISOString(),
    };
    // Journaliser au 1er échec puis toutes les 10 tentatives, sans inonder le log
    if (this.consecutiveCloudFailures === 1 || this.consecutiveCloudFailures % 10 === 0) {
      console.warn(
        `⚠️  Neon inaccessible (échec n°${this.consecutiveCloudFailures}, 3 essais) : ` +
        `${derniereErreur.code || 'sans code'} — ${derniereErreur.message}`
      );
    }
    this.isCloudAvailable = false;
    return false;
  }

  /**
   * Crée la table deleted_records en local si elle n'existe pas
   */
  async _ensureDeletedRecordsTable() {
    try {
      // Check if table exists first
      const existing = await this.localPrisma.$queryRaw`
        SELECT name FROM sqlite_master WHERE type='table' AND name='deleted_records'
      `;
      
      if (existing.length === 0) {
        await this.localPrisma.$executeRawUnsafe(
          `CREATE TABLE "deleted_records" (
            "id"          INTEGER PRIMARY KEY AUTOINCREMENT,
            "table_name"  TEXT NOT NULL,
            "record_id"   INTEGER NOT NULL,
            "deleted_at"  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "deleted_by"  INTEGER
          )`
        );
        
        await this.localPrisma.$executeRawUnsafe(
          `CREATE INDEX "idx_deleted_records_deleted_at"
           ON "deleted_records"("deleted_at")`
        );
        
        await this.localPrisma.$executeRawUnsafe(
          `CREATE INDEX "idx_deleted_records_table_deleted_at"
           ON "deleted_records"("table_name", "deleted_at")`
        );
        
        console.log('✅ Table deleted_records créée en local avec AUTOINCREMENT');
      } else {
        // Check if the existing table has AUTOINCREMENT
        const schema = await this.localPrisma.$queryRaw`
          SELECT sql FROM sqlite_master WHERE type='table' AND name='deleted_records'
        `;
        const sql = schema[0]?.sql || '';
        if (!sql.includes('AUTOINCREMENT')) {
          console.log('⚠️  Table deleted_records existe mais sans AUTOINCREMENT - recréation...');
          await this.localPrisma.$executeRawUnsafe(`DROP TABLE "deleted_records"`);
          
          await this.localPrisma.$executeRawUnsafe(
            `CREATE TABLE "deleted_records" (
              "id"          INTEGER PRIMARY KEY AUTOINCREMENT,
              "table_name"  TEXT NOT NULL,
              "record_id"   INTEGER NOT NULL,
              "deleted_at"  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              "deleted_by"  INTEGER
            )`
          );
          
          await this.localPrisma.$executeRawUnsafe(
            `CREATE INDEX "idx_deleted_records_deleted_at"
             ON "deleted_records"("deleted_at")`
          );
          
          await this.localPrisma.$executeRawUnsafe(
            `CREATE INDEX "idx_deleted_records_table_deleted_at"
             ON "deleted_records"("table_name", "deleted_at")`
          );
          
          console.log('✅ Table deleted_records recréée avec AUTOINCREMENT');
        } else {
          console.log('✅ Table deleted_records existe déjà avec AUTOINCREMENT');
        }
      }
    } catch (e) {
      console.warn('⚠️  Erreur création table deleted_records:', e.message);
    }
  }

  /**
   * NOUVEAU: Replay des opérations non-synchronisées
   * C'est le cœur du Event Sourcing
   */
  async _replayPendingOperations() {
    try {
      // Avant d'envoyer : une fiche déjà présente sur Neon sous un autre identifiant est
      // alignée tout de suite, au lieu d'être refusée puis réparée plus tard.
      try {
        await this._reconcileCompositeKeyConflicts();
      } catch (e) {
        if (this._isConnectionError(e)) throw e;
        console.warn('⚠️  Vérification des doublons avant envoi:', e.message);
      }

      const pending = await this.localPrisma.$queryRawUnsafe(
        `SELECT * FROM operation_log WHERE status IN ('pending', 'failed') ORDER BY timestamp ASC LIMIT 1000`
      );

      if (pending.length === 0) {
        console.log('✅ Aucune opération en attente — journal à jour');
        return;
      }

      // Trier les opérations par ordre de dépendances FK
      // - INSERT/UPDATE : ordre normal (parents avant enfants)
      // - DELETE : ordre inverse (enfants avant parents, pour respecter les FK)
      pending.sort((a, b) => {
        const orderA = PULL_TABLES.indexOf(a.table_name);
        const orderB = PULL_TABLES.indexOf(b.table_name);
        const isDeleteA = a.operation_type === 'DELETE';
        const isDeleteB = b.operation_type === 'DELETE';

        // DELETE d'une table enfant doit passer avant DELETE d'une table parent
        // → inverser l'ordre pour les DELETE
        if (isDeleteA && isDeleteB) {
          if (orderA !== orderB) return orderB - orderA; // inverse
          return 0;
        }

        // INSERT/UPDATE avant DELETE (créer avant supprimer)
        if (!isDeleteA && isDeleteB) return -1;
        if (isDeleteA && !isDeleteB) return 1;

        // INSERT/UPDATE : ordre normal (parent avant enfant)
        if (orderA !== orderB) return orderA - orderB;
        return 0;
      });

      console.log(`📋 [V2] Replay de ${pending.length} opération(s) en attente...`);
      const client = await this.cloudPool.connect();
      let connexionPerdue = false;

      try {
      for (const op of pending) {
        try {
          // Sauter les INSERT/UPDATE si un DELETE synced existe pour le même enregistrement
          if (op.operation_type !== 'DELETE' && op.record_id) {
            const deleted = await this.localPrisma.$queryRawUnsafe(
              `SELECT 1 FROM operation_log 
               WHERE table_name = ? AND record_id = ? AND operation_type = 'DELETE'
               AND status IN ('synced', 'pending')
               LIMIT 1`,
              op.table_name,
              op.record_id
            );
            if (deleted.length > 0) {
              await this.localPrisma.$executeRawUnsafe(
                `UPDATE operation_log SET status = 'cancelled' WHERE operation_id = ?`,
                op.operation_id
              );
              console.log(`  ⏭️  Annulé: ${op.operation_type} ${op.table_name} (id=${op.record_id}) — enregistrement supprimé`);
              continue;
            }
          }
          
          console.log(`  ⏮️  Replay: ${op.operation_type} ${op.table_name} (id=${op.record_id})`);
          
          const data = typeof op.data === 'string' ? JSON.parse(op.data) : op.data;
          // Retracer l'opération (INSERT/UPDATE/DELETE)
          await this._applyToCloud(client, op.table_name, op.operation_type, data);

          // Marquer comme synced
          await this.localPrisma.$executeRawUnsafe(
            `UPDATE operation_log SET status = 'synced', synced_at = datetime('now') 
             WHERE operation_id = ?`,
            op.operation_id
          );

          console.log(`  ✅ Synced: ${op.table_name} (id=${op.record_id})`);
        } catch (e) {
          // Coupure de liaison : l'opération n'est pas en échec, elle reste en
          // attente. On arrête ici (inutile de marquer "failed" toutes les
          // opérations restantes une par une) ; le prochain cycle reprend.
          if (this._isConnectionError(e)) {
            console.warn(`  📡 Liaison perdue pendant le replay (${e.message}) — reprise au prochain cycle`);
            connexionPerdue = true;
            this.isCloudAvailable = false;
            break;
          }
          console.error(`  ❌ Erreur replay ${op.table_name}: ${e.message}`);
          
          await this.localPrisma.$executeRawUnsafe(
            `UPDATE operation_log SET status = 'failed', error_message = ? 
             WHERE operation_id = ?`,
            e.message.substring(0, 500),
            op.operation_id
          );
        }
      }
      } finally {
        // true => la connexion est détruite et non remise dans le pool
        client.release(connexionPerdue ? true : undefined);
      }
      console.log('✅ Replay terminé');
    } catch (e) {
      console.error('❌ Erreur replay:', e.message);
    }
  }

  /**
   * Garantit que ce poste dispose d'un numéro d'installation et d'une plage
   * d'identifiants réservée.
   *
   * Sans cela, deux postes génèrent les mêmes ids auto-incrémentés pour des
   * enregistrements différents ; le second écrase alors silencieusement le
   * premier dans Neon (perte de données définitive).
   *
   * Idempotent : ne fait un aller-retour réseau qu'au tout premier démarrage.
   */
  async ensureInstallationIdentity(localPrisma) {
    if (localPrisma) this.localPrisma = localPrisma;
    if (!this.localPrisma) return null;

    // Déjà résolue durant ce démarrage — rien à refaire
    if (installation.getInstallationId()) return null;

    try {
      await this.localPrisma.$executeRawUnsafe(
        `CREATE TABLE IF NOT EXISTS "sync_identity" (
          "id"              INTEGER PRIMARY KEY,
          "installation_id" INTEGER NOT NULL,
          "block_start"     INTEGER NOT NULL,
          "machine_name"    TEXT,
          "assigned_at"     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )`
      );

      let rows = await this.localPrisma.$queryRawUnsafe(
        `SELECT installation_id, block_start FROM sync_identity WHERE id = 1`
      );

      // Pas encore d'identité : la réserver auprès de Neon
      if (rows.length === 0) {
        if (!this.cloudUrl) return null; // mode 100% local : un seul poste, rien à faire
        const claimed = await this._claimInstallationFromCloud();
        if (!claimed) {
          console.warn('⚠️  Numéro de poste non réservé (Neon injoignable) — nouvelle tentative au prochain cycle');
          return null;
        }
        rows = [claimed];
      }

      const identity = rows[0];
      const installationId = Number(identity.installation_id);
      const blockStart = Number(identity.block_start);

      await this._applyIdBlock(blockStart);
      installation.setInstallationId(installationId);

      console.log(`🏷️  Poste n°${installationId} — plage d'ids réservée à partir de ${blockStart.toLocaleString('fr-FR')}`);
      return identity;
    } catch (e) {
      console.warn('⚠️  Identité de poste non initialisée (non bloquant):', e.message);
      return null;
    }
  }

  /**
   * Réserve un numéro de poste dans Neon, de façon atomique.
   */
  async _claimInstallationFromCloud() {
    const available = await this._checkCloudConnection();
    if (!available) return null;

    const client = await this.cloudPool.connect();
    try {
      await client.query(
        `CREATE TABLE IF NOT EXISTS "installations" (
          "id"           SERIAL PRIMARY KEY,
          "machine_name" TEXT,
          "block_start"  BIGINT NOT NULL DEFAULT 0,
          "created_at"   TIMESTAMP NOT NULL DEFAULT NOW(),
          "last_seen_at" TIMESTAMP
        )`
      );

      const machineName = require('os').hostname();
      const res = await client.query(
        `INSERT INTO "installations" ("machine_name", "last_seen_at") VALUES ($1, NOW()) RETURNING id`,
        [machineName]
      );

      const installationId = Number(res.rows[0].id);
      const blockStart = installation.blockStartFor(installationId);

      await client.query(`UPDATE "installations" SET "block_start" = $1 WHERE id = $2`, [blockStart, installationId]);

      await this.localPrisma.$executeRawUnsafe(
        `INSERT INTO sync_identity (id, installation_id, block_start, machine_name)
         VALUES (1, ?, ?, ?)`,
        installationId, blockStart, machineName
      );

      console.log(`✅ Poste enregistré auprès de Neon sous le n°${installationId}`);
      return { installation_id: installationId, block_start: blockStart };
    } catch (e) {
      console.warn('⚠️  Réservation du numéro de poste échouée:', e.message);
      return null;
    } finally {
      client.release();
    }
  }

  /**
   * Décale les compteurs AUTOINCREMENT de SQLite dans la plage du poste.
   * Ne baisse jamais un compteur : les données existantes restent intactes.
   */
  async _applyIdBlock(blockStart) {
    if (!blockStart || blockStart <= 0) return;

    try {
      const tables = await this.localPrisma.$queryRawUnsafe(
        `SELECT name FROM sqlite_master
         WHERE type='table' AND sql LIKE '%AUTOINCREMENT%' AND name NOT LIKE 'sqlite_%'`
      );

      let adjusted = 0;
      for (const { name } of tables) {
        await this.localPrisma.$executeRawUnsafe(
          `INSERT INTO sqlite_sequence (name, seq)
           SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM sqlite_sequence WHERE name = ?)`,
          name, blockStart, name
        );
        const changed = await this.localPrisma.$executeRawUnsafe(
          `UPDATE sqlite_sequence SET seq = ? WHERE name = ? AND seq < ?`,
          blockStart, name, blockStart
        );
        if (changed > 0) adjusted++;
      }

      if (adjusted > 0) {
        console.log(`🔢 ${adjusted} compteur(s) d'identifiants repositionné(s) dans la plage du poste`);
      }
    } catch (e) {
      console.warn('⚠️  Repositionnement des compteurs échoué:', e.message);
    }
  }

  /**
   * Ajoute dans Neon les colonnes introduites par une mise à jour applicative.
   * Les postes clients ne peuvent pas exécuter `prisma migrate` : la migration
   * doit donc être portée par le démarrage, et être idempotente.
   */
  /**
   * Crée les tables « commerciaux terrain » (villes / zones / commerciaux)
   * côté Neon si elles sont absentes.
   *
   * Ajoutées à schema.postgresql.prisma après la mise en place initiale de
   * nombreuses bases clients : sans ce rattrapage, toute écriture locale sur
   * ces tables (ou sur ventes.commercial_id/zone_id/ville_id) échoue
   * indéfiniment côté sync ("relation does not exist").
   */
  async _ensureTablesCloud() {
    const disponible = await this._checkCloudConnection();
    if (!disponible) return;

    const client = await this.cloudPool.connect();
    try {
      await client.query(`
        CREATE OR REPLACE FUNCTION update_date_modification()
        RETURNS TRIGGER AS $f$
        BEGIN
            NEW.date_modification = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $f$ LANGUAGE plpgsql;

        CREATE TABLE IF NOT EXISTS "villes" (
            "id" SERIAL NOT NULL,
            "nom" TEXT NOT NULL,
            "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "villes_pkey" PRIMARY KEY ("id")
        );

        CREATE TABLE IF NOT EXISTS "zones" (
            "id" SERIAL NOT NULL,
            "nom" TEXT NOT NULL,
            "ville_id" INTEGER NOT NULL,
            "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "zones_pkey" PRIMARY KEY ("id")
        );

        CREATE TABLE IF NOT EXISTS "commerciaux" (
            "id" SERIAL NOT NULL,
            "nom" TEXT NOT NULL,
            "prenom" TEXT,
            "telephone" TEXT,
            "zone_id" INTEGER NOT NULL,
            "is_active" BOOLEAN NOT NULL DEFAULT true,
            "date_creation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "date_modification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "commerciaux_pkey" PRIMARY KEY ("id")
        );

        ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "commercial_id" INTEGER;
        ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "zone_id" INTEGER;
        ALTER TABLE "ventes" ADD COLUMN IF NOT EXISTS "ville_id" INTEGER;

        DO $d$ BEGIN
            ALTER TABLE "villes" ADD CONSTRAINT "villes_nom_key" UNIQUE ("nom");
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "zones" ADD CONSTRAINT "zones_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "villes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "zones" ADD CONSTRAINT "zones_ville_id_nom_key" UNIQUE ("ville_id", "nom");
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "commerciaux" ADD CONSTRAINT "commerciaux_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "ventes" ADD CONSTRAINT "ventes_commercial_id_fkey" FOREIGN KEY ("commercial_id") REFERENCES "commerciaux"("id") ON DELETE SET NULL ON UPDATE CASCADE;
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "ventes" ADD CONSTRAINT "ventes_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        DO $d$ BEGIN
            ALTER TABLE "ventes" ADD CONSTRAINT "ventes_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "villes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
        EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $d$;

        CREATE TABLE IF NOT EXISTS "deleted_records" (
            "id" SERIAL NOT NULL,
            "table_name" TEXT NOT NULL,
            "record_id" INTEGER NOT NULL,
            "deleted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "deleted_by" INTEGER,
            CONSTRAINT "deleted_records_pkey" PRIMARY KEY ("id")
        );
        CREATE INDEX IF NOT EXISTS "idx_deleted_records_deleted_at" ON "deleted_records"("deleted_at");
        CREATE INDEX IF NOT EXISTS "idx_deleted_records_table_deleted_at" ON "deleted_records"("table_name", "deleted_at");

        CREATE INDEX IF NOT EXISTS "idx_villes_nom" ON "villes"("nom");
        CREATE INDEX IF NOT EXISTS "idx_zones_ville" ON "zones"("ville_id");
        CREATE INDEX IF NOT EXISTS "idx_commerciaux_zone" ON "commerciaux"("zone_id");
        CREATE INDEX IF NOT EXISTS "idx_commerciaux_actif" ON "commerciaux"("is_active");
        CREATE INDEX IF NOT EXISTS "idx_ventes_commercial" ON "ventes"("commercial_id");
        CREATE INDEX IF NOT EXISTS "idx_ventes_zone" ON "ventes"("zone_id");
        CREATE INDEX IF NOT EXISTS "idx_ventes_ville" ON "ventes"("ville_id");

        DROP TRIGGER IF EXISTS update_villes_date_modification ON villes;
        CREATE TRIGGER update_villes_date_modification
            BEFORE UPDATE ON villes
            FOR EACH ROW
            EXECUTE FUNCTION update_date_modification();

        DROP TRIGGER IF EXISTS update_zones_date_modification ON zones;
        CREATE TRIGGER update_zones_date_modification
            BEFORE UPDATE ON zones
            FOR EACH ROW
            EXECUTE FUNCTION update_date_modification();

        DROP TRIGGER IF EXISTS update_commerciaux_date_modification ON commerciaux;
        CREATE TRIGGER update_commerciaux_date_modification
            BEFORE UPDATE ON commerciaux
            FOR EACH ROW
            EXECUTE FUNCTION update_date_modification();
      `).catch(e => console.warn(`⚠️  _ensureTablesCloud: ${e.message}`));
    } finally {
      client.release();
    }
  }

  async _ensureColonnesCloud() {
    const AJOUTS = [
      [`financial_movements`, `statut`, `TEXT NOT NULL DEFAULT 'actif'`],
      [`parametres_entreprise`, `separer_commande_encaissement`, `BOOLEAN NOT NULL DEFAULT false`],
      [`parametres_entreprise`, `vendeurs_voient_toutes_ventes`, `BOOLEAN NOT NULL DEFAULT false`],
    ];
    const disponible = await this._checkCloudConnection();
    if (!disponible) return;

    const client = await this.cloudPool.connect();
    try {
      for (const [table, colonne, definition] of AJOUTS) {
        try {
          await client.query(`ALTER TABLE "${table}" ADD COLUMN IF NOT EXISTS "${colonne}" ${definition}`);
        } catch (e) {
          console.warn(`⚠️  Ajout colonne ${table}.${colonne}: ${e.message}`);
        }
      }
    } finally {
      client.release();
    }
  }

  /**
   * Fusionne les doublons créés par l'auto-seed.
   *
   * Chaque installation crée sa propre « Caisse Principale », « Boutique
   * Principale », rôle ADMIN, etc. avant même de connaître le cloud. Quand un
   * second poste se connecte, il télécharge les mêmes enregistrements sous
   * d'autres identifiants et se retrouve avec des doublons. Les deux bases ne
   * s'accordent alors plus sur l'identité de ces enregistrements : Neon impose
   * une unicité sur le nom, la poussée est rejetée, et tout ce qui référence
   * l'enregistrement local est bloqué en cascade.
   *
   * On conserve donc l'identifiant du cloud (source de vérité partagée) et on
   * y repointe les références locales.
   */
  async _reconcileNaturalKeyDuplicates(client) {
    // Tables portant une clé naturelle unique côté Neon et alimentées par l'auto-seed
    const CLES_NATURELLES = {
      cash_registers:     'nom',
      user_roles:         'nom',
      utilisateurs:       'nom_utilisateur',
      categories:         'nom',
      movement_categories:'nom',
      boutiques:          'nom',
    };

    let fusions = 0;

    for (const [table, colonne] of Object.entries(CLES_NATURELLES)) {
      let doublons;
      try {
        doublons = await this.localPrisma.$queryRawUnsafe(
          `SELECT "${colonne}" AS cle, COUNT(*) AS n FROM "${table}"
           WHERE "${colonne}" IS NOT NULL GROUP BY "${colonne}" HAVING COUNT(*) > 1`
        );
      } catch (e) { continue; } // table absente sur d'anciennes installations
      if (doublons.length === 0) continue;

      for (const { cle } of doublons) {
        try {
          const locales = await this.localPrisma.$queryRawUnsafe(
            `SELECT id FROM "${table}" WHERE "${colonne}" = ? ORDER BY id`, cle
          );
          const ids = locales.map(r => Number(r.id));

          // L'identifiant du cloud fait foi ; à défaut on garde le plus ancien
          let garder = ids[0];
          try {
            const distant = await client.query(
              `SELECT id FROM "${table}" WHERE "${colonne}" = $1 LIMIT 1`, [cle]
            );
            if (distant.rows.length && ids.includes(Number(distant.rows[0].id))) {
              garder = Number(distant.rows[0].id);
            }
          } catch (_) { /* on garde le repli */ }

          for (const ancien of ids.filter(i => i !== garder)) {
            await this._repointerReferences(table, ancien, garder);
            await this.localPrisma.$executeRawUnsafe(`DELETE FROM "${table}" WHERE id = ?`, ancien);
            await this.localPrisma.$executeRawUnsafe(
              `UPDATE operation_log SET status = 'cancelled'
               WHERE table_name = ? AND record_id = ? AND status IN ('pending','failed')`,
              table, ancien
            );
            console.log(`🔗 ${table} « ${cle} » : id ${ancien} fusionné dans ${garder}`);
            fusions++;
          }
        } catch (e) {
          console.warn(`⚠️  Fusion ${table} « ${cle} » impossible: ${e.message}`);
        }
      }
    }

    if (fusions > 0) {
      // Les opérations en attente portent un payload figé qui référence encore
      // l'ancien identifiant : on le reconstruit depuis l'état réel de la base.
      await this._rafraichirPayloadsEnAttente();
      console.log(`✅ ${fusions} doublon(s) d'installation réconcilié(s)`);
    }
  }

  /**
   * Évite (et débloque) les fiches en doublon entre ce poste et Neon.
   *
   * Cas typique : le poste crée la ligne de stock (boutique 1, produit 3) sous
   * l'identifiant 150000001 alors que Neon en possède déjà une pour le même couple
   * sous l'identifiant 100000003 (créée par un autre poste). Neon refuse la
   * nôtre (clé unique boutique + produit) et nous refusons la sienne : chacun
   * attend que l'autre cède sa place, indéfiniment.
   *
   * Deux moments d'intervention :
   *  - AVANT l'envoi (_replayPendingOperations) : toute opération en attente sur
   *    ces tables est comparée à Neon ; le doublon est résolu sans jamais passer
   *    par l'état « refusé » ;
   *  - APRÈS un refus ou une ligne reçue non appliquée (réception) : filet de
   *    sécurité pour les cas déjà installés.
   *
   * L'identifiant du cloud est la référence commune : on y aligne la ligne
   * locale (un seul UPDATE, rien n'est supprimé), puis :
   *  - tables de quantité (stock) : on garde la quantité la PLUS RÉCENTE
   *    (derniere_maj) ; si c'est la nôtre et qu'elle diffère, elle est renvoyée ;
   *  - autres tables (affectations, villes, zones) : valeurs du cloud.
   * Les envois devenus sans objet sont annulés.
   *
   * Volontairement NON traités ici : comptes clients / fournisseurs (deux soldes à
   * additionner, pas à choisir), références de produit, inventaires nommés, et les
   * utilisateurs, caisses et boutiques (mots de passe, soldes d'argent, identité d'un
   * point de vente : on ne les remplace pas par ceux d'un autre poste sans décision humaine). Un
   * doublon y peut être une vraie différence ; il est signalé en clair sur l'écran
   * Synchronisation plutôt que fusionné à l'aveugle.
   *
   * @param {Object|null} client  connexion Neon déjà ouverte, sinon une est empruntée au besoin
   */
  async _reconcileCompositeKeyConflicts(client = null) {
    // ordre = dépendances : une ville avant ses zones
    const CLES = [
      // Référentiels créés par l'auto-seed de chaque poste (« admin », « VENDEUR »...) : l'index
      // unique local sur le nom empêche tout doublon local, donc _reconcileNaturalKeyDuplicates
      // (qui cherche des doublons LOCAUX) ne se déclenche jamais face à la ligne du cloud.
      ['user_roles', ['nom'], 'cloud'],
      ['categories', ['nom'], 'cloud'],
      ['movement_categories', ['nom'], 'cloud'],
      ['villes', ['nom'], 'cloud'],
      ['zones', ['ville_id', 'nom'], 'cloud'],
      ['user_boutique_assignments', ['utilisateur_id', 'boutique_id'], 'cloud'],
      ['stock', ['produit_id'], 'quantite'],
      ['stock_boutiques', ['boutique_id', 'produit_id'], 'quantite'],
    ];
    const toMs = (v) => {
      if (v === null || v === undefined) return 0;
      if (v instanceof Date) return v.getTime();
      if (typeof v === 'number' || typeof v === 'bigint') return Number(v);
      const t = Date.parse(String(v));
      return Number.isNaN(t) ? 0 : t;
    };
    const num = (v) => (typeof v === 'bigint' ? Number(v) : v);
    const camel = (c) => c.replace(/_([a-z])/g, (_, x) => x.toUpperCase());

    // 1. Fiches à vérifier : opérations en attente OU refusées (avant/après envoi) et
    //    lignes reçues non appliquées. On retient les IDENTIFIANTS des lignes locales
    //    (et non la clé figée dans le payload) : une ville fusionnée juste avant doit
    //    se refléter dans la clé de ses zones, lue au moment de les traiter.
    const aTraiter = [];
    for (const [table, cols, mode] of CLES) {
      const ids = new Set();
      const clesRecues = new Map();
      try {
        const envois = await this.localPrisma.$queryRawUnsafe(
          `SELECT DISTINCT record_id FROM operation_log
           WHERE table_name = ? AND status IN ('pending', 'failed') AND operation_type <> 'DELETE' AND record_id IS NOT NULL`,
          table
        );
        for (const e of envois) ids.add(Number(e.record_id));
        const recues = await this.localPrisma.$queryRawUnsafe(
          `SELECT payload AS data FROM sync_pull_retry WHERE table_name = ? AND last_error LIKE '%UNIQUE constraint%'`,
          table
        );
        for (const e of recues) {
          let d;
          try { d = typeof e.data === 'string' ? JSON.parse(e.data) : e.data; } catch (_) { continue; }
          const valeurs = d ? cols.map((c) => (d[c] !== undefined ? d[c] : d[camel(c)])) : [];
          if (valeurs.length === cols.length && valeurs.every((v) => v !== undefined && v !== null)) {
            clesRecues.set(valeurs.join(''), valeurs);
          }
        }
      } catch (_) { continue; } // table ou suivi absent sur d'anciennes installations
      if (ids.size > 0 || clesRecues.size > 0) aTraiter.push([table, cols, mode, ids, clesRecues]);
    }
    if (aTraiter.length === 0) return 0; // cas courant : aucun appel réseau

    let emprunte = false;
    if (!client) {
      if (!this.cloudPool || !this.isCloudAvailable) return 0;
      client = await this.cloudPool.connect();
      emprunte = true;
    }

    let fusions = 0;
    let connexionPerdue = false;
    try {
      for (const [table, cols, mode, ids, clesRecues] of aTraiter) {
        // Clés lues dans l'état ACTUEL de la base locale (après les fusions précédentes)
        const couples = new Map(clesRecues);
        for (const id of ids) {
          try {
            const lignes = await this.localPrisma.$queryRawUnsafe(
              `SELECT ${cols.map((c) => `"${c}"`).join(', ')} FROM "${table}" WHERE id = ? LIMIT 1`, id
            );
            if (lignes.length) {
              const valeurs = cols.map((c) => num(lignes[0][c]));
              if (valeurs.every((v) => v !== undefined && v !== null)) couples.set(valeurs.join(''), valeurs);
            }
          } catch (_) { /* ligne ou colonne absente : rien à vérifier */ }
        }
        for (const valeurs of couples.values()) {
          try {
            // 2. Ligne du cloud et ligne locale pour ce couple
            const distant = await client.query(
              `SELECT * FROM "${table}" WHERE ${cols.map((c, i) => `"${c}" = $${i + 1}`).join(' AND ')} LIMIT 1`,
              valeurs
            );
            if (!distant.rows.length) continue; // le cloud ne connaît pas ce couple : rien à fusionner
            const cloud = distant.rows[0];

            const locales = await this.localPrisma.$queryRawUnsafe(
              `SELECT * FROM "${table}" WHERE ${cols.map((c) => `"${c}" = ?`).join(' AND ')} LIMIT 1`,
              ...valeurs
            );
            if (!locales.length) continue;
            const locale = locales[0];
            const ancienId = Number(locale.id);
            const nouveauId = Number(cloud.id);

            // Même identifiant des deux côtés : pas de doublon. Un éventuel refus avait
            // une autre cause ; on remet en attente pour rejouer
            if (ancienId === nouveauId) {
              await this.localPrisma.$executeRawUnsafe(
                `UPDATE operation_log SET status = 'pending', error_message = NULL
                 WHERE table_name = ? AND record_id = ? AND status = 'failed'
                   AND (error_message LIKE '%duplicate key%' OR error_message LIKE '%UNIQUE constraint%')`,
                table, ancienId
              );
              continue;
            }

            // 3. Quantité la plus récente (avant de toucher à quoi que ce soit)
            const estStock = mode === 'quantite';
            const localGagne = estStock
              && toMs(locale.derniere_maj) > toMs(cloud.derniere_maj)
              && Number(locale.quantite_disponible) !== Number(cloud.quantite_disponible);
            const valeursLocales = estStock ? {
              quantite_disponible: num(locale.quantite_disponible),
              quantite_reservee: num(locale.quantite_reservee),
              derniere_maj: num(locale.derniere_maj),
            } : null;

            // 4. Aligner la ligne locale sur l'identifiant du cloud (un seul UPDATE : rien n'est supprimé)
            await this.localPrisma.$executeRawUnsafe(`UPDATE "${table}" SET id = ? WHERE id = ?`, nouveauId, ancienId);
            await this._repointerReferences(table, ancienId, nouveauId);

            // 5. Les envois portant l'ancien identifiant n'ont plus d'objet
            await this.localPrisma.$executeRawUnsafe(
              `UPDATE operation_log
               SET status = 'cancelled', error_message = ?
               WHERE table_name = ? AND record_id = ? AND status IN ('pending', 'failed')`,
              `Fiche fusionnée avec celle du cloud (identifiant ${ancienId} → ${nouveauId})`, table, ancienId
            );

            // 6. Valeurs du cloud, puis valeurs locales si elles sont plus récentes
            await this._mergeRemoteRow(table, cloud);
            if (localGagne) {
              await this.localPrisma.$executeRawUnsafe(
                `UPDATE "${table}" SET quantite_disponible = ?, quantite_reservee = ?, derniere_maj = ? WHERE id = ?`,
                valeursLocales.quantite_disponible, valeursLocales.quantite_reservee, valeursLocales.derniere_maj, nouveauId
              );
              const miseAJour = { ...Object.fromEntries(Object.entries(locale).map(([k, v]) => [k, num(v)])), id: nouveauId, ...valeursLocales };
              await this.logOperation(table, 'UPDATE', miseAJour);
            }

            // 7. La ligne reçue n'est plus en échec
            await this.localPrisma.$executeRawUnsafe(
              `DELETE FROM sync_pull_retry WHERE table_name = ? AND record_id IN (?, ?)`,
              table, String(nouveauId), String(ancienId)
            );

            console.log(
              `🔗 ${table} (${cols.join(', ')} = ${valeurs.join(', ')}) : identifiant local ${ancienId} aligné sur celui du cloud ${nouveauId}` +
              (localGagne ? ` — quantité locale plus récente (${valeursLocales.quantite_disponible}) renvoyée au cloud` : '')
            );
            fusions++;
          } catch (e) {
            if (this._isConnectionError(e)) { connexionPerdue = true; throw e; }
            console.warn(`⚠️  Fusion ${table} (${valeurs.join(', ')}) impossible: ${e.message}`);
          }
        }
      }
    } finally {
      if (emprunte) client.release(connexionPerdue ? true : undefined);
    }

    if (fusions > 0) {
      await this._rafraichirPayloadsEnAttente();
      console.log(`✅ ${fusions} fiche(s) en doublon réconciliée(s) avec le cloud`);
    }
    return fusions;
  }

  /**
   * Repointe toutes les clés étrangères visant `cible.ancienId` vers `nouveauId`.
   * Les relations sont découvertes dynamiquement : aucune liste à maintenir.
   */
  async _repointerReferences(cible, ancienId, nouveauId) {
    const tables = await this.localPrisma.$queryRawUnsafe(
      `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'`
    );

    for (const { name } of tables) {
      let fks;
      try {
        fks = await this.localPrisma.$queryRawUnsafe(`PRAGMA foreign_key_list("${name}")`);
      } catch (e) { continue; }

      for (const fk of fks) {
        if (fk.table !== cible) continue;
        try {
          const n = await this.localPrisma.$executeRawUnsafe(
            `UPDATE "${name}" SET "${fk.from}" = ? WHERE "${fk.from}" = ?`, nouveauId, ancienId
          );
          if (n > 0) console.log(`   ↳ ${name}.${fk.from}: ${n} référence(s) repointée(s)`);
        } catch (e) {
          console.warn(`   ⚠️  ${name}.${fk.from}: ${e.message}`);
        }
      }
    }
  }

  /**
   * Reconstruit le payload des opérations en attente à partir des lignes
   * réelles, afin qu'elles ne référencent plus d'identifiant fusionné.
   */
  async _rafraichirPayloadsEnAttente() {
    const MODELES = {
      cash_sessions: 'cashSession', cash_movements: 'cashMovement', cash_registers: 'cashRegister',
      ventes: 'vente', details_ventes: 'detailVente', stock_boutiques: 'stockBoutique',
      utilisateurs: 'utilisateur', produits: 'produit', clients: 'client',
      fournisseurs: 'fournisseur', financial_movements: 'financialMovement',
      user_boutique_assignments: 'userBoutiqueAssignment', boutiques: 'boutique',
    };

    const enAttente = await this.localPrisma.$queryRawUnsafe(
      `SELECT DISTINCT table_name, record_id FROM operation_log
       WHERE status IN ('pending','failed') AND operation_type <> 'DELETE'`
    );

    for (const op of enAttente) {
      const modele = MODELES[op.table_name];
      if (!modele || !this.localPrisma[modele]) continue;
      try {
        const ligne = await this.localPrisma[modele].findUnique({ where: { id: Number(op.record_id) } });
        await this.localPrisma.$executeRawUnsafe(
          `DELETE FROM operation_log WHERE table_name = ? AND record_id = ? AND status IN ('pending','failed')`,
          op.table_name, op.record_id
        );
        // La ligne peut avoir disparu (fusionnée) : l'opération devient caduque
        if (ligne) await this.logOperation(op.table_name, 'INSERT', ligne);
      } catch (e) {
        console.warn(`⚠️  Rafraîchissement ${op.table_name}#${op.record_id}: ${e.message}`);
      }
    }
  }

  /**
   * Crée les tables de suivi du pull.
   *
   * IMPORTANT : le curseur de réception doit être distinct de operation_log.
   * operation_log ne trace que les ENVOIS de ce poste ; s'en servir comme
   * curseur de réception rend invisibles toutes les données distantes
   * antérieures au dernier envoi local (perte de données entre postes).
   */
  async _ensurePullStateTables() {
    try {
      await this.localPrisma.$executeRawUnsafe(
        `CREATE TABLE IF NOT EXISTS "sync_pull_state" (
          "table_name"       TEXT PRIMARY KEY,
          "last_modified_at" TEXT,
          "last_pulled_at"   DATETIME
        )`
      );
      await this.localPrisma.$executeRawUnsafe(
        `CREATE TABLE IF NOT EXISTS "sync_pull_retry" (
          "id"         INTEGER PRIMARY KEY AUTOINCREMENT,
          "table_name" TEXT NOT NULL,
          "record_id"  TEXT NOT NULL,
          "payload"    TEXT NOT NULL,
          "attempts"   INTEGER NOT NULL DEFAULT 0,
          "last_error" TEXT,
          "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          "updated_at" DATETIME
        )`
      );
      await this.localPrisma.$executeRawUnsafe(
        `CREATE UNIQUE INDEX IF NOT EXISTS "idx_sync_pull_retry_unique"
         ON "sync_pull_retry"("table_name", "record_id")`
      );
      console.log('✅ Tables de suivi du pull prêtes (sync_pull_state, sync_pull_retry)');
    } catch (e) {
      console.warn('⚠️  Erreur création tables de suivi du pull:', e.message);
    }
  }

  /**
   * Convertit le cast ::text d'un timestamp Postgres SANS fuseau
   * ("2026-09-07 16:27:46.306") en ISO 8601 UTC comparable lexicalement au
   * curseur stocké ("2026-09-07T16:27:46.306Z").
   *
   * Ne JAMAIS repasser par Date#toISOString() sur la valeur du driver pg
   * pour ces colonnes : node-postgres réinterprète un timestamp sans fuseau
   * selon le fuseau local du process, alors que Postgres le traite comme une
   * valeur UTC littérale. Sur un poste en UTC+1, ça décale le curseur d'1h
   * en retard en permanence — la même ligne "récente" ne sort jamais de la
   * fenêtre du delta pull et revient à chaque cycle.
   */
  _rawTimestampToIso(raw) {
    if (!raw) return null;
    const [datePart, timePart = '00:00:00'] = String(raw).split(' ');
    const [hms, frac = '0'] = timePart.split('.');
    // Postgres stocke jusqu'à la microseconde (6 chiffres) ; tronquer à 3
    // (millisecondes) faisait perdre les derniers chiffres et laissait la
    // ligne "légèrement" plus récente que le curseur enregistré à chaque
    // cycle — même bug de re-pull perpétuel que le décalage horaire, pour
    // les timestamps dont les microsecondes ne sont pas nulles.
    const micros = frac.padEnd(6, '0').slice(0, 6);
    return `${datePart}T${hms}.${micros}Z`;
  }

  /**
   * Curseur de réception : date de modification la plus récente déjà reçue
   * pour cette table. '1970…' = jamais reçu → pull complet (réparateur).
   */
  async _getPullWatermark(table) {
    try {
      const rows = await this.localPrisma.$queryRawUnsafe(
        `SELECT last_modified_at FROM sync_pull_state WHERE table_name = ?`, table
      );
      return rows[0]?.last_modified_at || '1970-01-01T00:00:00.000Z';
    } catch (e) {
      return '1970-01-01T00:00:00.000Z';
    }
  }

  async _setPullWatermark(table, isoValue) {
    try {
      await this.localPrisma.$executeRawUnsafe(
        `INSERT INTO sync_pull_state (table_name, last_modified_at, last_pulled_at)
         VALUES (?, ?, datetime('now'))
         ON CONFLICT(table_name) DO UPDATE SET
           last_modified_at = excluded.last_modified_at,
           last_pulled_at   = excluded.last_pulled_at`,
        table, isoValue
      );
    } catch (e) {
      console.warn(`⚠️  Curseur ${table}: ${e.message}`);
    }
  }

  /**
   * Détermine la colonne de suivi de modification réellement présente côté Neon.
   * Résultat mis en cache : le schéma ne change pas en cours d'exécution.
   */
  async _resolveModificationColumn(client, table) {
    if (this._modColumnCache[table] !== undefined) return this._modColumnCache[table];

    const candidates = ['date_modification', ALT_MODIFICATION_COLUMNS[table], 'date_creation'].filter(Boolean);
    let found = null;
    try {
      const res = await client.query(
        `SELECT column_name FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = $1`,
        [table]
      );
      const available = new Set(res.rows.map(r => r.column_name));
      found = candidates.find(c => available.has(c)) || null;
      if (!found && available.size > 0) {
        console.warn(`⚠️  ${table}: aucune colonne de suivi de modification — table non synchronisable`);
      }
    } catch (e) {
      found = 'date_modification';
    }

    this._modColumnCache[table] = found;
    return found;
  }

  /**
   * Applique une ligne distante dans la base locale (insert ou update).
   */
  async _mergeRemoteRow(table, row) {
    const keys = Object.keys(row).filter(k => row[k] !== null && row[k] !== undefined);
    if (keys.length === 0) return;

    const cols = keys.map(k => `"${k}"`).join(', ');
    const placeholders = keys.map(() => '?').join(', ');
    const updateKeys = keys.filter(k => k !== 'id');
    const vals = keys.map(k => {
      const val = row[k];
      if (val instanceof Date) return val.toISOString();
      if (typeof val === 'bigint') return Number(val);
      return val;
    });

    const sql = updateKeys.length > 0
      ? `INSERT INTO "${table}" (${cols}) VALUES (${placeholders})
         ON CONFLICT(id) DO UPDATE SET ${updateKeys.map(k => `"${k}" = excluded."${k}"`).join(', ')}`
      : `INSERT INTO "${table}" (${cols}) VALUES (${placeholders}) ON CONFLICT(id) DO NOTHING`;

    await this.localPrisma.$executeRawUnsafe(sql, ...vals);
  }

  /**
   * Met une ligne en échec de côté au lieu de la perdre.
   * Le curseur peut alors avancer sans risque : la ligne sera rejouée
   * une fois ses dépendances (parents FK) arrivées.
   */
  async _enqueuePullRetry(table, row, errMessage) {
    try {
      const payload = JSON.stringify(row, (k, v) => (typeof v === 'bigint' ? Number(v) : v));
      await this.localPrisma.$executeRawUnsafe(
        `INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at)
         VALUES (?, ?, ?, 1, ?, datetime('now'))
         ON CONFLICT(table_name, record_id) DO UPDATE SET
           payload    = excluded.payload,
           attempts   = sync_pull_retry.attempts + 1,
           last_error = excluded.last_error,
           updated_at = excluded.updated_at`,
        table, String(row.id), payload, String(errMessage).substring(0, 500)
      );
    } catch (e) {
      console.warn(`⚠️  File de reprise ${table}: ${e.message}`);
    }
  }

  /**
   * Rejoue les lignes en échec, dans l'ordre des dépendances FK.
   * Appelé après le pull de toutes les tables, quand les parents sont présents.
   *
   * Une ligne n'est JAMAIS abandonnée. Au-delà de MAX_TENTATIVES (échec probablement structurel : parent pas
   * encore arrivé, conflit de clé) elle n'est plus rejouée à chaque cycle mais une fois par heure. L'ancien plafond
   * définitif laissait des lignes bloquées pendant des semaines alors que leur parent était arrivé depuis longtemps.
   *
   * @param {{ignorerDelai?: boolean}} [options]  ignorerDelai : rejoue aussi les lignes en pause (après un rattrapage)
   */
  async _processPullRetryQueue({ ignorerDelai = false } = {}) {
    try {
      const MAX_TENTATIVES = 20;

      const rows = ignorerDelai
        ? await this.localPrisma.$queryRawUnsafe(
            `SELECT id, table_name, record_id, payload, attempts FROM sync_pull_retry LIMIT 5000`
          )
        : await this.localPrisma.$queryRawUnsafe(
            `SELECT id, table_name, record_id, payload, attempts FROM sync_pull_retry
             WHERE attempts < ? OR updated_at IS NULL OR updated_at <= datetime('now', '-1 hour') LIMIT 5000`,
            MAX_TENTATIVES
          );
      if (rows.length === 0) return;

      rows.sort((a, b) => PULL_TABLES.indexOf(a.table_name) - PULL_TABLES.indexOf(b.table_name));

      let repaired = 0;
      let perimees = 0;
      const stillFailing = {};

      for (const entry of rows) {
        try {
          const payload = JSON.parse(entry.payload);
          // Entre-temps la ligne a pu arriver par le chemin normal, dans une version plus récente : ce qui est en file
          // est périmé et ne doit surtout pas l'écraser (risque réel quand une ligne reste des heures en file).
          if (await this._localePlusRecente(entry.table_name, payload)) {
            await this.localPrisma.$executeRawUnsafe(`DELETE FROM sync_pull_retry WHERE id = ?`, entry.id);
            perimees++;
            continue;
          }
          await this._mergeRemoteRow(entry.table_name, payload);
          await this.localPrisma.$executeRawUnsafe(`DELETE FROM sync_pull_retry WHERE id = ?`, entry.id);
          repaired++;
        } catch (e) {
          stillFailing[entry.table_name] = (stillFailing[entry.table_name] || 0) + 1;
          await this.localPrisma.$executeRawUnsafe(
            `UPDATE sync_pull_retry SET attempts = attempts + 1, last_error = ?, updated_at = datetime('now')
             WHERE id = ?`,
            String(e.message).substring(0, 500), entry.id
          );
        }
      }

      if (repaired > 0) console.log(`🔁 File de reprise: ${repaired} ligne(s) réparée(s)`);
      if (perimees > 0) console.log(`🔁 File de reprise: ${perimees} ligne(s) périmée(s) retirée(s) (version plus récente déjà reçue)`);
      const remaining = Object.entries(stillFailing);
      if (remaining.length > 0) {
        console.warn(`⚠️  File de reprise: ${remaining.map(([t, n]) => `${t}=${n}`).join(', ')} encore en échec`);
      }
    } catch (e) {
      console.warn('⚠️  Erreur traitement file de reprise:', e.message);
    }
  }

  /** La ligne locale existe déjà avec une modification au moins aussi récente que celle de `payload` */
  async _localePlusRecente(table, payload) {
    try {
      const toMs = (v) => {
        if (v === null || v === undefined) return 0;
        if (typeof v === 'number' || typeof v === 'bigint') return Number(v);
        const t = Date.parse(String(v).includes('T') ? String(v) : String(v).replace(' ', 'T') + 'Z');
        return Number.isNaN(t) ? 0 : t;
      };
      const local = await this.localPrisma.$queryRawUnsafe(`SELECT "date_modification" AS m FROM "${table}" WHERE id = ? LIMIT 1`, Number(payload.id));
      if (!local.length) return false;
      const mLocal = toMs(local[0].m);
      const mDistant = toMs(payload.date_modification);
      return mLocal > 0 && mDistant > 0 && mLocal >= mDistant;
    } catch (_) {
      return false; // table sans date de modification : on rejoue comme avant
    }
  }

  // ── Réception : application des lignes du cloud ───────────────────────────

  /** Ce qui empêche d'appliquer une ligne reçue : suppression locale en cours, ou écriture locale pas encore partie */
  async _contexteReception(table) {
    // Ne pas ré-insérer un enregistrement supprimé localement.
    //
    // Le statut 'failed' doit impérativement être couvert : une suppression rejetée par Neon laisse la ligne présente
    // côté cloud, et sans ce garde-fou le pull la réinsère en local — l'élément supprimé « revient » à l'écran. Tant
    // que la suppression n'est pas aboutie, on ignore la ligne distante, sans limite de temps.
    const recentDeletes = await this.localPrisma.$queryRawUnsafe(
      `SELECT record_id FROM operation_log
       WHERE table_name = ? AND operation_type = 'DELETE'
       AND ( status IN ('pending', 'failed')
          OR (status = 'synced' AND timestamp > datetime('now', '-1 hour')) )`,
      table
    );

    // Ne pas écraser une ligne dont la modification locale n'est pas encore partie vers le cloud.
    //
    // Sans ce garde-fou, le pull applique la valeur (périmée) de Neon par-dessus une écriture locale toute fraîche :
    // le stock restauré après une annulation repassait à sa valeur d'avant, jusqu'à ce que la poussée finisse par le
    // rétablir — et parfois définitivement si c'est la valeur périmée qui remportait la course.
    const enAttenteLocale = await this.localPrisma.$queryRawUnsafe(
      `SELECT DISTINCT record_id FROM operation_log
       WHERE table_name = ? AND status IN ('pending', 'failed')
       AND operation_type <> 'DELETE' AND record_id IS NOT NULL`,
      table
    );
    return {
      deletedIds: new Set(recentDeletes.map((r) => Number(r.record_id))),
      idsEnAttente: new Set(enAttenteLocale.map((r) => Number(r.record_id))),
    };
  }

  /**
   * Applique des lignes reçues du cloud à la base locale.
   *
   * Une ligne laissée de côté parce qu'une écriture locale est en attente est MÉMORISÉE : elle est redemandée au
   * cloud au cycle suivant (voir _reprendreProtegees). Avant, le curseur avançait au-delà d'elle et elle n'était
   * plus jamais reçue tant que quelqu'un ne la modifiait pas à nouveau, malgré un commentaire disant le contraire.
   *
   * @returns {{applied:number, deferred:number, conflits:number, protegees:number, maxSeen:string}}
   */
  async _appliquerLignesDistantes(table, rows, since, ctx) {
    let maxSeen = since;
    let applied = 0, deferred = 0, conflits = 0;
    const protegees = [];

    for (const row of rows) {
      const brut = row.__mod_col_raw;
      delete row.__mod_col_raw;
      const tsIso = brut ? this._rawTimestampToIso(brut) : null;
      if (tsIso && tsIso > maxSeen) maxSeen = tsIso;

      if (ctx.deletedIds.has(Number(row.id))) continue;

      // Écriture locale pas encore poussée : elle fait foi, on ne l'écrase pas, mais on se souvient de la ligne
      if (ctx.idsEnAttente.has(Number(row.id))) { protegees.push(Number(row.id)); continue; }

      try {
        await this._mergeRemoteRow(table, row);
        applied++;
      } catch (insertErr) {
        // Un conflit UNIQUE signale une divergence réelle : la ligne distante entre en collision avec une AUTRE ligne
        // locale sur une clé naturelle. L'ignorer silencieusement fait disparaître la donnée sans la moindre trace —
        // on la conserve et on la signale.
        if (insertErr.message.includes('UNIQUE constraint failed')) conflits++;
        deferred++;
        await this._enqueuePullRetry(table, row, insertErr.message);
      }
    }

    if (protegees.length > 0) {
      const memo = this._protegees.get(table) || new Set();
      for (const id of protegees) if (memo.size < 2000) memo.add(id);
      this._protegees.set(table, memo);
    }
    return { applied, deferred, conflits, protegees: protegees.length, maxSeen };
  }

  /** Redemande au cloud les lignes laissées de côté (écriture locale en attente) dont l'envoi est maintenant parti */
  async _reprendreProtegees(client, table) {
    const memo = this._protegees.get(table);
    if (!memo || memo.size === 0) return 0;
    const ctx = await this._contexteReception(table);
    const libres = [...memo].filter((id) => !ctx.idsEnAttente.has(id));
    if (libres.length === 0) return 0;
    const res = await client.query(`SELECT * FROM "${table}" WHERE id = ANY($1::bigint[])`, [libres]);
    const st = await this._appliquerLignesDistantes(table, res.rows, '', ctx);
    for (const id of libres) memo.delete(id);
    if (st.applied > 0) console.log(`  📥 ${table}: ${st.applied} ligne(s) laissée(s) de côté reprise(s) après l'envoi local`);
    return st.applied;
  }

  /**
   * Va chercher dans le cloud des lignes précises (par identifiant) et les applique. Sert au rattrapage des lignes
   * que le curseur de réception n'a jamais ramenées : ligne poussée tard par un poste resté hors ligne (sa date de
   * modification d'origine est plus ancienne que le curseur), ou sans date de modification.
   */
  async _recupererLignes(client, table, ids) {
    const total = { applied: 0, deferred: 0, conflits: 0, protegees: 0 };
    if (!ids.length) return total;
    const ctx = await this._contexteReception(table);
    for (let i = 0; i < ids.length; i += 500) {
      const lot = ids.slice(i, i + 500);
      const res = await client.query(`SELECT * FROM "${table}" WHERE id = ANY($1::bigint[])`, [lot]);
      const st = await this._appliquerLignesDistantes(table, res.rows, '', ctx);
      total.applied += st.applied; total.deferred += st.deferred; total.conflits += st.conflits; total.protegees += st.protegees;
    }
    return total;
  }

  /**
   * Rattrapage : applique les lignes que le contrôle d'écart a trouvées dans le cloud sans trace locale
   * (« jamais reçues », cause inconnue). Les lignes déjà connues du système (file de reprise, suppression) sont exclues.
   * @returns {Promise<number>} nombre de lignes récupérées
   */
  async _recupererManquants(client, rapport) {
    let recuperes = 0;
    for (const g of (rapport && rapport.ecarts) || []) {
      if (g.sens !== 'a_recevoir' || g.connue || g.cause !== 'inconnue' || !Array.isArray(g.ids) || g.ids.length === 0) continue;
      try {
        const st = await this._recupererLignes(client, g.table, g.ids.map((i) => Number(i.id)));
        recuperes += st.applied;
        console.log(`🩹 Rattrapage ${g.table}: ${st.applied} ligne(s) jamais reçue(s) récupérée(s)` + (st.deferred ? `, ${st.deferred} différée(s)` : '') + (st.protegees ? `, ${st.protegees} protégée(s)` : ''));
      } catch (e) {
        if (this._isConnectionError(e)) throw e;
        console.warn(`⚠️  Rattrapage ${g.table} impossible: ${e.message}`);
      }
    }
    if (recuperes > 0) {
      // Les parents viennent peut-être d'arriver : on rejoue aussi les lignes mises en pause
      await this._processPullRetryQueue({ ignorerDelai: true });
    }
    return recuperes;
  }

  /**
   * Pull DELTA depuis Neon (pas de DELETE ici — voir _applyRemoteDeletions).
   *
   * Le curseur vient de sync_pull_state (ce qu'on a REÇU) et non d'operation_log
   * (ce qu'on a ENVOYÉ). Les lignes en échec partent en file de reprise, ce qui
   * permet au curseur d'avancer sans jamais perdre de donnée.
   */
  async _pullDeltaFromNeon() {
    try {
      const client = await this.cloudPool.connect();
      let pulled = 0;
      let connexionPerdue = false;

      try {
      // ── Étape 1 : Propager les suppressions depuis deleted_records ────────
      await this._applyRemoteDeletions(client);

      // ── Étape 2 : Pull delta des données nouvelles/modifiées ──────────────
      for (const table of PULL_TABLES) {
        try {
          const modCol = await this._resolveModificationColumn(client, table);
          if (!modCol) continue;

          const since = await this._getPullWatermark(table);

          // "${modCol}"::text : le pilote pg réinterprète un timestamp SANS
          // fuseau (colonne "date_modification") selon le fuseau LOCAL du
          // process Node, alors que Postgres le traite comme une valeur UTC
          // littérale. Sur une machine en UTC+1 (ex. Afrique de l'Ouest),
          // Date#toISOString() renvoie une heure -1h par rapport à la valeur
          // réellement stockée. Le curseur enregistré est alors perpétuellement
          // "en retard" d'1h sur la ligne qu'il est censé exclure : la même
          // ligne redevient "nouvelle" à chaque cycle, indéfiniment. Le cast
          // ::text contourne la conversion du driver et lit la valeur telle
          // qu'écrite (voir _rawTimestampToIso ci-dessous).
          // Lignes laissées de côté au cycle précédent (écriture locale en attente) : redemandées au cloud
          await this._reprendreProtegees(client, table);

          const result = await client.query(
            `SELECT *, "${modCol}"::text AS __mod_col_raw FROM "${table}" WHERE "${modCol}" > $1 ORDER BY "${modCol}" ASC LIMIT 5000`,
            [since]
          );
          if (result.rows.length === 0) continue;

          const ctx = await this._contexteReception(table);
          const st = await this._appliquerLignesDistantes(table, result.rows, since, ctx);
          pulled += st.applied;

          if (st.maxSeen !== since) await this._setPullWatermark(table, st.maxSeen);

          const details = [
            st.deferred ? `${st.deferred} différée(s)` : null,
            st.conflits ? `dont ${st.conflits} conflit(s) de clé` : null,
            st.protegees ? `${st.protegees} protégée(s) (écriture locale en attente)` : null,
          ].filter(Boolean).join(', ');
          console.log(`  📥 ${table}: ${st.applied} appliquée(s)${details ? `, ${details}` : ''}`);
        } catch (e) {
          console.warn(`  ⚠️  ${table}: erreur pull - ${e.message}`);
          // Liaison perdue : inutile d'attendre un délai par table restante.
          // Le curseur n'a pas avancé, la table sera reprise au prochain cycle.
          if (this._isConnectionError(e)) {
            connexionPerdue = true;
            this.isCloudAvailable = false;
            break;
          }
        }
      }

      if (connexionPerdue) return;

      // ── Étape 3 : rejouer les lignes différées, parents désormais présents ──
      await this._processPullRetryQueue();

      // ── Étape 4 : fusionner les doublons introduits par l'auto-seed ────────
      // (le pull vient peut-être de descendre l'équivalent cloud d'un
      //  enregistrement que ce poste avait créé de son côté)
      await this._reconcileNaturalKeyDuplicates(client);

      // ── Étape 5 : débloquer les fiches de stock en doublon avec le cloud ────
      await this._reconcileCompositeKeyConflicts(client);
      } catch (e) {
        if (this._isConnectionError(e)) connexionPerdue = true;
        throw e;
      } finally {
        // true => connexion détruite au lieu d'être remise (cassée) dans le pool ;
        // et surtout : jamais de connexion "oubliée" si une étape lève une erreur.
        client.release(connexionPerdue ? true : undefined);
      }
      if (pulled > 0) console.log(`📥 Pull delta: ${pulled} enregistrement(s) depuis Neon`);
    } catch (e) {
      console.error('❌ Erreur pull delta:', e.message);
    }
  }


  /**
   * Lit deleted_records dans Neon et supprime les enregistrements correspondants en local.
   * Respecte l'ordre FK inverse : enfants supprimés avant parents.
   */
  async _applyRemoteDeletions(client) {
    try {
      // Timestamp de la dernière lecture des deleted_records
      const lastCheck = await this.localPrisma.$queryRawUnsafe(
        `SELECT MAX(deleted_at) as ts FROM deleted_records`
      );
      const since = (() => {
        const ts = lastCheck[0]?.ts;
        if (!ts) return '1970-01-01T00:00:00Z';
        const tsNum = typeof ts === 'bigint' ? Number(ts) : ts;
        try { return new Date(tsNum).toISOString(); } catch { return '1970-01-01T00:00:00Z'; }
      })();

      // deleted_at::text : voir _rawTimestampToIso — évite le décalage d'1h
      // que Date#toISOString() introduit sur un timestamp sans fuseau.
      const result = await client.query(
        `SELECT table_name, record_id, deleted_at::text AS deleted_at, deleted_by
         FROM deleted_records WHERE deleted_at > $1 ORDER BY deleted_at ASC LIMIT 1000`,
        [since]
      );

      if (result.rows.length === 0) return;

      console.log(`🗑️  Propagation de ${result.rows.length} suppression(s) depuis Neon...`);

      // Trier dans l'ordre FK inverse (enfants avant parents)
      // ex: comptes_clients avant clients, comptes_fournisseurs avant fournisseurs
      const deletionOrder = [...PULL_TABLES].reverse();
      result.rows.sort((a, b) => {
        return deletionOrder.indexOf(a.table_name) - deletionOrder.indexOf(b.table_name);
      });

      for (const row of result.rows) {
        const { table_name, record_id, deleted_at, deleted_by } = row;
        try {
          // Supprimer localement
          await this.localPrisma.$executeRawUnsafe(
            `DELETE FROM "${table_name}" WHERE id = ?`, record_id
          );

          // Mémoriser dans deleted_records local pour ne pas re-pull
          await this.localPrisma.$executeRawUnsafe(
            `INSERT OR IGNORE INTO deleted_records (table_name, record_id, deleted_at, deleted_by)
             VALUES (?, ?, ?, ?)`,
            table_name,
            record_id,
            this._rawTimestampToIso(deleted_at) || deleted_at,
            deleted_by || null
          );

          console.log(`  🗑️  Supprimé local: ${table_name} (id=${record_id})`);
        } catch (e) {
          // Si l'enregistrement n'existe pas en local, pas grave
          if (!e.message.includes('no rows') && !e.message.includes('FOREIGN KEY')) {
            console.warn(`  ⚠️  Suppression locale ${table_name} (id=${record_id}): ${e.message}`);
          }
        }
      }

      console.log(`✅ ${result.rows.length} suppression(s) propagée(s)`);
    } catch (e) {
      // Si deleted_records n'existe pas encore (vieux poste), ignorer silencieusement
      if (e.message.includes('deleted_records') && e.message.includes('does not exist')) {
        console.warn('⚠️  Table deleted_records absente de Neon — suppression propagation ignorée');
      } else {
        console.warn('⚠️  Erreur propagation suppressions:', e.message);
      }
    }
  }

  async _syncCycle() {
    // Garde-fou : un cycle resté bloqué (liaison gelée) ne doit pas empêcher
    // toutes les synchros suivantes. Au-delà de 5 min on le déclare mort.
    if (this.isSyncing) {
      const depuis = Date.now() - (this.syncStartedAt || Date.now());
      if (depuis < SYNC_CYCLE_MAX_MS) return;
      console.warn(`⚠️  Cycle de synchro bloqué depuis ${Math.round(depuis / 1000)} s — réinitialisation`);
      if (this.cloudPool) {
        const ancien = this.cloudPool;
        this.cloudPool = null;
        ancien.end().catch(() => {});
      }
    }
    this.isSyncing = true;
    this.syncStartedAt = Date.now();
    try {
      const available = await this._checkCloudConnection();
      if (!available) return;
      await this._replayPendingOperations();
      // Liaison perdue pendant l'envoi : on laisse le reste en attente
      if (!this.isCloudAvailable) return;
      await this._pullDeltaFromNeon();
      if (!this.isCloudAvailable) return;
      this.lastSuccessfulSyncAt = new Date().toISOString();
    } catch (e) {
      console.error('❌ Erreur sync:', e.message);
    } finally {
      this.isSyncing = false;
    }
  }

  _isTimestampField(snakeKey) {
    // Explicit timestamp field patterns — must start or end with date-related words
    return (
      snakeKey === 'derniere_maj' ||
      snakeKey === 'date_derniere_maj' ||
      snakeKey.startsWith('date_') ||
      snakeKey.endsWith('_date') ||
      snakeKey.endsWith('_at') ||
      snakeKey.endsWith('_maj') ||
      snakeKey === 'timestamp' ||
      snakeKey === 'created_at' ||
      snakeKey === 'updated_at'
    );
  }

  _toSnakeCase(obj) {
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      if (Array.isArray(value)) continue;
      if (value !== null && typeof value === 'object' && !(value instanceof Date)) continue;
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      if (value instanceof Date) {
        result[snakeKey] = value.toISOString();
      } else if (typeof value === 'bigint') {
        result[snakeKey] = this._isTimestampField(snakeKey)
          ? new Date(Number(value)).toISOString()
          : Number(value);
      } else if (typeof value === 'number' && this._isTimestampField(snakeKey) && value > 1000000000000) {
        // Large integer that looks like a ms timestamp
        result[snakeKey] = new Date(value).toISOString();
      } else {
        result[snakeKey] = value;
      }
    }
    return result;
  }

  async _applyToCloud(client, tableName, operation, data) {
    const row = this._toSnakeCase(data);

    // Ensure timestamp fields are proper ISO strings for PostgreSQL
    for (const [key, val] of Object.entries(row)) {
      if (val === null || val === undefined) continue;
      if (this._isTimestampField(key)) {
        if (typeof val === 'number' || typeof val === 'bigint') {
          row[key] = new Date(Number(val)).toISOString();
        } else if (typeof val === 'string') {
          const d = new Date(val);
          if (!isNaN(d.getTime())) row[key] = d.toISOString();
        }
      }
    }

    if (operation === 'DELETE') {
      // Neutraliser les références qui ne doivent pas être supprimées
      for (const [table, colonne] of (NULLIFY_ON_DELETE[tableName] || [])) {
        try {
          await client.query(`UPDATE "${table}" SET "${colonne}" = NULL WHERE "${colonne}" = $1`, [row.id]);
        } catch (e) {
          console.warn(`⚠️  Neutralisation ${table}.${colonne}: ${e.message}`);
        }
      }

      // Supprimer les lignes filles avant le parent (Neon applique les FK,
      // contrairement au SQLite local)
      for (const [table, colonne] of (CASCADE_ON_DELETE[tableName] || [])) {
        try {
          const r = await client.query(`DELETE FROM "${table}" WHERE "${colonne}" = $1`, [row.id]);
          if (r.rowCount > 0) console.log(`   ↳ ${table}: ${r.rowCount} ligne(s) fille(s) supprimée(s)`);
        } catch (e) {
          // Table absente sur d'anciennes installations : non bloquant
          if (!e.message.includes('does not exist')) {
            console.warn(`⚠️  Cascade ${table}.${colonne}: ${e.message}`);
          }
        }
      }

      await client.query(`DELETE FROM "${tableName}" WHERE id = $1`, [row.id]);
      // Enregistrer la suppression dans deleted_records pour propagation aux autres postes
      try {
        await client.query(
          `INSERT INTO "deleted_records" (table_name, record_id, deleted_at) VALUES ($1, $2, NOW())`,
          [tableName, row.id]
        );
      } catch (e) {
        console.warn(`⚠️  deleted_records INSERT failed (${tableName} id=${row.id}): ${e.message}`);
      }
      return;
    }

    // Defaults for required fields (même logique qu'avant)
    if (tableName === 'produits') {
      if (!row.reference) {
        const year = new Date().getFullYear();
        row.reference = `PRD${year}${String(row.id || Date.now()).padStart(4, '0')}`;
      }
      if (row.prix_unitaire === null || row.prix_unitaire === undefined) row.prix_unitaire = 0;
      if (!row.nom) row.nom = `Produit ${row.id || 'Sans nom'}`;
    }

    if (tableName === 'fournisseurs') {
      if (!row.nom || row.nom === 'undefined') row.nom = `Fournisseur ${row.id || 'Inconnu'}`;
      if (!row.email || row.email === 'undefined' || row.email === 'null') row.email = `fournisseur${row.id}@example.com`;
      const now = new Date().toISOString();
      if (!row.date_creation || row.date_creation === 'undefined') row.date_creation = now;
      if (!row.date_modification || row.date_modification === 'undefined') row.date_modification = now;
    }

    if (tableName === 'clients') {
      if (!row.nom || row.nom === 'undefined') row.nom = `Client ${row.id || 'Inconnu'}`;
      if (!row.prenom || row.prenom === 'undefined') row.prenom = '';
      const now = new Date().toISOString();
      if (!row.date_creation || row.date_creation === 'undefined') row.date_creation = now;
      if (!row.date_modification || row.date_modification === 'undefined') row.date_modification = now;
    }

    if (tableName === 'user_boutique_assignments') {
      const now = new Date().toISOString();
      if (!row.date_creation) row.date_creation = now;
      if (!row.date_modification) row.date_modification = now;
    }

    if (tableName === 'boutiques') {
      if (!row.nom) row.nom = `Boutique ${row.id || ''}`.trim();
      const now = new Date().toISOString();
      if (!row.date_creation) row.date_creation = now;
      if (!row.date_modification) row.date_modification = now;
    }

    // Remove date_modification for tables that don't have it
    if (TABLES_WITHOUT_DATE_MODIFICATION.includes(tableName)) {
      delete row.date_modification;
    }

    // Compléter les colonnes NOT NULL absentes du payload
    for (const [colonne, valeurParDefaut] of Object.entries(COLONNES_OBLIGATOIRES[tableName] || {})) {
      if (row[colonne] === undefined || row[colonne] === null) {
        row[colonne] = valeurParDefaut();
      }
    }

    const keys = Object.keys(row).filter(k => {
      if (row[k] === undefined) return false;
      if (row[k] === null) return false;
      if (row[k] === 'undefined') return false;
      if (row[k] === 'null') return false;
      if (k.startsWith('_')) return false;
      return true;
    });
    const values = keys.map(k => row[k]);

    if (operation === 'INSERT') {
      const cols = keys.map(k => `"${k}"`).join(', ');
      const placeholders = keys.map((_, i) => '$' + (i + 1)).join(', ');
      const updateKeys = keys.filter(k => k !== 'id');

      if (updateKeys.length === 0) {
        const query = `INSERT INTO "${tableName}" (${cols}) VALUES (${placeholders}) ON CONFLICT (id) DO NOTHING`;
        try {
          await client.query(query, values);
        } catch (queryErr) {
          console.error(`❌ Erreur SQL INSERT ${tableName}:`, queryErr.message);
          throw queryErr;
        }
      } else {
        const updates = updateKeys.map(k => `"${k}" = EXCLUDED."${k}"`).join(', ');
        const query = `INSERT INTO "${tableName}" (${cols}) VALUES (${placeholders}) ON CONFLICT (id) DO UPDATE SET ${updates}`;
        try {
          await client.query(query, values);
        } catch (queryErr) {
          console.error(`❌ Erreur SQL INSERT ${tableName}:`, queryErr.message);
          throw queryErr;
        }
      }
    } else if (operation === 'UPDATE') {
      // Tables qui utilisent des upserts localement → doivent faire UPSERT dans Neon
      const UPSERT_TABLES = ['stock_boutiques', 'mouvements_stock'];
      
      if (UPSERT_TABLES.includes(tableName)) {
        // UPSERT : peut créer l'enregistrement s'il n'existe pas
        const updateKeys = keys.filter(k => k !== 'id');
        if (updateKeys.length === 0) return;
        
        const cols = keys.map(k => `"${k}"`).join(', ');
        const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
        const updates = updateKeys.map(k => `"${k}" = EXCLUDED."${k}"`).join(', ');
        const query = `INSERT INTO "${tableName}" (${cols}) VALUES (${placeholders}) ON CONFLICT (id) DO UPDATE SET ${updates}`;
        
        try {
          await client.query(query, values);
        } catch (queryErr) {
          console.error(`❌ Erreur SQL UPSERT ${tableName}:`, queryErr.message);
          throw queryErr;
        }
      } else {
        // UPDATE pur : ne crée pas l'enregistrement s'il n'existe pas
        const nonIdKeys = keys.filter(k => k !== 'id');
        if (nonIdKeys.length === 0) return;
        const sets = nonIdKeys.map((k, i) => `"${k}" = $${i + 1}`).join(', ');
        const vals = nonIdKeys.map(k => row[k]);
        vals.push(row.id);
        const whereId = '$' + vals.length;
        const query = `UPDATE "${tableName}" SET ${sets} WHERE id = ${whereId}`;
        
        try {
          const result = await client.query(query, vals);
          if (result.rowCount === 0) {
            console.log(`  Info: ${tableName} (id=${row.id}) pas encore dans Neon`);
          }
        } catch (queryErr) {
          console.error(`❌ Erreur SQL UPDATE ${tableName}:`, queryErr.message);
          throw queryErr;
        }
      }
    }
  }

  /**
   * NOUVEAU: logOperation - Log une opération dans le journal des événements
   * C'est LA méthode que les routes doivent appeler
   */
  async logOperation(tableName, operation, data, userId = null) {
    if (!this.cloudUrl) return; // Pas de sync en mode local-only

    const operationId = uuidv4();
    
    try {
      // Safely serialize data, handling BigInt and Date objects
      let dataStr;
      try {
        dataStr = JSON.stringify(data, (key, value) => {
          if (typeof value === 'bigint') {
            // Only convert to ISO if it's a known timestamp field name
            const snakeKey = key.replace(/[A-Z]/g, l => `_${l.toLowerCase()}`);
            const isTs = snakeKey === 'derniere_maj' || snakeKey === 'date_derniere_maj' ||
              snakeKey.startsWith('date_') || snakeKey.endsWith('_date') ||
              snakeKey.endsWith('_at') || snakeKey.endsWith('_maj') ||
              key === 'timestamp' || key === 'createdAt' || key === 'updatedAt';
            return isTs ? new Date(Number(value)).toISOString() : Number(value);
          }
          if (value instanceof Date) return value.toISOString();
          return value;
        });
      } catch (jsonErr) {
        console.warn(`⚠️  JSON stringify failed for ${tableName}, using safe serialization`);
        // Fallback: serialize only safe properties
        const safeData = {};
        for (const [k, v] of Object.entries(data || {})) {
          if (typeof v === 'bigint') {
            const isTs = k.includes('date') || k.includes('_maj') || k.includes('_at') || k.includes('Maj');
            safeData[k] = isTs ? new Date(Number(v)).toISOString() : Number(v);
          } else if (v instanceof Date) {
            safeData[k] = v.toISOString();
          } else if (typeof v !== 'object') {
            safeData[k] = v;
          }
        }
        dataStr = JSON.stringify(safeData);
      }

      // ── Déduplication ────────────────────────────────────────────────────
      // Trois mécanismes journalisent les écritures (appels explicites dans les
      // routes, middleware HTTP, hooks Prisma) et se recouvrent sur plusieurs
      // tables : une même écriture peut être journalisée jusqu'à trois fois.
      // Plutôt que de pousser trois fois vers Neon, on fusionne dans
      // l'opération déjà en attente — chaque mécanisme apporte des colonnes
      // que les autres n'ont pas, l'union est donc plus complète que chacun
      // pris isolément.
      if (data.id && operation !== 'DELETE') {
        const enAttente = await this.localPrisma.$queryRawUnsafe(
          `SELECT operation_id, data FROM operation_log
           WHERE table_name = ? AND record_id = ? AND operation_type = ? AND status = 'pending'
           ORDER BY id DESC LIMIT 1`,
          tableName, data.id, operation
        );

        if (enAttente.length > 0) {
          let fusion = dataStr;
          try {
            fusion = JSON.stringify({
              ...JSON.parse(enAttente[0].data || '{}'),
              ...JSON.parse(dataStr),
            });
          } catch (_) { /* payload illisible : on garde le plus récent */ }

          // Le timestamp d'origine est conservé pour ne pas fausser l'ordre de replay
          await this.localPrisma.$executeRawUnsafe(
            `UPDATE operation_log SET data = ? WHERE operation_id = ?`,
            fusion, enAttente[0].operation_id
          );
          return;
        }
      }

      await this.localPrisma.$executeRawUnsafe(
        `INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, user_id, status)
         VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
        operationId,
        operation,
        tableName,
        data.id || null,
        dataStr,
        userId
      );


      // Si c'est un DELETE, annuler les INSERT/UPDATE pending pour le même enregistrement
      // (évite des erreurs FK lors du replay : INSERT d'un compte dont le client a été supprimé)
      if (operation === 'DELETE' && data.id) {
        await this.localPrisma.$executeRawUnsafe(
          `UPDATE operation_log SET status = 'cancelled'
           WHERE table_name = ? AND record_id = ? AND operation_type IN ('INSERT', 'UPDATE')
           AND status = 'pending'`,
          tableName,
          data.id
        );
      }

      console.log(`📋 Logged: ${operation} ${tableName} (id=${data.id})`);

      // Si cloud available et pas en syncing, lancer sync immédiate
      if (this.isCloudAvailable && !this.isSyncing) {
        setImmediate(() => this._syncCycle());
      }
    } catch (e) {
      console.warn('⚠️  Erreur logOperation:', e.message);
      // Don't throw - let operations continue even if sync fails
    }
  }

  /**
   * BACKWARD COMPATIBILITY: enqueue() → logOperation()
   * Routes anciennes utilisent .enqueue(), on redirige vers logOperation()
   */
  async enqueue(tableName, operation, data, userId = null) {
    return this.logOperation(tableName, operation, data, userId);
  }

  /**
   * Supprime dans Neon par une colonne FK (ex: client_id) quand l'id local est inconnu
   * Utilisé quand le compte est absent du local mais peut exister dans Neon
   */
  async deleteByClientId(tableName, clientId) {
    if (!this.cloudUrl || !this.isCloudAvailable) return;
    try {
      const client = await this.cloudPool.connect();
      await client.query(`DELETE FROM "${tableName}" WHERE client_id = $1`, [clientId]);
      client.release();
      console.log(`📋 Direct DELETE: ${tableName} WHERE client_id=${clientId}`);
    } catch (e) {
      console.warn(`⚠️  deleteByClientId ${tableName} (client_id=${clientId}): ${e.message}`);
    }
  }

  async deleteByFournisseurId(tableName, fournisseurId) {
    if (!this.cloudUrl || !this.isCloudAvailable) return;
    try {
      const client = await this.cloudPool.connect();
      await client.query(`DELETE FROM "${tableName}" WHERE fournisseur_id = $1`, [fournisseurId]);
      client.release();
      console.log(`📋 Direct DELETE: ${tableName} WHERE fournisseur_id=${fournisseurId}`);
    } catch (e) {
      console.warn(`⚠️  deleteByFournisseurId ${tableName} (fournisseur_id=${fournisseurId}): ${e.message}`);
    }
  }

  getStatus() {
    return {
      cloudEnabled: !!this.cloudUrl,
      cloudAvailable: this.isCloudAvailable,
      installationId: installation.getInstallationId(),
      lastError: this.lastCloudError,
      lastSuccessfulSyncAt: this.lastSuccessfulSyncAt,
      mode: !this.cloudUrl ? 'local-only' : this.isCloudAvailable ? 'hybrid' : 'offline-fallback'
    };
  }

  /**
   * Détail des lignes reçues de Neon qui n'ont pas pu être appliquées.
   * Sert au diagnostic : une donnée manquante sur un poste se lit ici.
   */
  async getPullIssues() {
    try {
      const rows = await this.localPrisma.$queryRawUnsafe(
        `SELECT table_name, COUNT(*) AS total,
                SUM(CASE WHEN attempts >= 20 THEN 1 ELSE 0 END) AS abandonnees, -- en pause : rejouées 1 fois par heure
                MAX(last_error) AS derniere_erreur
         FROM sync_pull_retry GROUP BY table_name ORDER BY total DESC`
      );
      return rows.map(r => ({
        table: r.table_name,
        enAttente: Number(r.total),
        abandonnees: Number(r.abandonnees || 0),
        derniereErreur: String(r.derniere_erreur || '').replace(/\s+/g, ' ').substring(0, 200),
      }));
    } catch (e) {
      return [];
    }
  }

  stop() {
    if (this.syncInterval) clearInterval(this.syncInterval);
    if (this.driftInterval) clearInterval(this.driftInterval);
    if (this.driftTimeout) clearTimeout(this.driftTimeout);
    if (this.cloudPool) this.cloudPool.end();
  }
}

const instance = new SyncServiceV2();
instance.PULL_TABLES = PULL_TABLES;
module.exports = instance;
