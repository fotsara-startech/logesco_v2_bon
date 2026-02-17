/**
 * Script de build pour créer un exécutable standalone du backend
 * Utilisé pour le déploiement client simplifié
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Construction du backend standalone LOGESCO...\n');

// Étape 1: Vérifier que pkg est installé
console.log('📦 Vérification de pkg...');
try {
  execSync('npx pkg --version', { stdio: 'inherit' });
} catch (error) {
  console.log('Installation de pkg...');
  execSync('npm install -g pkg', { stdio: 'inherit' });
}

// Étape 2: Générer le client Prisma
console.log('\n🔧 Génération du client Prisma...');
execSync('npx prisma generate', { stdio: 'inherit' });

// Étape 3: Créer le dossier dist
const distPath = path.join(__dirname, '..', 'dist');
if (!fs.existsSync(distPath)) {
  fs.mkdirSync(distPath, { recursive: true });
}

// Étape 4: Créer le fichier de configuration pour l'exécutable
console.log('\n📝 Création du fichier de configuration...');
const standaloneConfig = {
  name: 'logesco-backend',
  version: '1.0.0',
  main: 'src/server.js',
  bin: 'src/server.js',
  pkg: {
    scripts: [
      'src/**/*.js',
      'scripts/**/*.js'
    ],
    assets: [
      'prisma/schema.prisma',
      'node_modules/@prisma/client/**/*',
      'node_modules/.prisma/client/**/*'
    ],
    targets: ['node18-win-x64'],
    outputPath: distPath
  }
};

// Étape 5: Build l'exécutable
console.log('\n🔨 Construction de l\'exécutable Windows...');
try {
  // Utiliser server-standalone.js comme point d'entrée
  execSync('npx pkg src/server-standalone.js --targets node18-win-x64 --output ../dist/logesco-backend.exe', {
    stdio: 'inherit',
    cwd: __dirname
  });
} catch (error) {
  console.error('❌ Erreur lors de la construction:', error.message);
  process.exit(1);
}

// Étape 6: Copier les fichiers nécessaires
console.log('\n📋 Copie des fichiers nécessaires...');

// Copier le schéma Prisma
const prismaSchemaSource = path.join(__dirname, 'prisma', 'schema.prisma');
const prismaSchemaTarget = path.join(distPath, 'schema.prisma');
if (fs.existsSync(prismaSchemaSource)) {
  fs.copyFileSync(prismaSchemaSource, prismaSchemaTarget);
  console.log('✓ Schema Prisma copié');
}

// Créer un fichier .env par défaut
const defaultEnv = `# Configuration LOGESCO Backend
NODE_ENV=production
PORT=8080
DATABASE_URL=file:./database/logesco.db
JWT_SECRET=${require('crypto').randomBytes(32).toString('hex')}
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
`;

fs.writeFileSync(path.join(distPath, '.env.example'), defaultEnv);
console.log('✓ Fichier .env.example créé');

// Créer le dossier database
const dbPath = path.join(distPath, 'database');
if (!fs.existsSync(dbPath)) {
  fs.mkdirSync(dbPath, { recursive: true });
  console.log('✓ Dossier database créé');
}

// Créer un README pour l'exécutable
const readmeContent = `# LOGESCO Backend Standalone

## Démarrage Rapide

1. Copier .env.example vers .env
2. Lancer logesco-backend.exe
3. Le serveur démarre sur http://localhost:8080

## Configuration

Modifier le fichier .env pour personnaliser:
- PORT: Port du serveur (défaut: 8080)
- DATABASE_URL: Chemin de la base de données
- JWT_SECRET: Clé secrète pour les tokens

## Structure

- logesco-backend.exe: Serveur backend
- database/: Base de données SQLite
- logs/: Fichiers de logs
- .env: Configuration

## Support

Pour toute question, consulter la documentation principale.
`;

fs.writeFileSync(path.join(distPath, 'README.txt'), readmeContent);
console.log('✓ README créé');

console.log('\n✅ Build terminé avec succès!');
console.log(`📁 Fichiers générés dans: ${distPath}`);
console.log('\n📦 Contenu:');
console.log('  - logesco-backend.exe (Serveur backend)');
console.log('  - .env.example (Configuration)');
console.log('  - schema.prisma (Schéma de base de données)');
console.log('  - README.txt (Instructions)');
console.log('  - database/ (Dossier pour la base de données)');
