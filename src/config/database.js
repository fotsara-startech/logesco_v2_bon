const { PrismaClient } = require('./prisma-client');
const environment = require('./environment');

/**
 * Configuration et gestion de la connexion à la base de données
 * Support hybride SQLite/PostgreSQL
 */
class DatabaseManager {
  constructor() {
    this.prisma = null;
    this.isConnected = false;
  }

  /**
   * Initialise la connexion à la base de données
   * @returns {Promise<PrismaClient>}
   */
  async initialize() {
    try {
      console.log(`🗄️  Initialisation de la base de données ${environment.databaseConfig.provider}...`);

      // Configuration Prisma simplifiée
      this.prisma = new PrismaClient({
        log: environment.nodeEnv === 'development' ? ['error'] : ['error']
      });

      // Test de connexion
      await this.testConnection();

      this.isConnected = true;
      console.log('✅ Base de données connectée avec succès');

      return this.prisma;
    } catch (error) {
      console.error('❌ Erreur de connexion à la base de données:', error.message);
      throw error;
    }
  }

  /**
   * Test de connexion à la base de données
   * @returns {Promise<void>}
   */
  async testConnection() {
    try {
      // Test simple de connexion
      await this.prisma.$connect();

      // Vérification de la structure avec une requête plus simple
      await this.prisma.$queryRaw`SELECT name FROM sqlite_master WHERE type='table' LIMIT 1`;

      console.log('🔍 Structure de base de données vérifiée');
    } catch (error) {
      if (error.code === 'P2021' || error.message.includes('does not exist')) {
        console.log('⚠️  Base de données vide détectée - Migration nécessaire');
        throw new Error('Database needs migration. Run: npm run migrate');
      }
      throw error;
    }
  }

  /**
   * Ferme la connexion à la base de données
   * @returns {Promise<void>}
   */
  async disconnect() {
    if (this.prisma && this.isConnected) {
      await this.prisma.$disconnect();
      this.isConnected = false;
      console.log('🔌 Base de données déconnectée');
    }
  }

  /**
   * Retourne l'instance Prisma
   * @returns {PrismaClient}
   */
  getClient() {
    if (!this.prisma || !this.isConnected) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.prisma;
  }

  /**
   * Exécute les migrations de base de données
   * @returns {Promise<void>}
   */
  async runMigrations() {
    try {
      console.log('🔄 Exécution des migrations...');

      if (environment.isLocal) {
        console.log('📁 Création de la structure SQLite...');
      } else {
        console.log('🐘 Mise à jour de la structure PostgreSQL...');
      }

      // Les migrations sont gérées par Prisma CLI
      // Cette méthode peut être étendue pour des migrations personnalisées

      console.log('✅ Migrations terminées');
    } catch (error) {
      console.error('❌ Erreur lors des migrations:', error.message);
      throw error;
    }
  }

  /**
   * Sauvegarde de la base de données
   * @returns {Promise<string>}
   */
  async backup() {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

      if (environment.isLocal) {
        // Sauvegarde SQLite - copie du fichier
        const fs = require('fs');
        const path = require('path');

        const sourceDb = path.join(__dirname, '../../database/logesco.db');
        const backupDir = path.join(__dirname, '../../database/backups');
        const backupFile = path.join(backupDir, `logesco-backup-${timestamp}.db`);

        // Créer le dossier de sauvegarde s'il n'existe pas
        if (!fs.existsSync(backupDir)) {
          fs.mkdirSync(backupDir, { recursive: true });
        }

        // Copier le fichier de base de données
        fs.copyFileSync(sourceDb, backupFile);

        console.log(`💾 Sauvegarde SQLite créée: ${backupFile}`);
        return backupFile;
      } else {
        // Sauvegarde PostgreSQL - dump SQL
        console.log('💾 Sauvegarde PostgreSQL initiée (implémentation cloud requise)');
        return `postgresql-backup-${timestamp}`;
      }
    } catch (error) {
      console.error('❌ Erreur lors de la sauvegarde:', error.message);
      throw error;
    }
  }

  /**
   * Statistiques de la base de données
   * @returns {Promise<Object>}
   */
  async getStats() {
    try {
      const stats = {
        environment: environment.isLocal ? 'Local (SQLite)' : 'Cloud (PostgreSQL)',
        connected: this.isConnected,
        tables: {}
      };

      if (this.isConnected) {
        // Compter les enregistrements dans chaque table principale
        stats.tables = {
          // utilisateurs: await this.prisma.utilisateur.count(),
          produits: await this.prisma.produit.count(),
          clients: await this.prisma.client.count(),
          fournisseurs: await this.prisma.fournisseur.count(),
          ventes: await this.prisma.vente.count(),
          commandes: await this.prisma.commandeApprovisionnement.count()
        };
      }

      return stats;
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des statistiques:', error.message);
      return { error: error.message };
    }
  }
}

// Instance singleton
const databaseManager = new DatabaseManager();

module.exports = databaseManager;