/**
 * Utilitaires d'optimisation de base de données pour LOGESCO
 * Index, requêtes optimisées et monitoring des performances
 */

const logger = require('./logger');

/**
 * Gestionnaire d'optimisation de base de données
 */
class DatabaseOptimizer {
  constructor(prisma) {
    this.prisma = prisma;
    this.queryStats = new Map();
  }

  /**
   * Crée les index recommandés pour optimiser les performances
   */
  async createOptimizedIndexes() {
    try {
      logger.info('Creating optimized database indexes...');

      // Index pour les produits (recherche et tri fréquents)
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_produits_reference ON produits(reference);
      `;
      
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_produits_nom_search ON produits USING gin(to_tsvector('french', nom));
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_produits_categorie ON produits(categorieId);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_produits_prix ON produits(prixVente);
      `;

      // Index pour les ventes (rapports et statistiques)
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_ventes_date ON ventes(dateVente);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_ventes_client ON ventes(clientId);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_ventes_statut ON ventes(statut);
      `;

      // Index pour les mouvements de stock
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_mouvements_stock_produit_date ON mouvements_stock(produitId, dateCreation);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_mouvements_stock_type ON mouvements_stock(type);
      `;

      // Index pour les utilisateurs
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_utilisateurs_email ON utilisateurs(email);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_utilisateurs_actif ON utilisateurs(actif);
      `;

      // Index pour les clients/fournisseurs
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_clients_nom_search ON clients USING gin(to_tsvector('french', nom));
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_fournisseurs_nom_search ON fournisseurs USING gin(to_tsvector('french', nom));
      `;

      // Index composites pour les requêtes complexes
      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_ventes_date_statut ON ventes(dateVente, statut);
      `;

      await this.prisma.$executeRaw`
        CREATE INDEX IF NOT EXISTS idx_produits_categorie_actif ON produits(categorieId, actif);
      `;

      logger.info('Database indexes created successfully');
    } catch (error) {
      logger.error('Error creating database indexes', error);
      throw error;
    }
  }

  /**
   * Analyse les performances des requêtes
   * @param {string} query - Requête SQL
   * @param {Array} params - Paramètres de la requête
   * @returns {Object} Plan d'exécution
   */
  async analyzeQuery(query, params = []) {
    try {
      const explainQuery = `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ${query}`;
      const result = await this.prisma.$queryRawUnsafe(explainQuery, ...params);
      
      const plan = result[0]['QUERY PLAN'][0];
      
      logger.performance('Query analysis', plan['Execution Time'], {
        query: query.substring(0, 100),
        executionTime: plan['Execution Time'],
        planningTime: plan['Planning Time'],
        totalCost: plan.Plan['Total Cost']
      });

      return plan;
    } catch (error) {
      logger.error('Error analyzing query', error, { query });
      return null;
    }
  }

  /**
   * Monitore les performances d'une requête
   * @param {string} queryName - Nom de la requête
   * @param {Function} queryFunction - Fonction exécutant la requête
   * @returns {*} Résultat de la requête
   */
  async monitorQuery(queryName, queryFunction) {
    const startTime = Date.now();
    
    try {
      const result = await queryFunction();
      const duration = Date.now() - startTime;
      
      // Enregistrer les statistiques
      if (!this.queryStats.has(queryName)) {
        this.queryStats.set(queryName, {
          count: 0,
          totalTime: 0,
          avgTime: 0,
          minTime: Infinity,
          maxTime: 0,
          errors: 0
        });
      }

      const stats = this.queryStats.get(queryName);
      stats.count++;
      stats.totalTime += duration;
      stats.avgTime = stats.totalTime / stats.count;
      stats.minTime = Math.min(stats.minTime, duration);
      stats.maxTime = Math.max(stats.maxTime, duration);

      // Log des requêtes lentes
      if (duration > 1000) {
        logger.performance('Slow query detected', duration, {
          queryName,
          duration,
          avgTime: stats.avgTime
        });
      }

      return result;
    } catch (error) {
      const stats = this.queryStats.get(queryName);
      if (stats) {
        stats.errors++;
      }
      
      logger.error('Query execution error', error, { queryName });
      throw error;
    }
  }

  /**
   * Optimise une requête Prisma pour de meilleures performances
   * @param {Object} queryOptions - Options de la requête
   * @returns {Object} Options optimisées
   */
  optimizePrismaQuery(queryOptions) {
    const optimized = { ...queryOptions };

    // Limiter les champs sélectionnés
    if (!optimized.select && !optimized.include) {
      // Suggérer une sélection explicite pour les grandes tables
      logger.debug('Consider using explicit field selection for better performance');
    }

    // Optimiser les relations
    if (optimized.include) {
      Object.keys(optimized.include).forEach(relation => {
        if (typeof optimized.include[relation] === 'boolean') {
          logger.debug(`Consider limiting fields for relation: ${relation}`);
        }
      });
    }

    // Ajouter des hints pour l'optimiseur
    if (optimized.where) {
      // Réorganiser les conditions WHERE pour utiliser les index
      const { id, ...otherConditions } = optimized.where;
      if (id) {
        optimized.where = { id, ...otherConditions };
      }
    }

    return optimized;
  }

  /**
   * Nettoie les données obsolètes pour maintenir les performances
   */
  async cleanupObsoleteData() {
    try {
      logger.info('Starting database cleanup...');

      // Nettoyer les sessions expirées (si applicable)
      const expiredSessions = await this.prisma.$executeRaw`
        DELETE FROM sessions WHERE expires_at < NOW();
      `;

      // Nettoyer les logs anciens (si applicable)
      const oldLogs = await this.prisma.$executeRaw`
        DELETE FROM logs WHERE created_at < NOW() - INTERVAL '30 days';
      `;

      // Nettoyer les tokens expirés
      const expiredTokens = await this.prisma.$executeRaw`
        DELETE FROM refresh_tokens WHERE expires_at < NOW();
      `;

      logger.info('Database cleanup completed', {
        expiredSessions,
        oldLogs,
        expiredTokens
      });
    } catch (error) {
      logger.error('Error during database cleanup', error);
    }
  }

  /**
   * Obtient les statistiques de performance des requêtes
   * @returns {Object} Statistiques
   */
  getQueryStats() {
    const stats = {};
    
    for (const [queryName, data] of this.queryStats.entries()) {
      stats[queryName] = {
        ...data,
        minTime: data.minTime === Infinity ? 0 : data.minTime
      };
    }

    return stats;
  }

  /**
   * Réinitialise les statistiques de performance
   */
  resetQueryStats() {
    this.queryStats.clear();
    logger.info('Query statistics reset');
  }

  /**
   * Vérifie la santé de la base de données
   * @returns {Object} État de santé
   */
  async checkDatabaseHealth() {
    try {
      const startTime = Date.now();
      
      // Test de connectivité
      await this.prisma.$queryRaw`SELECT 1`;
      const connectionTime = Date.now() - startTime;

      // Statistiques de base
      const tableStats = await this.prisma.$queryRaw`
        SELECT 
          schemaname,
          tablename,
          n_tup_ins as inserts,
          n_tup_upd as updates,
          n_tup_del as deletes,
          n_live_tup as live_tuples,
          n_dead_tup as dead_tuples
        FROM pg_stat_user_tables
        ORDER BY n_live_tup DESC;
      `;

      // Taille de la base de données
      const dbSize = await this.prisma.$queryRaw`
        SELECT pg_size_pretty(pg_database_size(current_database())) as size;
      `;

      // Index non utilisés
      const unusedIndexes = await this.prisma.$queryRaw`
        SELECT 
          schemaname,
          tablename,
          indexname,
          idx_tup_read,
          idx_tup_fetch
        FROM pg_stat_user_indexes
        WHERE idx_tup_read = 0 AND idx_tup_fetch = 0
        ORDER BY schemaname, tablename;
      `;

      return {
        status: 'healthy',
        connectionTime,
        databaseSize: dbSize[0]?.size,
        tableStats,
        unusedIndexes,
        queryStats: this.getQueryStats(),
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Database health check failed', error);
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * Optimise automatiquement la base de données
   */
  async autoOptimize() {
    try {
      logger.info('Starting automatic database optimization...');

      // Analyser et reconstruire les statistiques
      await this.prisma.$executeRaw`ANALYZE;`;

      // Nettoyer les données obsolètes
      await this.cleanupObsoleteData();

      // Vacuum pour récupérer l'espace
      await this.prisma.$executeRaw`VACUUM;`;

      logger.info('Automatic database optimization completed');
    } catch (error) {
      logger.error('Error during automatic optimization', error);
    }
  }
}

module.exports = DatabaseOptimizer;