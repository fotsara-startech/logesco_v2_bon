/**
 * Configuration de l'environnement de test avec données réelles
 * LOGESCO v2
 */

const fs = require('fs').promises;
const path = require('path');

class TestEnvironmentSetup {
  constructor() {
    this.envFile = path.join(__dirname, '..', '.env');
    this.testEnvFile = path.join(__dirname, '..', '.env.test');
  }

  /**
   * Configure l'environnement de test
   */
  async setup() {
    console.log('🔧 Configuration de l\'environnement de test...\n');

    try {
      // 1. Créer le fichier .env de test
      await this.createTestEnvFile();

      // 2. Vérifier la configuration de la base de données
      await this.checkDatabaseConfig();

      // 3. Créer les dossiers nécessaires
      await this.createRequiredDirectories();

      // 4. Afficher les instructions
      this.displayInstructions();

      console.log('✅ Environnement de test configuré avec succès!\n');

    } catch (error) {
      console.error('❌ Erreur lors de la configuration:', error.message);
      process.exit(1);
    }
  }

  /**
   * Crée le fichier .env de test
   */
  async createTestEnvFile() {
    const testEnvContent = `# Configuration de test LOGESCO v2
# Généré automatiquement le ${new Date().toISOString()}

# Environment
NODE_ENV=test
PORT=8080

# Base de données de test (SQLite)
DATABASE_URL="file:./database/logesco-test.db"

# JWT Configuration pour tests
JWT_SECRET=test-secret-key-for-logesco-v2-comprehensive-testing-2024
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# API Configuration
API_VERSION=v1
CORS_ORIGIN=*

# Logging pour tests
LOG_LEVEL=error

# Configuration spécifique aux tests
TEST_MODE=true
RESET_DB_ON_START=true
ENABLE_TEST_ROUTES=true

# Désactiver complètement le rate limiting pour les tests
DISABLE_RATE_LIMITING=true
`;

    await fs.writeFile(this.testEnvFile, testEnvContent);
    console.log('📝 Fichier .env.test créé');

    // Copier vers .env si il n'existe pas
    try {
      await fs.access(this.envFile);
      console.log('📄 Fichier .env existant conservé');
    } catch {
      await fs.writeFile(this.envFile, testEnvContent);
      console.log('📝 Fichier .env créé pour les tests');
    }
  }

  /**
   * Vérifie la configuration de la base de données
   */
  async checkDatabaseConfig() {
    const dbDir = path.join(__dirname, '..', 'database');
    
    try {
      await fs.access(dbDir);
      console.log('📁 Dossier database existant');
    } catch {
      await fs.mkdir(dbDir, { recursive: true });
      console.log('📁 Dossier database créé');
    }

    // Créer un fichier de configuration de test pour Prisma
    const prismaTestConfig = `// Configuration Prisma pour tests
// Ce fichier peut être utilisé pour des configurations spécifiques aux tests

generator client {
  provider = "prisma-client-js"
  output   = "../node_modules/.prisma/client"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

// Les modèles sont définis dans schema.prisma principal
`;

    const prismaTestFile = path.join(__dirname, '..', 'prisma', 'test.prisma');
    await fs.writeFile(prismaTestFile, prismaTestConfig);
    console.log('📝 Configuration Prisma de test créée');
  }

  /**
   * Crée les dossiers nécessaires
   */
  async createRequiredDirectories() {
    const directories = [
      path.join(__dirname, '..', 'logs'),
      path.join(__dirname, '..', 'uploads'),
      path.join(__dirname, '..', 'temp'),
      path.join(__dirname, 'test-results')
    ];

    for (const dir of directories) {
      try {
        await fs.access(dir);
      } catch {
        await fs.mkdir(dir, { recursive: true });
        console.log(`📁 Dossier créé: ${path.basename(dir)}`);
      }
    }
  }

  /**
   * Affiche les instructions pour lancer les tests
   */
  displayInstructions() {
    console.log('\n' + '='.repeat(60));
    console.log('📋 INSTRUCTIONS POUR LANCER LES TESTS');
    console.log('='.repeat(60));
    console.log('');
    console.log('1. 🚀 Démarrer le serveur backend:');
    console.log('   cd backend');
    console.log('   npm run dev');
    console.log('');
    console.log('2. 🧪 Dans un autre terminal, lancer les tests:');
    console.log('   cd backend');
    console.log('   node scripts/comprehensive-real-data-test.js');
    console.log('');
    console.log('3. 📱 Pour tester l\'application Flutter:');
    console.log('   cd logesco_v2');
    console.log('   flutter run');
    console.log('');
    console.log('4. 🔍 Vérifier les résultats:');
    console.log('   - Rapport détaillé: backend/scripts/test-results/test-results.json');
    console.log('   - Logs du serveur dans la console');
    console.log('   - Interface Flutter pour tests manuels');
    console.log('');
    console.log('💡 CONSEILS:');
    console.log('   - Assurez-vous que le port 8080 est libre');
    console.log('   - Les tests créent des données réelles dans la DB');
    console.log('   - Utilisez npm run db:reset pour nettoyer entre les tests');
    console.log('   - Vérifiez les logs pour diagnostiquer les problèmes');
    console.log('');
    console.log('='.repeat(60));
  }

  /**
   * Nettoie l'environnement de test
   */
  async cleanup() {
    console.log('🧹 Nettoyage de l\'environnement de test...');

    try {
      // Supprimer la base de données de test
      const testDbPath = path.join(__dirname, '..', 'database', 'logesco-test.db');
      try {
        await fs.unlink(testDbPath);
        console.log('🗑️  Base de données de test supprimée');
      } catch {
        // Fichier n'existe pas, pas de problème
      }

      // Nettoyer les fichiers temporaires
      const tempDir = path.join(__dirname, '..', 'temp');
      try {
        const files = await fs.readdir(tempDir);
        for (const file of files) {
          await fs.unlink(path.join(tempDir, file));
        }
        console.log('🗑️  Fichiers temporaires nettoyés');
      } catch {
        // Dossier n'existe pas ou vide
      }

      console.log('✅ Nettoyage terminé');

    } catch (error) {
      console.error('❌ Erreur lors du nettoyage:', error.message);
    }
  }
}

// Gestion des arguments de ligne de commande
const args = process.argv.slice(2);
const command = args[0];

const setup = new TestEnvironmentSetup();

switch (command) {
  case 'cleanup':
    setup.cleanup();
    break;
  case 'setup':
  default:
    setup.setup();
    break;
}

module.exports = TestEnvironmentSetup;