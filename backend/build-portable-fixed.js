/**
 * Script amélioré pour créer un package portable du backend
 * Gestion des erreurs Prisma et permissions Windows
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Création du package portable LOGESCO Backend (Version Améliorée)...\n');

const distPath = path.join(__dirname, '..', 'dist-portable');

// Fonction pour nettoyer avec gestion des permissions Windows
function cleanDirectory(dirPath) {
  if (fs.existsSync(dirPath)) {
    console.log(`🧹 Nettoyage de ${dirPath}...`);
    try {
      // Essayer de supprimer normalement
      fs.rmSync(dirPath, { recursive: true, force: true });
    } catch (error) {
      console.log('⚠️ Suppression normale échouée, tentative avec attrib...');
      try {
        // Utiliser attrib pour enlever les attributs de lecture seule
        execSync(`attrib -R "${dirPath}\\*.*" /S /D`, { stdio: 'ignore' });
        // Puis rmdir avec force
        execSync(`rmdir /S /Q "${dirPath}"`, { stdio: 'ignore' });
      } catch (cmdError) {
        console.log('⚠️ Suppression par commande échouée, tentative manuelle...');
        // Dernier recours : renommer le dossier
        const backupPath = dirPath + '_backup_' + Date.now();
        try {
          fs.renameSync(dirPath, backupPath);
          console.log(`📁 Dossier renommé en ${backupPath} (à supprimer manuellement)`);
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
      // Ignorer les dossiers problématiques
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
      
      // Nettoyer le cache npm d'abord
      if (i > 0) {
        console.log('🧹 Nettoyage du cache npm...');
        execSync('npm cache clean --force', { cwd: distPath, stdio: 'inherit' });
      }
      
      // Installer avec des options plus robustes
      execSync('npm install --production --no-optional --no-audit --no-fund --prefer-offline', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 300000 // 5 minutes
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

// Fonction pour générer Prisma avec fallback
async function generatePrisma() {
  try {
    console.log('🔄 Génération du client Prisma...');
    // Forcer l'utilisation de la version locale de Prisma
    execSync('npx prisma@6.17.1 generate', {
      cwd: distPath,
      stdio: 'inherit',
      timeout: 180000 // 3 minutes
    });
    console.log('✅ Client Prisma généré');
    return true;
  } catch (error) {
    console.log('⚠️ Tentative avec version globale...');
    try {
      execSync('npx prisma generate', {
        cwd: distPath,
        stdio: 'inherit',
        timeout: 180000
      });
      console.log('✅ Client Prisma généré (version globale)');
      return true;
    } catch (globalError) {
      console.log('⚠️ Génération Prisma échouée, tentative de copie...');
      
      // Essayer de copier depuis le dossier source
      const sourcePrisma = path.join(__dirname, 'node_modules', '.prisma');
      const destPrisma = path.join(distPath, 'node_modules', '.prisma');
      
      if (fs.existsSync(sourcePrisma)) {
        try {
          copyRecursiveSync(sourcePrisma, destPrisma);
          console.log('✅ Client Prisma copié depuis le source');
          return true;
        } catch (copyError) {
          console.log('❌ Erreur lors de la copie Prisma:', copyError.message);
        }
      }
      
      // Dernière tentative : télécharger manuellement les engines
      try {
        console.log('🔄 Tentative de téléchargement manuel des engines...');
        execSync('npx prisma generate --generator client', {
          cwd: distPath,
          stdio: 'inherit',
          env: { ...process.env, PRISMA_CLI_BINARY_TARGETS: 'native' }
        });
        console.log('✅ Engines téléchargés manuellement');
        return true;
      } catch (manualError) {
        console.log('❌ Téléchargement manuel échoué');
        return false;
      }
    }
  }
}

async function main() {
  try {
    // Étape 1: Nettoyer le dossier dist
    console.log('[1/7] Nettoyage...');
    cleanDirectory(distPath);
    fs.mkdirSync(distPath, { recursive: true });
    console.log('✅ Dossier dist-portable créé');

    // Étape 2: Copier les fichiers source
    console.log('\n[2/7] Copie des fichiers source...');
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
    console.log('\n[3/7] Optimisation du package.json...');
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
    console.log('\n[4/7] Installation des dépendances...');
    await installDependencies();

    // Étape 5: Générer le client Prisma
    console.log('\n[5/7] Génération du client Prisma...');
    const prismaSuccess = await generatePrisma();
    if (!prismaSuccess) {
      console.log('⚠️ Prisma non généré, mais continuons...');
    }

    // Étape 6: Créer les dossiers de données
    console.log('\n[6/7] Création des dossiers...');
    ['database', 'logs', 'uploads'].forEach(folder => {
      const folderPath = path.join(distPath, folder);
      if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
      }
    });
    console.log('✅ Dossiers créés');

    // Étape 7: Créer les scripts de lancement
    console.log('\n[7/7] Création des scripts de lancement...');

    // Script Windows amélioré
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

REM Vérifier que le client Prisma existe
if not exist "node_modules\\.prisma" (
    echo ⚠️ Client Prisma manquant, tentative de generation...
    npx prisma@6.17.1 generate
    if errorlevel 1 (
        echo ⚠️ Tentative avec version globale...
        npx prisma generate
        if errorlevel 1 (
            echo ❌ Erreur generation Prisma
            echo Verifiez votre connexion Internet
            pause
            exit /b 1
        )
    )
)

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
    console.log('✅ start-backend.bat créé');

    // Script de diagnostic
    const diagnosticBat = `@echo off
title LOGESCO - Diagnostic
echo ========================================
echo LOGESCO Backend - Diagnostic
echo ========================================
echo.

echo [1/5] Verification Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js NON INSTALLE
    echo Telechargez: https://nodejs.org/
) else (
    echo ✅ Node.js INSTALLE
    node --version
)
echo.

echo [2/5] Verification des dependances...
if exist "node_modules" (
    echo ✅ Dossier node_modules present
) else (
    echo ❌ Dossier node_modules manquant
    echo Executez: npm install
)
echo.

echo [3/5] Verification Prisma...
if exist "node_modules\\.prisma" (
    echo ✅ Client Prisma present
) else (
    echo ❌ Client Prisma manquant
    echo Executez: npx prisma generate
)
echo.

echo [4/5] Verification base de donnees...
if exist "database\\logesco.db" (
    echo ✅ Base de donnees presente
) else (
    echo ⚠️ Base de donnees manquante (sera creee au demarrage)
)
echo.

echo [5/5] Verification port 8080...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ✅ Port 8080 libre
) else (
    echo ⚠️ Port 8080 deja utilise
)
echo.

echo ========================================
echo Diagnostic termine
echo ========================================
pause
`;

    fs.writeFileSync(path.join(distPath, 'diagnostic.bat'), diagnosticBat);
    console.log('✅ diagnostic.bat créé');

    // README amélioré
    const readme = `LOGESCO Backend Portable v${originalPackage.version}
${'='.repeat(50)}

DEMARRAGE RAPIDE
================
1. Double-cliquez sur: start-backend.bat
2. Attendez que "Serveur démarré" apparaisse
3. Ouvrez votre navigateur sur: http://localhost:8080
4. Connexion: admin / admin123

PREREQUIS
=========
- Windows 10/11 (64-bit)
- Node.js 18 ou superieur (https://nodejs.org/)
- 200 MB d'espace disque libre

DEPANNAGE
=========
Si le serveur ne demarre pas:

1. Executez: diagnostic.bat
2. Verifiez que Node.js est installe: node --version
3. Si erreur Prisma: npx prisma generate
4. Si port occupe: changez PORT dans .env
5. Consultez les logs: logs/error.log

STRUCTURE
=========
start-backend.bat    - Demarrage du serveur
diagnostic.bat       - Verification du systeme
src/                 - Code source
node_modules/        - Dependances (NE PAS SUPPRIMER)
prisma/             - Schema base de donnees
database/           - Base de donnees SQLite
logs/               - Fichiers de logs
uploads/            - Fichiers uploades

CONFIGURATION
=============
Modifiez .env pour personnaliser:
- PORT=8080          - Port du serveur
- DATABASE_URL=...   - Chemin base de donnees
- JWT_SECRET=...     - Cle secrete tokens

SUPPORT
=======
En cas de probleme persistant:
1. Verifiez les prerequis
2. Consultez diagnostic.bat
3. Verifiez les logs dans logs/
4. Redemarrez en tant qu'administrateur

Version: ${originalPackage.version}
Date: ${new Date().toLocaleDateString('fr-FR')}
`;

    fs.writeFileSync(path.join(distPath, 'README.txt'), readme);
    console.log('✅ README.txt créé');

    // Créer un fichier .env par défaut
    const defaultEnv = `# Configuration LOGESCO Backend Portable
PORT=8080
NODE_ENV=production
DATABASE_URL="file:./database/logesco.db"
JWT_SECRET="logesco-jwt-secret-change-in-production"
CORS_ORIGIN="*"
RATE_LIMIT_ENABLED=false
`;

    fs.writeFileSync(path.join(distPath, '.env'), defaultEnv);
    console.log('✅ .env par défaut créé');

    console.log('\n' + '='.repeat(60));
    console.log('🎉 PACKAGE PORTABLE CRÉÉ AVEC SUCCÈS !');
    console.log('='.repeat(60));
    console.log(`📁 Emplacement: ${distPath}`);
    console.log('\n📦 Contenu:');
    console.log('  ✅ start-backend.bat (Démarrage)');
    console.log('  ✅ diagnostic.bat (Vérification)');
    console.log('  ✅ src/ (Code source)');
    console.log('  ✅ node_modules/ (Dépendances)');
    console.log('  ✅ prisma/ (Schéma DB)');
    console.log('  ✅ .env (Configuration)');
    console.log('  ✅ README.txt (Instructions)');
    
    const stats = fs.statSync(distPath);
    console.log(`\n📊 Taille: ~${Math.round(getDirectorySize(distPath) / 1024 / 1024)} MB`);
    
    console.log('\n🧪 Pour tester:');
    console.log(`  cd ${path.relative(process.cwd(), distPath)}`);
    console.log('  start-backend.bat');
    
    console.log('\n🚀 Prêt pour la distribution !');

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

// Fonction utilitaire pour calculer la taille
function getDirectorySize(dirPath) {
  let size = 0;
  try {
    const files = fs.readdirSync(dirPath);
    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const stats = fs.statSync(filePath);
      if (stats.isDirectory()) {
        size += getDirectorySize(filePath);
      } else {
        size += stats.size;
      }
    }
  } catch (error) {
    // Ignorer les erreurs d'accès
  }
  return size;
}

// Exécuter le script
main();