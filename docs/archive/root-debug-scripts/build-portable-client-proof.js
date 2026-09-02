/**
 * Script ultra-robuste pour créer un package portable
 * Compatible avec tous les environnements clients
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Création du package portable LOGESCO (Version Client-Proof)...\n');

const distPath = path.join(__dirname, '..', 'dist-portable');

// Fonction pour nettoyer avec gestion des permissions Windows
function cleanDirectory(dirPath) {
  if (fs.existsSync(dirPath)) {
    console.log(`🧹 Nettoyage de ${dirPath}...`);
    try {
      fs.rmSync(dirPath, { recursive: true, force: true });
    } catch (error) {
      try {
        execSync(`attrib -R "${dirPath}\\*.*" /S /D`, { stdio: 'ignore' });
        execSync(`rmdir /S /Q "${dirPath}"`, { stdio: 'ignore' });
      } catch (cmdError) {
        const backupPath = dirPath + '_backup_' + Date.now();
        try {
          fs.renameSync(dirPath, backupPath);
          console.log(`📁 Dossier renommé en ${backupPath}`);
        } catch (renameError) {
          console.log('⚠️ Impossible de nettoyer complètement, continuons...');
        }
      }
    }
  }
}

// Fonction de copie améliorée
function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  
  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(childItemName => {
      if (childItemName === 'node_modules' || childItemName === '.git') {
        return;
      }
      copyRecursiveSync(
        path.join(src, childItemName),
        path.join(dest, childItemName)
      );
    });
  } else {
    try {
      fs.copyFileSync(src, dest);
    } catch (error) {
      console.log(`⚠️ Erreur copie ${src}: ${error.message}`);
    }
  }
}

// Fonction pour installer les dépendances avec retry
async function installDependencies(retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      console.log(`Tentative ${i + 1}/${retries} d'installation des dépendances...`);
      
      if (i > 0) {
        console.log('🧹 Nettoyage du cache npm...');
        execSync('npm cache clean --force', { cwd: distPath, stdio: 'inherit' });
      }
      
      execSync('npm install --production --no-optional --no-audit --no-fund --prefer-offline', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 300000
      });
      
      console.log('✅ Dépendances installées avec succès');
      return true;
    } catch (error) {
      console.log(`❌ Tentative ${i + 1} échouée: ${error.message}`);
      if (i === retries - 1) {
        throw error;
      }
      console.log('⏳ Attente avant nouvelle tentative...');
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
}

// Fonction pour générer Prisma avec fallback ultra-robuste
async function generatePrismaClientProof() {
  console.log('🔄 Génération du client Prisma (Version Client-Proof)...');
  
  const strategies = [
    // Stratégie 1: Version locale depuis node_modules
    () => {
      console.log('Tentative 1: Version locale depuis node_modules...');
      execSync('node_modules\\.bin\\prisma generate', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 180000
      });
    },
    
    // Stratégie 2: Version spécifique 6.17.1
    () => {
      console.log('Tentative 2: Version spécifique 6.17.1...');
      execSync('npx --package=@prisma/client@6.17.1 --package=prisma@6.17.1 prisma generate', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 180000
      });
    },
    
    // Stratégie 3: Version globale avec schéma explicite
    () => {
      console.log('Tentative 3: Version globale avec schéma...');
      execSync('npx prisma generate --schema=prisma/schema.prisma', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 180000
      });
    },
    
    // Stratégie 4: Copie depuis le source
    () => {
      console.log('Tentative 4: Copie depuis le source...');
      const sourcePrisma = path.join(__dirname, 'node_modules', '.prisma');
      const destPrisma = path.join(distPath, 'node_modules', '.prisma');
      
      if (fs.existsSync(sourcePrisma)) {
        copyRecursiveSync(sourcePrisma, destPrisma);
        console.log('✅ Client Prisma copié depuis le source');
      } else {
        throw new Error('Source Prisma non trouvé');
      }
    }
  ];
  
  for (let i = 0; i < strategies.length; i++) {
    try {
      strategies[i]();
      console.log(`✅ Client Prisma généré (Stratégie ${i + 1})`);
      return true;
    } catch (error) {
      console.log(`⚠️ Stratégie ${i + 1} échouée: ${error.message}`);
      if (i === strategies.length - 1) {
        console.log('❌ Toutes les stratégies ont échoué');
        return false;
      }
    }
  }
  
  return false;
}

async function main() {
  try {
    // Étape 1: Nettoyer le dossier dist
    console.log('[1/8] Nettoyage...');
    cleanDirectory(distPath);
    fs.mkdirSync(distPath, { recursive: true });
    console.log('✅ Dossier dist-portable créé');

    // Étape 2: Copier les fichiers source
    console.log('\n[2/8] Copie des fichiers source...');
    const filesToCopy = [
      'src',
      'prisma',
      'scripts',
      'package.json',
      '.env.example'
    ];

    for (const file of filesToCopy) {
      const src = path.join(__dirname, file);
      const dest = path.join(distPath, file);
      
      if (fs.existsSync(src)) {
        copyRecursiveSync(src, dest);
        console.log(`✅ Copié: ${file}`);
      }
    }

    // Étape 3: Créer un package.json optimisé
    console.log('\n[3/8] Optimisation du package.json...');
    const originalPackage = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
    const optimizedPackage = {
      name: originalPackage.name,
      version: originalPackage.version,
      description: originalPackage.description,
      main: originalPackage.main,
      scripts: {
        start: "node src/server-standalone.js"
      },
      dependencies: originalPackage.dependencies,
      engines: originalPackage.engines
    };
    
    fs.writeFileSync(
      path.join(distPath, 'package.json'), 
      JSON.stringify(optimizedPackage, null, 2)
    );
    console.log('✅ Package.json optimisé');

    // Étape 4: Installer les dépendances
    console.log('\n[4/8] Installation des dépendances...');
    await installDependencies();

    // Étape 5: Générer le client Prisma
    console.log('\n[5/8] Génération du client Prisma...');
    const prismaSuccess = await generatePrismaClientProof();
    if (!prismaSuccess) {
      console.log('⚠️ Prisma non généré, mais continuons...');
    }

    // Étape 6: Créer les dossiers de données
    console.log('\n[6/8] Création des dossiers...');
    ['database', 'logs', 'uploads'].forEach(folder => {
      const folderPath = path.join(distPath, folder);
      if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
      }
    });
    console.log('✅ Dossiers créés');

    // Étape 7: Créer les scripts de lancement ultra-robustes
    console.log('\n[7/8] Création des scripts de lancement...');

    // Script Windows ultra-robuste
    const startBat = `@echo off
title LOGESCO Backend Server
echo ========================================
echo LOGESCO Backend Server v${originalPackage.version}
echo ========================================
echo.

REM Vérifier Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    echo.
    echo Veuillez installer Node.js 18 ou superieur:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js detecte
node --version
echo.

REM Vérifier et générer le client Prisma si nécessaire
if not exist "node_modules\\.prisma" (
    echo ⚠️ Client Prisma manquant, generation automatique...
    
    REM Stratégie 1: Version locale
    node_modules\\.bin\\prisma generate >nul 2>nul
    if errorlevel 1 (
        echo Tentative avec version specifique...
        
        REM Stratégie 2: Version spécifique
        npx --package=prisma@6.17.1 prisma generate >nul 2>nul
        if errorlevel 1 (
            echo Tentative avec version globale...
            
            REM Stratégie 3: Version globale
            npx prisma generate >nul 2>nul
            if errorlevel 1 (
                echo ❌ Erreur generation Prisma
                echo.
                echo Solutions:
                echo 1. Verifiez votre connexion Internet
                echo 2. Executez: npm cache clean --force
                echo 3. Redemarrez en tant qu'administrateur
                echo.
                pause
                exit /b 1
            )
        )
    )
    echo ✅ Client Prisma genere
)

REM Vérifier et créer la base de données si nécessaire
if not exist "database\\logesco.db" (
    echo ⚠️ Base de donnees manquante, creation automatique...
    
    REM Stratégie 1: Version locale
    node_modules\\.bin\\prisma db push --accept-data-loss >nul 2>nul
    if errorlevel 1 (
        echo Tentative avec version specifique...
        
        REM Stratégie 2: Version spécifique
        npx --package=prisma@6.17.1 prisma db push --accept-data-loss >nul 2>nul
        if errorlevel 1 (
            echo Tentative avec migrate deploy...
            
            REM Stratégie 3: Migrate deploy
            npx prisma migrate deploy >nul 2>nul
            if errorlevel 1 (
                echo ⚠️ Creation base de donnees echouee
                echo Le serveur tentera de la creer au demarrage
            )
        )
    )
    
    if exist "database\\logesco.db" (
        echo ✅ Base de donnees creee
    )
)

echo.
echo 🚀 Demarrage du serveur...
echo.
echo Backend disponible sur: http://localhost:8080
echo Connexion: admin / admin123
echo.
echo Pour arreter: Ctrl+C ou fermer cette fenetre
echo.

node "%~dp0src\\server-standalone.js"

if errorlevel 1 (
    echo.
    echo ❌ Le serveur s'est arrete avec une erreur
    echo Consultez les logs dans le dossier logs/
    echo.
)

pause
`;

    fs.writeFileSync(path.join(distPath, 'start-backend.bat'), startBat);
    console.log('✅ start-backend.bat créé (ultra-robuste)');

    // Étape 8: Créer un fichier .env par défaut
    console.log('\n[8/8] Configuration finale...');
    const defaultEnv = `# Configuration LOGESCO Backend Portable
PORT=8080
NODE_ENV=production
DATABASE_URL="file:./database/logesco.db"
JWT_SECRET="logesco-jwt-secret-change-in-production"
CORS_ORIGIN="*"
RATE_LIMIT_ENABLED=false
DEPLOYMENT_TYPE=local
`;

    fs.writeFileSync(path.join(distPath, '.env'), defaultEnv);
    console.log('✅ .env par défaut créé');

    // README pour le client
    const readme = `LOGESCO Backend Portable v${originalPackage.version}
${'='.repeat(50)}

DEMARRAGE RAPIDE
================
1. Double-cliquez sur: start-backend.bat
2. Attendez que "Serveur démarré" apparaisse
3. Le serveur gère automatiquement:
   - La génération du client Prisma
   - La création de la base de données
   - L'initialisation des données

PREREQUIS
=========
- Windows 10/11 (64-bit)
- Node.js 18 ou superieur (https://nodejs.org/)
- 200 MB d'espace disque libre

COMPATIBILITE
=============
Ce package est conçu pour fonctionner sur tous les
environnements clients, même avec des versions
différentes de Prisma installées globalement.

DEPANNAGE
=========
Le script start-backend.bat gère automatiquement:
- Les conflits de versions Prisma
- La création de la base de données
- L'initialisation des données

Si problème persistant:
1. Redémarrez en tant qu'administrateur
2. Vérifiez que Node.js est installé
3. Consultez les logs dans logs/

Version: ${originalPackage.version}
Date: ${new Date().toLocaleDateString('fr-FR')}
Compatibilité: Tous environnements clients
`;

    fs.writeFileSync(path.join(distPath, 'README.txt'), readme);
    console.log('✅ README.txt créé');

    console.log('\n' + '='.repeat(60));
    console.log('🎉 PACKAGE PORTABLE CLIENT-PROOF CRÉÉ !');
    console.log('='.repeat(60));
    console.log(`📁 Emplacement: ${distPath}`);
    console.log('\n📦 Fonctionnalités:');
    console.log('  ✅ Compatible tous environnements clients');
    console.log('  ✅ Gestion automatique des versions Prisma');
    console.log('  ✅ Création automatique de la base de données');
    console.log('  ✅ Initialisation automatique des données');
    console.log('  ✅ Scripts de démarrage ultra-robustes');
    
    console.log('\n🚀 Prêt pour déploiement client !');

  } catch (error) {
    console.error('\n❌ ERREUR LORS DE LA CRÉATION:', error.message);
    console.error('\n🔧 Solutions possibles:');
    console.error('  1. Fermer tous les processus Node.js');
    console.error('  2. Redémarrer en tant qu\'administrateur');
    console.error('  3. Vérifier la connexion Internet');
    console.error('  4. Nettoyer le cache npm: npm cache clean --force');
    process.exit(1);
  }
}

// Exécuter le script
main();