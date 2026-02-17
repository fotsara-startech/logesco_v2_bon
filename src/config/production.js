/**
 * Configuration spécifique pour le mode production (exécutable standalone)
 */

const path = require('path');
const fs = require('fs');

/**
 * Détecte si l'application tourne en mode standalone (pkg)
 */
function isStandalone() {
  return typeof process.pkg !== 'undefined';
}

/**
 * Obtient le chemin de base de l'application
 */
function getBasePath() {
  if (isStandalone()) {
    // En mode standalone, utiliser le dossier de l'exécutable
    return path.dirname(process.execPath);
  }
  // En mode développement, utiliser le dossier du projet
  return path.join(__dirname, '../..');
}

/**
 * Configuration pour le mode production
 */
const productionConfig = {
  // Chemins
  basePath: getBasePath(),
  databasePath: path.join(getBasePath(), 'database'),
  logsPath: path.join(getBasePath(), 'logs'),
  uploadsPath: path.join(getBasePath(), 'uploads'),
  
  // Base de données
  getDatabaseUrl() {
    const dbPath = path.join(this.databasePath, 'logesco.db');
    return `file:${dbPath}`;
  },
  
  // Initialisation
  async initialize() {
    console.log('🔧 Initialisation de la configuration production...');
    console.log(`📁 Chemin de base: ${this.basePath}`);
    
    // Créer les dossiers nécessaires
    const folders = [
      this.databasePath,
      this.logsPath,
      this.uploadsPath
    ];
    
    for (const folder of folders) {
      if (!fs.existsSync(folder)) {
        fs.mkdirSync(folder, { recursive: true });
        console.log(`✓ Dossier créé: ${folder}`);
      }
    }
    
    // Vérifier/créer le fichier .env
    await this.ensureEnvFile();
    
    console.log('✅ Configuration production initialisée');
  },
  
  // Créer le fichier .env s'il n'existe pas
  async ensureEnvFile() {
    const envPath = path.join(this.basePath, '.env');
    const envExamplePath = path.join(this.basePath, '.env.example');
    
    if (!fs.existsSync(envPath)) {
      console.log('📝 Création du fichier .env...');
      
      // Copier depuis .env.example si disponible
      if (fs.existsSync(envExamplePath)) {
        fs.copyFileSync(envExamplePath, envPath);
        console.log('✓ Fichier .env créé depuis .env.example');
      } else {
        // Créer un .env par défaut
        const defaultEnv = this.getDefaultEnvContent();
        fs.writeFileSync(envPath, defaultEnv);
        console.log('✓ Fichier .env créé avec valeurs par défaut');
      }
    }
  },
  
  // Contenu par défaut du fichier .env
  getDefaultEnvContent() {
    const crypto = require('crypto');
    const secret = crypto.randomBytes(32).toString('hex');
    
    return `# Configuration LOGESCO Backend - Production
NODE_ENV=production
PORT=8080

# Base de données SQLite locale
DATABASE_URL=file:${path.join(this.databasePath, 'logesco.db')}

# JWT Configuration
JWT_SECRET=${secret}
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# API Configuration
API_VERSION=v1
CORS_ORIGIN=*

# Logging
LOG_LEVEL=info
`;
  },
  
  // Vérifier la santé de la configuration
  healthCheck() {
    const checks = {
      basePath: fs.existsSync(this.basePath),
      databasePath: fs.existsSync(this.databasePath),
      logsPath: fs.existsSync(this.logsPath),
      uploadsPath: fs.existsSync(this.uploadsPath),
      envFile: fs.existsSync(path.join(this.basePath, '.env'))
    };
    
    const allHealthy = Object.values(checks).every(check => check === true);
    
    return {
      healthy: allHealthy,
      checks,
      mode: isStandalone() ? 'standalone' : 'development'
    };
  }
};

module.exports = {
  isStandalone,
  getBasePath,
  productionConfig
};
