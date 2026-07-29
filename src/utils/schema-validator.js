/**
 * Validateur de schéma de base de données
 * Vérifie et corrige automatiquement les colonnes manquantes au démarrage
 */

const logger = require('./logger');

class SchemaValidator {
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Liste de TOUTES les colonnes requises par table.
   * On ne liste QUE les colonnes à surveiller (pas besoin de toutes).
   */
  getRequiredSchema() {
    return {
      stock: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      stock_boutiques: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      comptes_clients: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      comptes_fournisseurs: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      produits: [
        { name: 'image_url', type: 'TEXT', nullable: true }
      ],
      clients: [
        { name: 'date_modification', type: 'DATETIME', nullable: true },
        { name: 'nui', type: 'TEXT', nullable: true },
        { name: 'rccm', type: 'TEXT', nullable: true }
      ],
      fournisseurs: [
        { name: 'date_modification', type: 'DATETIME', nullable: true },
        { name: 'nui', type: 'TEXT', nullable: true },
        { name: 'rccm', type: 'TEXT', nullable: true }
      ],
      commandes_approvisionnement: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      details_commandes_approvisionnement: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      details_ventes: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      details_ventes_proforma: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      mouvements_stock: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      transferts_stock: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      inventory_items: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      stock_inventories: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      transactions_comptes: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      cash_movements: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      historique_prix_achat: [
        { name: 'date_modification', type: 'DATETIME', nullable: true }
      ],
      operation_log: [
        { name: 'operation_id', type: 'TEXT', nullable: true },
        { name: 'operation_type', type: 'TEXT', nullable: true },
        { name: 'table_name', type: 'TEXT', nullable: true },
        { name: 'record_id', type: 'INTEGER', nullable: true },
        { name: 'data', type: 'TEXT', nullable: true },
        { name: 'timestamp', type: 'DATETIME', nullable: true },
        { name: 'synced_at', type: 'DATETIME', nullable: true },
        { name: 'status', type: 'TEXT', nullable: true },
        { name: 'error_message', type: 'TEXT', nullable: true },
        { name: 'device_id', type: 'TEXT', nullable: true },
        { name: 'user_id', type: 'INTEGER', nullable: true }
      ]
    };
  }

  /**
   * Récupère les colonnes actuelles d'une table
   */
  async getTableColumns(tableName) {
    try {
      const columns = await this.prisma.$queryRaw`
        SELECT name, type FROM pragma_table_info(${tableName})
      `;
      return columns || [];
    } catch (error) {
      return [];
    }
  }

  /**
   * Vérifie si une table existe
   */
  async tableExists(tableName) {
    try {
      const result = await this.prisma.$queryRaw`
        SELECT name FROM sqlite_master WHERE type='table' AND name=${tableName}
      `;
      return result && result.length > 0;
    } catch (error) {
      return false;
    }
  }

  /**
   * Ajoute une colonne manquante à une table
   */
  async addMissingColumn(tableName, columnDef) {
    try {
      // Toujours nullable pour ALTER TABLE (SQLite ne supporte pas NOT NULL sans DEFAULT)
      await this.prisma.$executeRawUnsafe(
        `ALTER TABLE "${tableName}" ADD COLUMN "${columnDef.name}" ${columnDef.type}`
      );
      logger.info(`✅ Colonne ${columnDef.name} ajoutée à ${tableName}`);
      return true;
    } catch (error) {
      // Ignorer l'erreur "duplicate column" (déjà présente)
      if (error.message && error.message.includes('duplicate column')) {
        return true;
      }
      logger.error(`❌ Échec ajout ${tableName}.${columnDef.name}: ${error.message}`);
      return false;
    }
  }

  /**
   * Crée la table operation_log si elle n'existe pas
   */
  async ensureOperationLog() {
    const exists = await this.tableExists('operation_log');
    if (!exists) {
      try {
        await this.prisma.$executeRaw`
          CREATE TABLE IF NOT EXISTS operation_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_id TEXT UNIQUE,
            operation_type TEXT,
            table_name TEXT,
            record_id INTEGER,
            data TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            synced_at DATETIME,
            status TEXT DEFAULT 'pending',
            error_message TEXT,
            device_id TEXT,
            user_id INTEGER
          )
        `;
        await this.prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_op_log_status ON operation_log(status, timestamp)`;
        await this.prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_op_log_table ON operation_log(table_name, timestamp)`;
        logger.info('✅ Table operation_log créée');
      } catch (error) {
        logger.error('❌ Création operation_log échouée:', error.message);
      }
    }
  }

  /**
   * Valide et corrige le schéma de toutes les tables
   */
  async validateAndFix() {
    const requiredSchema = this.getRequiredSchema();
    let issuesFound = 0;
    let issuesFixed = 0;

    logger.info('🔍 Vérification du schéma de base de données...');

    // S'assurer que operation_log existe
    await this.ensureOperationLog();

    for (const [tableName, requiredColumns] of Object.entries(requiredSchema)) {
      const exists = await this.tableExists(tableName);
      if (!exists) continue;

      const currentColumns = await this.getTableColumns(tableName);
      const currentColumnNames = currentColumns.map(col => col.name);

      for (const requiredCol of requiredColumns) {
        if (!currentColumnNames.includes(requiredCol.name)) {
          issuesFound++;
          logger.warn(`⚠️  Colonne manquante: ${tableName}.${requiredCol.name}`);
          const success = await this.addMissingColumn(tableName, requiredCol);
          if (success) issuesFixed++;
        }
      }
    }

    if (issuesFound === 0) {
      logger.info('✅ Schéma de base de données OK');
    } else {
      logger.info(`📊 Schéma: ${issuesFixed}/${issuesFound} corrections appliquées`);
    }

    return { issuesFound, issuesFixed, success: issuesFixed === issuesFound };
  }

  /**
   * Validation rapide : vérifie uniquement les colonnes les plus critiques
   */
  async quickValidate() {
    const checks = {
      commandes_approvisionnement: 'date_modification',
      stock: 'date_modification',
      comptes_clients: 'date_modification',
      produits: 'image_url'
    };

    for (const [table, column] of Object.entries(checks)) {
      const exists = await this.tableExists(table);
      if (!exists) continue;
      const columns = await this.getTableColumns(table);
      if (!columns.map(c => c.name).includes(column)) {
        return false;
      }
    }

    // Vérifier que operation_log existe
    const opLogExists = await this.tableExists('operation_log');
    if (!opLogExists) return false;

    return true;
  }
}

module.exports = SchemaValidator;
