/**
 * Script de build amélioré pour créer un exécutable standalone
 * Gère correctement Prisma en copiant les fichiers natifs à côté de l'exe
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Construction du backend standalone LOGESCO (v2)...\n');

// Étape 1: Vérifier pkg
console.log('📦 Vérification de pkg...');
try {
  execSync('npx pkg --version', { stdio: 'inherit' });
} catch (error) {
  console.log('Installation de pkg...');
  execSync('npm install -g pkg', { stdio: 'inherit' });
}

// Étape 2: Plus besoin de Prisma (utilisation de JSON DB)
console.log('\n🔧 Préparation du build...');

// Étape 3: Créer le dossier dist
const distPath = path.join(__dirname, '..', 'dist');
if (!fs.existsSync(distPath)) {
  fs.mkdirSync(distPath, { recursive: true });
}

// Étape 4: Build l'exécutable en EXCLUANT Prisma du snapshot
console.log('\n🔨 Construction de l\'exécutable...');
try {
  // Exclure @prisma/client du snapshot pour le charger depuis le filesystem
  execSync(
    'npx pkg src/server-standalone.js --targets node18-win-x64 --output ../dist/logesco-backend.exe',
    {
      stdio: 'inherit',
      cwd: __dirname
    }
  );
} catch (error) {
  console.error('❌ Erreur lors de la construction:', error.message);
  process.exit(1);
}

// Étape 5: Copier les fichiers Prisma nécessaires
console.log('\n📋 Copie des fichiers Prisma...');

// Copier node_modules/@prisma/client
const prismaClientSrc = path.join(__dirname, 'node_modules', '@prisma', 'client');
const prismaClientDest = path.join(distPath, 'node_modules', '@prisma', 'client');

if (fs.existsSync(prismaClientSrc)) {
  console.log('Copie de @prisma/client...');
  copyRecursiveSync(prismaClientSrc, prismaClientDest);
  console.log('✓ @prisma/client copié');
} else {
  console.error('❌ @prisma/client introuvable. Exécutez: npm install');
  process.exit(1);
}

// Copier node_modules/.prisma/client
const dotPrismaClientSrc = path.join(__dirname, 'node_modules', '.prisma', 'client');
const dotPrismaClientDest = path.join(distPath, 'node_modules', '.prisma', 'client');

if (fs.existsSync(dotPrismaClientSrc)) {
  console.log('Copie de .prisma/client...');
  copyRecursiveSync(dotPrismaClientSrc, dotPrismaClientDest);
  console.log('✓ .prisma/client copié');
} else {
  console.error('❌ .prisma/client introuvable. Exécutez: npx prisma generate');
  process.exit(1);
}

// Copier le schéma Prisma
const schemaSrc = path.join(__dirname, 'prisma', 'schema.prisma');
const schemaDest = path.join(distPath, 'prisma', 'schema.prisma');

if (fs.existsSync(schemaSrc)) {
  if (!fs.existsSync(path.dirname(schemaDest))) {
    fs.mkdirSync(path.dirname(schemaDest), { recursive: true });
  }
  fs.copyFileSync(schemaSrc, schemaDest);
  console.log('✓ Schéma Prisma copié');
}

// Étape 6: Créer le fichier .env.example
console.log('\n📝 Création des fichiers de configuration...');
const crypto = require('crypto');
const defaultEnv = `# Configuration LOGESCO Backend
NODE_ENV=production
PORT=8080
DATABASE_URL=file:./database/logesco.db
JWT_SECRET=${crypto.randomBytes(32).toString('hex')}
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
DEPLOYMENT_TYPE=local
`;

fs.writeFileSync(path.join(distPath, '.env.example'), defaultEnv);
console.log('✓ Fichier .env.example créé');

// Créer les dossiers
['database', 'logs', 'uploads'].forEach(folder => {
  const folderPath = path.join(distPath, folder);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
  }
});
console.log('✓ Dossiers créés');

// Créer un README
const readmeContent = `# LOGESCO Backend Standalone

## Démarrage

1. Double-cliquez sur logesco-backend.exe
2. Le serveur démarre sur http://localhost:8080
3. Les données sont stockées dans: %LOCALAPPDATA%\\LOGESCO\\backend

## Configuration

Le fichier .env est créé automatiquement au premier démarrage dans:
%LOCALAPPDATA%\\LOGESCO\\backend\\.env

Vous pouvez le modifier pour personnaliser la configuration.

## Structure

- logesco-backend.exe : Serveur backend
- node_modules/@prisma/client : Client Prisma (REQUIS)
- node_modules/.prisma/client : Client généré (REQUIS)
- prisma/schema.prisma : Schéma de base de données

Les données sont stockées dans %LOCALAPPDATA%\\LOGESCO\\backend:
- database/ : Base de données SQLite
- logs/ : Fichiers de logs
- uploads/ : Fichiers uploadés

## Important

⚠️ NE SUPPRIMEZ PAS le dossier node_modules !
Il contient les fichiers natifs Prisma nécessaires au fonctionnement.

## Dépannage

Si le serveur ne démarre pas:
1. Vérifiez que le dossier node_modules/@prisma/client existe
2. Vérifiez que le dossier node_modules/.prisma/client existe
3. Vérifiez les logs dans: %LOCALAPPDATA%\\LOGESCO\\backend\\logs
`;

fs.writeFileSync(path.join(distPath, 'README.txt'), readmeContent);
console.log('✓ README créé');

console.log('\n✅ Build terminé avec succès!');
console.log(`📁 Fichiers générés dans: ${distPath}`);
console.log('\n📦 Contenu:');
console.log('  - logesco-backend.exe (Serveur backend standalone)');
console.log('  - node_modules/@prisma/client (Client Prisma)');
console.log('  - node_modules/.prisma/client (Client généré)');
console.log('  - prisma/schema.prisma (Schéma de base de données)');
console.log('  - .env.example (Configuration par défaut)');
console.log('  - README.txt (Instructions)');
console.log('  - database/, logs/, uploads/ (Dossiers de données)');
console.log('\n🎉 Le backend est prêt pour la distribution!');
console.log('✓ Prisma chargé depuis le filesystem (compatible pkg)');
console.log('✓ Base de données SQLite intégrée');
console.log('✓ Prêt pour la production');

// Fonction utilitaire pour copier récursivement
function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  
  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(childItemName => {
      copyRecursiveSync(
        path.join(src, childItemName),
        path.join(dest, childItemName)
      );
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}
