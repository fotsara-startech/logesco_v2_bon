/**
 * SyncService V2 — Event Sourcing + Hybrid Mode
 * Synchronisation bidirectionnelle SQLite local <-> Neon cloud avec replay d'événements
 */

const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

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

class SyncServiceV2 {
  constructor() {
    this.localPrisma = null;
    this.cloudPool = null;
    this.isCloudAvailable = false;
    this.syncInterval = null;
    this.isSyncing = false;
    this.cloudUrl = process.env.CLOUD_DB_URL;
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
    
    await this._checkCloudConnection();
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
   * NOUVEAU: Pull DELTA uniquement (pas de DELETE)
   * Récupère uniquement les nouvelles données depuis Neon
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
          // Trouver le dernier timestamp synchronisé
          const lastSync = await this.localPrisma.$queryRawUnsafe(
            `SELECT MAX(timestamp) as ts FROM operation_log 
             WHERE table_name = ? AND status = 'synced'`,
            table
          );

          const since = (() => {
            const ts = lastSync[0]?.ts;
            if (!ts) return '1970-01-01T00:00:00Z';
            // Gérer BigInt et Number
            const tsNum = typeof ts === 'bigint' ? Number(ts) : ts;
            try {
              return new Date(tsNum).toISOString();
            } catch (e) {
              return '1970-01-01T00:00:00Z';
            }
          })();

          // Pull UNIQUEMENT les nouveaux depuis Neon
          let result;
          try {
            result = await client.query(
              `SELECT * FROM "${table}" WHERE date_modification > $1 LIMIT 5000`,
              [since]
            );
          } catch (colErr) {
            // Fallback pour les tables sans date_modification (legacy, all tables should now have it)
            const altCols = {
              'mouvements_stock': 'date_mouvement',
              'cash_movements': 'date_creation',
              'historique_recus': 'date_generation',
              'transactions_comptes': 'date_transaction',
              'stock_inventories': 'date_creation',
              'inventory_items': 'date_comptage'
            };
            const altCol = altCols[table];
            if (altCol) {
              result = await client.query(
                `SELECT * FROM "${table}" WHERE "${altCol}" > $1 LIMIT 5000`,
                [since]
              );
            } else {
              result = { rows: [] };
            }
          }

          if (result.rows.length === 0) continue;

          // Charger les IDs récemment supprimés localement pour cette table (ne pas les ré-insérer)
          const recentDeletes = await this.localPrisma.$queryRawUnsafe(
            `SELECT record_id FROM operation_log 
             WHERE table_name = ? AND operation_type = 'DELETE' AND status IN ('pending', 'synced')
             AND timestamp > datetime('now', '-1 hour')`,
            table
          );
          const deletedIds = new Set(recentDeletes.map(r => Number(r.record_id)));

          // Insérer localement (merge, pas delete)
          for (const row of result.rows) {
            // Ne pas ré-insérer un enregistrement qu'on vient de supprimer localement
            if (deletedIds.has(Number(row.id))) {
              continue;
            }
            try {
              const keys = Object.keys(row).filter(k => row[k] !== null && row[k] !== undefined);
              const cols = keys.map(k => `"${k}"`).join(', ');
              const placeholders = keys.map(() => '?').join(', ');
              const updates = keys
                .filter(k => k !== 'id')
                .map(k => `"${k}" = excluded."${k}"`)
                .join(', ');
              const vals = keys.map(k => {
                const val = row[k];
                if (val instanceof Date) return val.toISOString();
                if (typeof val === 'bigint') return Number(val);
                return val;
              });

              await this.localPrisma.$executeRawUnsafe(
                `INSERT INTO "${table}" (${cols}) VALUES (${placeholders}) 
                 ON CONFLICT(id) DO UPDATE SET ${updates}`,
                ...vals
              );
              pulled++;
            } catch (insertErr) {
              if (insertErr.message.includes('FOREIGN KEY constraint failed') && table === 'comptes_clients') {
                // Le client parent n'existe pas encore en local — essayer de le récupérer depuis Neon
                try {
                  const clientId = row.client_id;
                  const parentResult = await client.query(`SELECT * FROM "clients" WHERE id = $1`, [clientId]);
                  if (parentResult.rows.length > 0) {
                    const parent = parentResult.rows[0];
                    const pKeys = Object.keys(parent).filter(k => parent[k] !== null && parent[k] !== undefined);
                    const pCols = pKeys.map(k => `"${k}"`).join(', ');
                    const pPh = pKeys.map(() => '?').join(', ');
                    const pUpd = pKeys.filter(k => k !== 'id').map(k => `"${k}" = excluded."${k}"`).join(', ');
                    const pVals = pKeys.map(k => {
                      const v = parent[k];
                      if (v instanceof Date) return v.toISOString();
                      if (typeof v === 'bigint') return Number(v);
                      return v;
                    });
                    await this.localPrisma.$executeRawUnsafe(
                      `INSERT INTO "clients" (${pCols}) VALUES (${pPh}) ON CONFLICT(id) DO UPDATE SET ${pUpd}`,
                      ...pVals
                    );
                    // Réessayer le compte maintenant que le client existe
                    await this.localPrisma.$executeRawUnsafe(
                      `INSERT INTO "${table}" (${cols}) VALUES (${placeholders}) ON CONFLICT(id) DO UPDATE SET ${updates}`,
                      ...vals
                    );
                    pulled++;
                  }
                } catch (retryErr) {
                  console.warn(`  ⚠️  ${table} retry échoué (id=${row.id}): ${retryErr.message}`);
                }
              } else if (!insertErr.message.includes('UNIQUE constraint failed')) {
                console.warn(`  ⚠️  ${table} merge échoué (id=${row.id}): ${insertErr.message}`);
              }
            }
          }

          if (result.rows.length > 0) {
            console.log(`  📥 ${table}: ${result.rows.length} nouveau(x), ${pulled} total`);
          }
        } catch (e) {
          console.warn(`  ⚠️  ${table}: erreur pull - ${e.message}`);
        }
      }

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
      mode: !this.cloudUrl ? 'local-only' : this.isCloudAvailable ? 'hybrid' : 'offline-fallback'
    };
  }

  stop() {
    if (this.syncInterval) clearInterval(this.syncInterval);
    if (this.cloudPool) this.cloudPool.end();
  }
}

module.exports = new SyncServiceV2();
