const path = require('path');
const fs = require('fs');

/**
 * Détection automatique de l'environnement (local/cloud)
 * et configuration adaptative de la base de données
 */
class EnvironmentConfig {
  constructor() {
    this.nodeEnv = process.env.NODE_ENV || 'development';
    this.port = process.env.PORT || 8080;
    this.apiVersion = process.env.API_VERSION || 'v1';
    
    // Détection automatique du type de déploiement
    this.isLocal = this.detectLocalEnvironment();
    this.isCloud = !this.isLocal;
    
    // Configuration de la base de données adaptative
    this.databaseConfig = this.getDatabaseConfig();
    
    // Configuration JWT
    this.jwtConfig = {
      secret: process.env.JWT_SECRET || 'dev-secret-key',
      expiresIn: process.env.JWT_EXPIRES_IN || '24h',
      refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
    };
    
    // Configuration CORS
    this.corsOrigin = process.env.CORS_ORIGIN || '*';
    
    // Configuration logging
    this.logLevel = process.env.LOG_LEVEL || 'info';
  }

  /**
   * Détecte si l'application s'exécute en environnement local
   * @returns {boolean}
   */
  detectLocalEnvironment() {
    // Vérifications pour détecter un environnement local
    const localIndicators = [
      // Présence d'un dossier database local
      fs.existsSync(path.join(__dirname, '../../database')),
      // Variable d'environnement explicite
      process.env.DEPLOYMENT_TYPE === 'local',
      // URL de base de données SQLite
      process.env.DATABASE_URL && process.env.DATABASE_URL.startsWith('file:'),
      // Absence de variables cloud typiques
      !process.env.HEROKU_APP_NAME && !process.env.VERCEL_URL && !process.env.AWS_REGION
    ];

    // Si au moins un indicateur local est présent
    return localIndicators.some(indicator => indicator === true);
  }

  /**
   * Configuration adaptative de la base de données
   * @returns {Object}
   */
  getDatabaseConfig() {
    if (this.isLocal) {
      // Configuration SQLite pour déploiement local
      const isPkg = typeof process.pkg !== 'undefined';
      let dbPath;
      
      if (isPkg) {
        // En mode pkg, utiliser le dossier de l'exécutable
        const basePath = path.dirname(process.execPath);
        dbPath = path.join(basePath, 'database', 'logesco.db');
      } else {
        // En mode développement normal
        dbPath = path.join(__dirname, '../../database/logesco.db');
      }
      
      const dbDir = path.dirname(dbPath);
      
      // Créer le dossier database seulement si on n'est pas dans un snapshot
      if (!isPkg && !fs.existsSync(dbDir)) {
        try {
          fs.mkdirSync(dbDir, { recursive: true });
        } catch (error) {
          console.warn('⚠️ Impossible de créer le dossier database:', error.message);
        }
      }

      return {
        provider: 'sqlite',
        url: process.env.DATABASE_URL || `file:${dbPath}`,
        type: 'local',
        backup: {
          enabled: true,
          path: path.join(dbDir, 'backups'),
          frequency: 'daily'
        }
      };
    } else {
      // Configuration PostgreSQL pour déploiement cloud
      return {
        provider: 'postgresql',
        url: process.env.DATABASE_URL,
        type: 'cloud',
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
        backup: {
          enabled: true,
          retention: '30d'
        }
      };
    }
  }

  /**
   * Génère la configuration Prisma dynamiquement
   * @returns {Object}
   */
  getPrismaConfig() {
    return {
      datasources: {
        db: {
          provider: this.databaseConfig.provider,
          url: this.databaseConfig.url
        }
      }
    };
  }

  /**
   * Configuration des middlewares selon l'environnement
   * @returns {Object}
   */
  getMiddlewareConfig() {
    // Désactiver le rate limiting si en mode test
    const isTestMode = process.env.NODE_ENV === 'test' || process.env.TEST_MODE === 'true';
    
    return {
      cors: {
        origin: this.corsOrigin,
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization']
      },
      rateLimit: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: isTestMode ? 999999 : (this.isLocal ? 1000 : 100), // Illimité en mode test
        message: 'Trop de requêtes, veuillez réessayer plus tard.',
        skip: isTestMode ? () => true : () => false // Skip complètement en mode test
      },
      helmet: {
        contentSecurityPolicy: this.nodeEnv === 'production',
        crossOriginEmbedderPolicy: false
      },
      morgan: {
        format: this.nodeEnv === 'production' ? 'combined' : 'dev'
      }
    };
  }

  /**
   * Affiche la configuration détectée
   */
  logConfiguration() {
    console.log('🔧 Configuration LOGESCO API');
    console.log('============================');
    console.log(`Environment: ${this.nodeEnv}`);
    console.log(`Deployment Type: ${this.isLocal ? 'Local' : 'Cloud'}`);
    console.log(`Database: ${this.databaseConfig.provider}`);
    console.log(`Port: ${this.port}`);
    console.log(`API Version: ${this.apiVersion}`);
    console.log('============================');
  }
}

module.exports = new EnvironmentConfig();