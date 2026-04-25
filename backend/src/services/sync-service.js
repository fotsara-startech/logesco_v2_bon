/**
 * SyncService — Synchronisation bidirectionnelle SQLite local <-> Neon cloud
 *
 * Logique :
 * - Toutes les écritures vont d'abord en local (SQLite via Prisma)
 * - Une sync_queue enregistre chaque opération
 * - Quand Neon est accessible, la queue est rejouée sur Neon
 * - Neon reste la source de vérité partagée entre tous les utilisateurs
 */

const { Pool } = require('pg');

// Tables avec date_modification pour le pull (dans l'ordre FK)
const PULL_TABLES = [
  'user_roles',
  'utilisateurs',
  'boutiques',
  'categories',
  'produits',
  'stock',
  'stock_boutiques',
  'fournisseurs',
  'clients',
  'cash_registers',
  'cash_sessions',
  'cash_movements',
  'movement_categories',
  'financial_movements',
  'ventes',
  'details_ventes',
  'ventes_proforma',
  'details_ventes_proforma',
  'mouvements_stock',
];

class SyncService {
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

    console.log('🔄 SyncService: initialisation...');
    await this._createLocalTables();
    await this._checkCloudConnection();

    if (this.isCloudAvailable) {
      // Push initial des données existantes si Neon est vide
      await this._initialSync();
    }

    // Vérification + sync toutes les 30 secondes
    this.syncInterval = setInterval(() => this._syncCycle(), 30000);
    console.log('✅ SyncService démarré');
  }

  /**
   * Crée les tables locales nécessaires au sync
   */
  async _createLocalTables() {
    try {
      await this.localPrisma.$executeRawUnsafe(`
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          operation TEXT NOT NULL,
          record_id TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          synced INTEGER DEFAULT 0,
          error TEXT
        )
      `);
      await this.localPrisma.$executeRawUnsafe(`
        CREATE TABLE IF NOT EXISTS sync_meta (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      `);
    } catch (e) {
      // Tables déjà existantes
    }
  }

  /**
   * Vérifie si Neon est accessible via pg Pool
   */
  async _checkCloudConnection() {
    if (!this.cloudUrl) return false;

    try {
      if (!this.cloudPool) {
        this.cloudPool = new Pool({
          connectionString: this.cloudUrl,
          ssl: { rejectUnauthorized: false },
          max: 3,
          idleTimeoutMillis: 10000,
          connectionTimeoutMillis: 5000,
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
   * Sync initial — envoie toutes les données locales vers Neon si Neon est vide
   */
  async _initialSync() {
    try {
      const client = await this.cloudPool.connect();
      const result = await client.query('SELECT COUNT(*) as total FROM utilisateurs');
      client.release();

      if (parseInt(result.rows[0].total) > 0) {
        console.log('☁️  Neon déjà peuplé — sync initiale ignorée');
        return;
      }

      console.log('📦 Neon vide — démarrage de la sync initiale...');

      // Tables dans l'ordre des dépendances FK
      const tables = [
        'user_roles', 'utilisateurs', 'boutiques', 'user_boutique_assignments',
        'categories', 'produits', 'stock', 'stock_boutiques',
        'fournisseurs', 'comptes_fournisseurs', 'clients', 'comptes_clients',
        'cash_registers', 'cash_sessions', 'cash_movements',
        'movement_categories', 'financial_movements',
        'commandes_approvisionnement', 'details_commandes_approvisionnement',
        'ventes', 'details_ventes', 'mouvements_stock', 'transferts_stock',
        'transactions_comptes', 'parametres_entreprise', 'dates_peremption',
        'stock_inventories', 'inventory_items', 'historique_recus',
      ];

      let total = 0;
      const pgClient = await this.cloudPool.connect();

      try {
        for (const table of tables) {
          try {
            const rows = await this.localPrisma.$queryRawUnsafe(
              `SELECT * FROM "${table}" LIMIT 5000`
            );
            if (rows.length === 0) continue;

            for (const row of rows) {
              try {
                await this._applyToCloud(pgClient, table, 'INSERT', row);
                total++;
              } catch (e) {
                // Skip les conflits
              }
            }
            console.log(`  ✓ ${table}: ${rows.length} enregistrements`);
          } catch (e) {
            // Table inexistante localement, on skip
          }
        }
      } finally {
        pgClient.release();
      }

      console.log(`✅ Sync initiale terminée — ${total} enregistrements envoyés vers Neon`);
    } catch (e) {
      console.warn('⚠️  Erreur sync initiale:', e.message);
    }
  }

  /**
   * Cycle de synchronisation principal
   */
  async _syncCycle() {
    if (this.isSyncing) return;
    this.isSyncing = true;

    try {
      const available = await this._checkCloudConnection();
      if (!available) return;

      await this._pushLocalToCloud();
      await this._pullCloudToLocal();
      await this._cleanQueue();
    } catch (e) {
      console.error('❌ Erreur sync:', e.message);
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * Nettoie les entrées sync_queue déjà synchronisées (> 7 jours)
   */
  async _cleanQueue() {
    try {
      const result = await this.localPrisma.$executeRawUnsafe(
        `DELETE FROM sync_queue
         WHERE synced = 1
         AND created_at < datetime('now', '-7 days')`
      );
      if (result > 0) console.log(`🧹 sync_queue: ${result} entrée(s) nettoyée(s)`);
    } catch (e) {
      // Non bloquant
    }
  }

  /**
   * Envoie les opérations locales en attente vers Neon
   * Respecte l'ordre des dépendances FK
   */
  async _pushLocalToCloud() {
    const pending = await this.localPrisma.$queryRawUnsafe(
      `SELECT * FROM sync_queue WHERE synced = 0 ORDER BY
       CASE table_name
         WHEN 'user_roles' THEN 1
         WHEN 'utilisateurs' THEN 2
         WHEN 'boutiques' THEN 3
         WHEN 'categories' THEN 4
         WHEN 'produits' THEN 5
         WHEN 'cash_registers' THEN 6
         WHEN 'cash_sessions' THEN 7
         WHEN 'clients' THEN 8
         WHEN 'fournisseurs' THEN 9
         WHEN 'movement_categories' THEN 10
         WHEN 'cash_movements' THEN 11
         WHEN 'financial_movements' THEN 12
         WHEN 'ventes' THEN 13
         ELSE 20
       END, id ASC LIMIT 100`
    );

    if (pending.length === 0) return;
    console.log(`📤 Push ${pending.length} opération(s) vers Neon...`);

    const client = await this.cloudPool.connect();
    try {
      for (const item of pending) {
        try {
          const data = JSON.parse(item.data);
          
          // IMPORTANT: Si c'est une vente, vérifier que la session existe en Neon
          if (item.table_name === 'ventes') {
            // sessionId peut être en camelCase ou snake_case
            const sessionId = data.sessionId || data.session_id;
            if (sessionId) {
              try {
                const sessionExists = await client.query(
                  'SELECT id FROM cash_sessions WHERE id = $1',
                  [sessionId]
                );
                if (sessionExists.rows.length === 0) {
                  // Session n'existe pas en Neon, la chercher en local et la syncer d'abord
                  const localSession = await this.localPrisma.$queryRawUnsafe(
                    'SELECT * FROM cash_sessions WHERE id = ?',
                    sessionId
                  );
                  if (localSession && localSession.length > 0) {
                    console.log(`  ⚠️  Session ${sessionId} manquante en Neon, sync d'abord...`);
                    await this._applyToCloud(client, 'cash_sessions', 'INSERT', localSession[0]);
                  }
                }
              } catch (e) {
                // Erreur lors de la vérification, continuer
              }
            }
          }
          
          // IMPORTANT: Si c'est un mouvement financier, vérifier que la catégorie existe en Neon
          if (item.table_name === 'financial_movements') {
            const categorieId = data.categorieId || data.categorie_id;
            if (categorieId) {
              try {
                const categoryExists = await client.query(
                  'SELECT id FROM movement_categories WHERE id = $1',
                  [categorieId]
                );
                if (categoryExists.rows.length === 0) {
                  // Catégorie n'existe pas en Neon, la chercher en local et la syncer d'abord
                  const localCategory = await this.localPrisma.$queryRawUnsafe(
                    'SELECT * FROM movement_categories WHERE id = ?',
                    categorieId
                  );
                  if (localCategory && localCategory.length > 0) {
                    console.log(`  ⚠️  Catégorie ${categorieId} manquante en Neon, sync d'abord...`);
                    await this._applyToCloud(client, 'movement_categories', 'INSERT', localCategory[0]);
                  }
                }
              } catch (e) {
                // Erreur lors de la vérification, continuer
              }
            }
          }
          
          await this._applyToCloud(client, item.table_name, item.operation, data);
          await this.localPrisma.$executeRawUnsafe(
            'UPDATE sync_queue SET synced = 1 WHERE id = ?', item.id
          );
        } catch (e) {
          await this.localPrisma.$executeRawUnsafe(
            'UPDATE sync_queue SET error = ? WHERE id = ?', e.message, item.id
          );
          console.warn(`⚠️  Erreur push item ${item.id}:`, e.message);
        }
      }
    } finally {
      client.release();
    }
  }

  /**
   * Convertit les clés camelCase en snake_case pour PostgreSQL
   * et filtre les objets imbriqués (relations Prisma) et champs calculés
   */
  _toSnakeCase(obj) {
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      // Ignorer tableaux et objets imbriqués (relations Prisma)
      if (Array.isArray(value)) continue;
      if (value !== null && typeof value === 'object' && !(value instanceof Date)) continue;

      // Convertir camelCase → snake_case
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      result[snakeKey] = value instanceof Date ? value.toISOString() : value;
    }
    return result;
  }

  /**
   * Applique une opération sur Neon via pg client
   */
  async _applyToCloud(client, tableName, operation, data) {
    // Convertir camelCase → snake_case
    const row = this._toSnakeCase(data);

    if (operation === 'DELETE') {
      await client.query(`DELETE FROM "${tableName}" WHERE id = $1`, [row.id]);
      return;
    }

    // Filtre les clés pour éviter les colonnes inexistantes
    const keys = Object.keys(row).filter(k => {
      if (row[k] === undefined || row[k] === null) return false;
      if (k.startsWith('_')) return false;
      return true;
    });
    const values = keys.map(k => row[k]);

    if (operation === 'INSERT') {
      const cols = keys.map(k => `"${k}"`).join(', ');
      const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
      const updates = keys.filter(k => k !== 'id').map(k => `"${k}" = EXCLUDED."${k}"`).join(', ');
      await client.query(
        `INSERT INTO "${tableName}" (${cols}) VALUES (${placeholders}) ON CONFLICT (id) DO UPDATE SET ${updates}`,
        values
      );
    } else if (operation === 'UPDATE') {
      const nonIdKeys = keys.filter(k => k !== 'id');
      if (nonIdKeys.length === 0) return;
      const sets = nonIdKeys.map((k, i) => `"${k}" = $${i + 1}`).join(', ');
      const vals = nonIdKeys.map(k => row[k]);
      vals.push(row.id);
      await client.query(
        `UPDATE "${tableName}" SET ${sets} WHERE id = $${vals.length}`,
        vals
      );
    }
  }

  /**
   * Récupère les nouvelles données de Neon vers local
   */
  async _pullCloudToLocal() {
    const metaResult = await this.localPrisma.$queryRawUnsafe(
      "SELECT value FROM sync_meta WHERE key = 'last_pull' LIMIT 1"
    );
    const lastSync = metaResult[0]?.value || '1970-01-01T00:00:00.000Z';
    const now = new Date().toISOString();

    const client = await this.cloudPool.connect();
    let pulled = 0;

    try {
      for (const table of PULL_TABLES) {
        try {
          const result = await client.query(
            `SELECT * FROM "${table}" WHERE date_modification > $1 LIMIT 500`,
            [lastSync]
          );

          for (const row of result.rows) {
            const keys = Object.keys(row);
            const vals = Object.values(row).map(v =>
              v instanceof Date ? v.toISOString() : v
            );
            const cols = keys.map(k => `"${k}"`).join(', ');
            const placeholders = keys.map(() => `?`).join(', ');
            const updates = keys.filter(k => k !== 'id').map(k => `"${k}" = excluded."${k}"`).join(', ');

            try {
              await this.localPrisma.$executeRawUnsafe(
                `INSERT INTO "${table}" (${cols}) VALUES (${placeholders}) ON CONFLICT(id) DO UPDATE SET ${updates}`,
                ...vals
              );
              pulled++;
            } catch (e) {
              // Conflit ou contrainte FK, on skip
            }
          }
        } catch (e) {
          // Table sans date_modification ou inexistante, on skip
        }
      }
    } finally {
      client.release();
    }

    if (pulled > 0) console.log(`📥 Pull ${pulled} enregistrement(s) depuis Neon`);

    await this.localPrisma.$executeRawUnsafe(
      `INSERT INTO sync_meta (key, value) VALUES ('last_pull', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
      now
    );
  }

  /**
   * Ajoute une opération à la queue de sync
   * Appelé après chaque écriture dans les routes
   */
  async enqueue(tableName, operation, data) {
    if (!this.cloudUrl) return;

    try {
      await this.localPrisma.$executeRawUnsafe(
        'INSERT INTO sync_queue (table_name, operation, record_id, data) VALUES (?, ?, ?, ?)',
        tableName, operation, String(data.id || ''), JSON.stringify(data)
      );

      // Sync immédiate si Neon est dispo
      if (this.isCloudAvailable && !this.isSyncing) {
        setImmediate(() => this._syncCycle());
      }
    } catch (e) {
      console.warn('⚠️  Erreur enqueue:', e.message);
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

module.exports = new SyncService();
