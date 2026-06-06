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
      pending.sort((a, b) => {
        const orderA = PULL_TABLES.indexOf(a.table_name);
        const orderB = PULL_TABLES.indexOf(b.table_name);
        // Si les tables sont différentes, trier par ordre de dépendances
        if (orderA !== orderB) return orderA - orderB;
        // Même table : garder l'ordre chronologique
        return 0;
      });

      console.log(`📋 [V2] Replay de ${pending.length} opération(s) en attente...`);
      const client = await this.cloudPool.connect();

      for (const op of pending) {
        try {
          const data = typeof op.data === 'string' ? JSON.parse(op.data) : op.data;
          
          console.log(`  ⏮️  Replay: ${op.operation_type} ${op.table_name} (id=${op.record_id})`);
          
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

          // Insérer localement (merge, pas delete)
          for (const row of result.rows) {
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
              // Ignorer silencieusement les erreurs UNIQUE constraint (normal en multi-boutique)
              if (!insertErr.message.includes('UNIQUE constraint failed')) {
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
