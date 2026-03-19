/**
 * Point d'entrée pour le serveur en mode standalone
 * Gère l'initialisation automatique et la configuration production
 */

const path = require('path');
const fs = require('fs');

// Détecte si on est en mode pkg
const isPkg = typeof process.pkg !== 'undefined';
const os = require('os');

// Obtenir le chemin de base (en dehors du snapshot)
function getBasePath() {
  if (isPkg) {
    // En mode pkg, utiliser AppData pour éviter les problèmes de permissions
    // C:\Users\[Username]\AppData\Local\LOGESCO\backend
    const appDataPath = process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local');
    return path.join(appDataPath, 'LOGESCO', 'backend');
  }
  return path.join(__dirname, '..');
}

async function startStandaloneServer() {
  try {
    console.log('🚀 Démarrage de LOGESCO Backend (Mode Standalone)...');
    console.log('='.repeat(50));
    
    const basePath = getBasePath();
    console.log(`📁 Chemin de base: ${basePath}`);
    
    // Créer les dossiers nécessaires (en dehors du snapshot)
    const folders = {
      database: path.join(basePath, 'database'),
      logs: path.join(basePath, 'logs'),
      uploads: path.join(basePath, 'uploads')
    };
    
    console.log('\n🔧 Création des dossiers...');
    for (const [name, folderPath] of Object.entries(folders)) {
      if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
        console.log(`✓ Dossier créé: ${name}`);
      } else {
        console.log(`✓ Dossier existant: ${name}`);
      }
    }
    
    // Créer/vérifier le fichier .env
    const envPath = path.join(basePath, '.env');
    if (!fs.existsSync(envPath)) {
      console.log('\n📝 Création du fichier .env...');
      const crypto = require('crypto');
      const secret = crypto.randomBytes(32).toString('hex');
      const dbPath = path.join(folders.database, 'logesco.db');
      
      const envContent = `NODE_ENV=production
PORT=8080
DATABASE_URL=file:${dbPath}
JWT_SECRET=${secret}
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
DEPLOYMENT_TYPE=local
`;
      fs.writeFileSync(envPath, envContent);
      console.log('✓ Fichier .env créé');
    }
    
    // Charger les variables d'environnement
    console.log('\n📝 Chargement de la configuration...');
    const dotenv = require('dotenv');
    dotenv.config({ path: envPath });
    
    // Forcer les chemins corrects
    process.env.DATABASE_URL = `file:${path.join(folders.database, 'logesco.db')}`;
    process.env.DEPLOYMENT_TYPE = 'local';
    
    console.log(`✓ Base de données: ${process.env.DATABASE_URL}`);
    console.log(`✓ Port: ${process.env.PORT || 8080}`);
    
    console.log('✓ Mode standalone - utilisation de Prisma avec SQLite');
    
    // Initialiser Prisma et la base de données
    console.log('\n🗄️ Initialisation de Prisma...');
    const { PrismaClient } = require('./config/prisma-client');
    
    // Vérifier si la base de données existe, sinon la créer
    const dbPath = path.join(folders.database, 'logesco.db');
    if (!fs.existsSync(dbPath)) {
      console.log('📦 Création de la base de données SQLite...');
      // Créer un fichier vide pour SQLite
      fs.writeFileSync(dbPath, '');
    }
    
    // Générer le client Prisma si nécessaire avec version forcée
    try {
      console.log('🔧 Génération du client Prisma...');
      const { execSync } = require('child_process');
      const backendPath = path.join(__dirname, '..');
      
      // Essayer d'abord avec la version locale
      try {
        execSync('node_modules\\.bin\\prisma generate', { 
          cwd: backendPath,
          stdio: 'inherit' 
        });
        console.log('✓ Client Prisma généré (version locale)');
      } catch (localError) {
        // Fallback avec version spécifique
        try {
          execSync('npx --package=prisma@6.17.1 prisma generate', { 
            cwd: backendPath,
            stdio: 'inherit' 
          });
          console.log('✓ Client Prisma généré (version 6.17.1)');
        } catch (specificError) {
          // Dernier recours avec version globale
          execSync('npx prisma generate', { 
            cwd: backendPath,
            stdio: 'inherit' 
          });
          console.log('✓ Client Prisma généré (version globale)');
        }
      }
    } catch (error) {
      console.log('⚠️ Erreur génération Prisma (peut être normal en mode pkg):', error.message);
    }
    
    // Appliquer les migrations avec version forcée
    try {
      console.log('🗄️ Application des migrations...');
      const { execSync } = require('child_process');
      const backendPath = path.join(__dirname, '..');
      
      // Essayer d'abord avec la version locale
      try {
        execSync('node_modules\\.bin\\prisma db push --accept-data-loss', { 
          cwd: backendPath,
          stdio: 'inherit' 
        });
        console.log('✓ Structure de base de données créée (version locale)');
      } catch (localError) {
        // Fallback avec version spécifique
        try {
          execSync('npx --package=prisma@6.17.1 prisma db push --accept-data-loss', { 
            cwd: backendPath,
            stdio: 'inherit' 
          });
          console.log('✓ Structure de base de données créée (version 6.17.1)');
        } catch (specificError) {
          // Dernier recours avec migrate deploy
          execSync('npx prisma migrate deploy', { 
            cwd: backendPath,
            stdio: 'inherit' 
          });
          console.log('✓ Migrations appliquées (version globale)');
        }
      }
    } catch (error) {
      console.log('⚠️ Erreur migrations (peut être normal en mode pkg):', error.message);
    }
    
    // S'assurer que les données de base existent
    console.log('\n👑 Vérification des données de base...');
    try {
      const { ensureAdminExists } = require('../scripts/ensure-admin');
      await ensureAdminExists();
      console.log('✓ Utilisateur admin vérifié');
      
      const { ensureBaseData } = require('../scripts/ensure-base-data');
      await ensureBaseData();
      console.log('✓ Données de base vérifiées');
    } catch (error) {
      console.log('⚠️ Erreur vérification données de base:', error.message);
      // Continuer même si les scripts ne sont pas disponibles
    }
    
    // Démarrer le serveur complet avec toutes les fonctionnalités
    console.log('\n🌐 Démarrage du serveur HTTP complet...');
    const server = require('./server');
    await server.start();
    
  } catch (error) {
    console.error('\n❌ Erreur fatale au démarrage:', error.message);
    console.error(error.stack);
    
    if (isPkg) {
      console.log('\n⚠️ Appuyez sur une touche pour fermer...');
      process.stdin.setRawMode(true);
      process.stdin.resume();
      process.stdin.on('data', process.exit.bind(process, 1));
    } else {
      process.exit(1);
    }
  }
}



// Gestion propre de l'arrêt
process.on('SIGINT', () => {
  console.log('\n\n🛑 Arrêt du serveur...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Arrêt du serveur...');
  process.exit(0);
});

// Démarrer le serveur
startStandaloneServer();
