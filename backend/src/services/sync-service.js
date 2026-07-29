/**
 * SyncService V2 — Event Sourcing + Hybrid Mode
 * Synchronisation bidirectionnelle SQLite local <-> Neon cloud avec replay d'événements
 */

const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const installation = require('../utils/installation');

// Tables à synchroniser depuis Neon vers local (dans l'ordre des dépendances FK)
const PULL_TABLES = [
  'user_roles', 'utilisateurs', 'boutiques', 'user_boutique_assignments',
  'categories', 'produits', 'historique_prix_achat', 'stock', 'stock_boutiques',
  'fournisseurs', 'comptes_fournisseurs', 'clients', 'comptes_clients',
  'cash_registers', 'cash_sessions', 'cash_movements', 'movement_categories',
  'financial_movements', 'commandes_approvisionnement', 'details_commandes_approvisionnement',
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

class SyncServiceV2 {
  constructor() {
    this.localPrisma = null;
    this.cloudPool = null;
    this.isCloudAvailable = false;
    this.syncInterval = null;
    this.isSyncing = false;
    this.cloudUrl = process.env.CLOUD_DB_URL;
    this._modColumnCache = {};
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
    console.log('✅ SyncService V2 démarré (Event Sourcing + Hybrid Mode)');
  }

  async _checkCloudConnection() {
    if (!this.cloudUrl) return false;
    try {
      if (!this.cloudPool) {
        this.cloudPool = new Pool({
          connectionString: this.cloudUrl,
          ssl: { rejectUnauthorized: false },
          max: 3,
          idleTimeoutMillis: 10000,
          connectionTimeoutMillis: 10000,
        });
      }
      const client = await this.cloudPool.connect();
      await client.query('SELECT 1');
      client.release();
      if (!this.isCloudAvailable) {
        console.log('☁️  Connexion Neon établie — mode hybride actif');
        this.isCloudAvailable = true;
      }
      return true;
    } catch (e) {
      if (this.isCloudAvailable) {
        console.warn('⚠️  Neon inaccessible — mode offline-fallback');
      }
      this.isCloudAvailable = false;
      return false;
    }
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
          console.error(`  ❌ Erreur replay ${op.table_name}: ${e.message}`);
          
          await this.localPrisma.$executeRawUnsafe(
            `UPDATE operation_log SET status = 'failed', error_message = ? 
             WHERE operation_id = ?`,
            e.message.substring(0, 500),
            op.operation_id
          );
        }
      }

      client.release();
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
  async _ensureColonnesCloud() {
    const AJOUTS = [
      [`financial_movements`, `statut`, `TEXT NOT NULL DEFAULT 'actif'`],
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
   */
  async _processPullRetryQueue() {
    try {
      // Au-delà de MAX_TENTATIVES l'échec est structurel (conflit de clé
      // naturelle, parent réellement absent) : on cesse de le rejouer à chaque
      // cycle mais on le conserve, visible via GET /sync/status.
      const MAX_TENTATIVES = 20;

      const rows = await this.localPrisma.$queryRawUnsafe(
        `SELECT id, table_name, record_id, payload, attempts FROM sync_pull_retry
         WHERE attempts < ? LIMIT 5000`,
        MAX_TENTATIVES
      );
      if (rows.length === 0) return;

      rows.sort((a, b) => PULL_TABLES.indexOf(a.table_name) - PULL_TABLES.indexOf(b.table_name));

      let repaired = 0;
      const stillFailing = {};

      for (const entry of rows) {
        try {
          await this._mergeRemoteRow(entry.table_name, JSON.parse(entry.payload));
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
      const remaining = Object.entries(stillFailing);
      if (remaining.length > 0) {
        console.warn(`⚠️  File de reprise: ${remaining.map(([t, n]) => `${t}=${n}`).join(', ')} encore en échec`);
      }
    } catch (e) {
      console.warn('⚠️  Erreur traitement file de reprise:', e.message);
    }
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

      // ── Étape 1 : Propager les suppressions depuis deleted_records ────────
      await this._applyRemoteDeletions(client);

      // ── Étape 2 : Pull delta des données nouvelles/modifiées ──────────────
      for (const table of PULL_TABLES) {
        try {
          const modCol = await this._resolveModificationColumn(client, table);
          if (!modCol) continue;

          const since = await this._getPullWatermark(table);

          const result = await client.query(
            `SELECT * FROM "${table}" WHERE "${modCol}" > $1 ORDER BY "${modCol}" ASC LIMIT 5000`,
            [since]
          );
          if (result.rows.length === 0) continue;

          // Ne pas ré-insérer un enregistrement supprimé localement.
          //
          // Le statut 'failed' doit impérativement être couvert : une
          // suppression rejetée par Neon laisse la ligne présente côté cloud,
          // et sans ce garde-fou le pull la réinsère en local — l'élément
          // supprimé « revient » à l'écran. Tant que la suppression n'est pas
          // aboutie, on ignore la ligne distante, sans limite de temps.
          const recentDeletes = await this.localPrisma.$queryRawUnsafe(
            `SELECT record_id FROM operation_log
             WHERE table_name = ? AND operation_type = 'DELETE'
             AND ( status IN ('pending', 'failed')
                OR (status = 'synced' AND timestamp > datetime('now', '-1 hour')) )`,
            table
          );
          const deletedIds = new Set(recentDeletes.map(r => Number(r.record_id)));

          // Ne pas écraser une ligne dont la modification locale n'est pas
          // encore partie vers le cloud.
          //
          // Sans ce garde-fou, le pull applique la valeur (périmée) de Neon
          // par-dessus une écriture locale toute fraîche : le stock restauré
          // après une annulation repassait à sa valeur d'avant, jusqu'à ce que
          // la poussée finisse par le rétablir — et parfois définitivement si
          // c'est la valeur périmée qui remportait la course.
          const enAttenteLocale = await this.localPrisma.$queryRawUnsafe(
            `SELECT DISTINCT record_id FROM operation_log
             WHERE table_name = ? AND status IN ('pending', 'failed')
             AND operation_type <> 'DELETE' AND record_id IS NOT NULL`,
            table
          );
          const idsEnAttente = new Set(enAttenteLocale.map(r => Number(r.record_id)));

          let maxSeen = since;
          let applied = 0, deferred = 0, conflits = 0, protegees = 0;

          for (const row of result.rows) {
            const ts = row[modCol];
            const tsIso = ts instanceof Date ? ts.toISOString() : (ts ? String(ts) : null);
            if (tsIso && tsIso > maxSeen) maxSeen = tsIso;

            if (deletedIds.has(Number(row.id))) continue;

            // Écriture locale pas encore poussée : elle fait foi, on ne
            // l'écrase pas. Le curseur avance quand même (la ligne sera
            // reprise au cycle suivant, une fois la poussée effectuée).
            if (idsEnAttente.has(Number(row.id))) { protegees++; continue; }

            try {
              await this._mergeRemoteRow(table, row);
              applied++; pulled++;
            } catch (insertErr) {
              // Un conflit UNIQUE signale une divergence réelle : la ligne
              // distante entre en collision avec une AUTRE ligne locale sur une
              // clé naturelle. L'ignorer silencieusement fait disparaître la
              // donnée sans la moindre trace — on la conserve et on la signale.
              if (insertErr.message.includes('UNIQUE constraint failed')) conflits++;
              deferred++;
              await this._enqueuePullRetry(table, row, insertErr.message);
            }
          }

          if (maxSeen !== since) await this._setPullWatermark(table, maxSeen);

          const details = [
            deferred ? `${deferred} différée(s)` : null,
            conflits ? `dont ${conflits} conflit(s) de clé` : null,
            protegees ? `${protegees} protégée(s) (écriture locale en attente)` : null,
          ].filter(Boolean).join(', ');
          console.log(`  📥 ${table}: ${applied} appliquée(s)${details ? `, ${details}` : ''}`);
        } catch (e) {
          console.warn(`  ⚠️  ${table}: erreur pull - ${e.message}`);
        }
      }

      // ── Étape 3 : rejouer les lignes différées, parents désormais présents ──
      await this._processPullRetryQueue();

      // ── Étape 4 : fusionner les doublons introduits par l'auto-seed ────────
      // (le pull vient peut-être de descendre l'équivalent cloud d'un
      //  enregistrement que ce poste avait créé de son côté)
      await this._reconcileNaturalKeyDuplicates(client);

      client.release();
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

      const result = await client.query(
        `SELECT table_name, record_id, deleted_at, deleted_by
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
            deleted_at instanceof Date ? deleted_at.toISOString() : deleted_at,
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
    if (this.isSyncing) return;
    this.isSyncing = true;
    try {
      const available = await this._checkCloudConnection();
      if (!available) return;
      await this._replayPendingOperations();
      await this._pullDeltaFromNeon();
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
                SUM(CASE WHEN attempts >= 20 THEN 1 ELSE 0 END) AS abandonnees,
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
    if (this.cloudPool) this.cloudPool.end();
  }
}

module.exports = new SyncServiceV2();
