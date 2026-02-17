/**
 * Script pour créer un package portable du backend (sans compilation exe)
 * Cette approche fonctionne mieux avec Prisma
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Création du package portable LOGESCO Backend...\n');

const distPath = path.join(__dirname, '..', 'dist-portable');

// Étape 1: Nettoyer le dossier dist
console.log('[1/6] Nettoyage...');
if (fs.existsSync(distPath)) {
  fs.rmSync(distPath, { recursive: true, force: true });
}
fs.mkdirSync(distPath, { recursive: true });
console.log('✓ Dossier dist-portable créé');

// Étape 2: Copier les fichiers source
console.log('\n[2/6] Copie des fichiers source...');
const filesToCopy = [
  'src',
  'prisma',
  'scripts',
  'package.json',
  'package-lock.json',
  '.env.example'
];

for (const file of filesToCopy) {
  const src = path.join(__dirname, file);
  const dest = path.join(distPath, file);
  
  if (fs.existsSync(src)) {
    copyRecursiveSync(src, dest);
    console.log(`✓ Copié: ${file}`);
  }
}

// Étape 3: Installer les dépendances de production
console.log('\n[3/6] Installation des dépendances...');
try {
  execSync('npm install --production --omit=dev', {
    cwd: distPath,
    stdio: 'inherit'
  });
  console.log('✓ Dépendances installées');
} catch (error) {
  console.error('❌ Erreur installation:', error.message);
  process.exit(1);
}

// Étape 4: Générer le client Prisma
console.log('\n[4/6] Génération du client Prisma...');
try {
  // Essayer avec un timeout plus long
  console.log('Tentative de génération du client Prisma...');
  execSync('npx prisma generate', {
    cwd: distPath,
    stdio: 'inherit',
    timeout: 120000 // 2 minutes
  });
  console.log('✓ Client Prisma généré');
} catch (error) {
  console.error('⚠️ Erreur génération Prisma:', error.message);
  console.log('\n⚠️ Le client Prisma n\'a pas pu être téléchargé.');
  console.log('Cela peut être dû à un problème de connexion réseau.');
  
  // Essayer de copier depuis le dossier source si disponible
  const sourcePrisma = path.join(__dirname, 'node_modules', '.prisma');
  const destPrisma = path.join(distPath, 'node_modules', '.prisma');
  
  if (fs.existsSync(sourcePrisma)) {
    console.log('\n📋 Copie du client Prisma depuis le dossier source...');
    try {
      copyRecursiveSync(sourcePrisma, destPrisma);
      console.log('✓ Client Prisma copié depuis le source');
    } catch (copyError) {
      console.error('❌ Erreur lors de la copie:', copyError.message);
      process.exit(1);
    }
  } else {
    console.error('\n❌ Impossible de générer ou copier le client Prisma');
    console.error('Veuillez vérifier votre connexion Internet et réessayer.');
    process.exit(1);
  }
}

// Étape 5: Créer les dossiers de données
console.log('\n[5/6] Création des dossiers...');
['database', 'logs', 'uploads'].forEach(folder => {
  const folderPath = path.join(distPath, folder);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
  }
});
console.log('✓ Dossiers créés');

// Étape 6: Créer les scripts de lancement
console.log('\n[6/6] Création des scripts de lancement...');

// Script Windows
const startBat = `@echo off
title LOGESCO Backend Server
echo ========================================
echo LOGESCO Backend Server
echo ========================================
echo.
echo Demarrage du serveur...
echo.

node "%~dp0src\\server-standalone.js"

pause
`;

fs.writeFileSync(path.join(distPath, 'start-backend.bat'), startBat);
console.log('✓ start-backend.bat créé');

// Script pour installer comme service Windows
const installServiceBat = `@echo off
echo ========================================
echo Installation du service LOGESCO Backend
echo ========================================
echo.
echo Ce script necessite NSSM (Non-Sucking Service Manager)
echo Telechargez-le depuis: https://nssm.cc/download
echo.
pause

set NSSM_PATH=nssm.exe
set SERVICE_NAME=LOGESCO-Backend
set NODE_PATH=%~dp0node.exe
set SCRIPT_PATH=%~dp0src\\server-standalone.js

echo Installation du service...
%NSSM_PATH% install %SERVICE_NAME% "%NODE_PATH%" "%SCRIPT_PATH%"
%NSSM_PATH% set %SERVICE_NAME% AppDirectory "%~dp0"
%NSSM_PATH% set %SERVICE_NAME% DisplayName "LOGESCO Backend Server"
%NSSM_PATH% set %SERVICE_NAME% Description "Serveur backend pour l'application LOGESCO"
%NSSM_PATH% set %SERVICE_NAME% Start SERVICE_AUTO_START

echo.
echo Service installe avec succes!
echo Pour demarrer: nssm start %SERVICE_NAME%
echo Pour arreter: nssm stop %SERVICE_NAME%
echo Pour desinstaller: nssm remove %SERVICE_NAME% confirm
echo.
pause
`;

fs.writeFileSync(path.join(distPath, 'install-service.bat'), installServiceBat);
console.log('✓ install-service.bat créé');

// README
const readme = `# LOGESCO Backend Portable

## Démarrage Manuel

Double-cliquez sur \`start-backend.bat\`

Le serveur démarre sur http://localhost:8080

## Installation comme Service Windows

1. Téléchargez NSSM: https://nssm.cc/download
2. Extrayez nssm.exe dans ce dossier
3. Exécutez \`install-service.bat\` en tant qu'administrateur

## Configuration

Modifiez le fichier \`.env\` pour personnaliser:
- PORT: Port du serveur (défaut: 8080)
- DATABASE_URL: Chemin de la base de données
- JWT_SECRET: Clé secrète pour les tokens

## Structure

- src/ : Code source
- node_modules/ : Dépendances (NE PAS SUPPRIMER)
- prisma/ : Schéma de base de données
- database/ : Base de données SQLite
- logs/ : Fichiers de logs
- uploads/ : Fichiers uploadés

## Prérequis

Node.js 18+ doit être installé sur le système.
Téléchargez depuis: https://nodejs.org/

## Dépannage

### Le serveur ne démarre pas

1. Vérifiez que Node.js est installé: \`node --version\`
2. Vérifiez les logs dans le dossier \`logs/\`
3. Vérifiez que le port 8080 n'est pas déjà utilisé

### Erreur Prisma

Régénérez le client: \`npx prisma generate\`

### Erreur de base de données

Appliquez les migrations: \`npx prisma migrate deploy\`
`;

fs.writeFileSync(path.join(distPath, 'README.txt'), readme);
console.log('✓ README.txt créé');

console.log('\n✅ Package portable créé avec succès!');
console.log(`📁 Emplacement: ${distPath}`);
console.log('\n📦 Contenu:');
console.log('  - start-backend.bat (Démarrage manuel)');
console.log('  - install-service.bat (Installation comme service)');
console.log('  - src/ (Code source)');
console.log('  - node_modules/ (Dépendances)');
console.log('  - prisma/ (Schéma DB)');
console.log('  - README.txt (Instructions)');
console.log('\n🎉 Prêt pour la distribution!');
console.log('\nPour tester:');
console.log(`  cd ${path.relative(process.cwd(), distPath)}`);
console.log('  start-backend.bat');

// Fonction utilitaire
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
