/**
 * build-exe.js - Stratégie Node.js portable
 *
 * Au lieu de compiler avec pkg (qui casse les modules natifs Prisma),
 * on crée un dossier dist-exe avec:
 *   - node.exe (Node.js portable, téléchargé une fois)
 *   - src/ + node_modules/ + prisma/ (le backend complet)
 *   - logesco-backend.cmd (lanceur)
 *
 * L'installeur copie tout ça dans AppData\Local\LOGESCO\backend\.
 * Flutter lance node.exe src/server.js silencieusement.
 *
 * Avantages vs pkg:
 *   - Aucun problème de modules natifs (Prisma, bcrypt, etc.)
 *   - Taille similaire (~80 MB avec node.exe)
 *   - Mise à jour facile: remplacer src/ sans toucher node.exe
 */

const fs   = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const ROOT = __dirname;
const DIST = path.join(ROOT, '..', 'dist-exe');

// Version Node.js portable à embarquer (doit correspondre à engines.node)
const NODE_VERSION = '18.20.4';
const NODE_URL = `https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-win-x64.zip`;
const NODE_ZIP  = path.join(DIST, 'node-portable.zip');
const NODE_EXE  = path.join(DIST, 'node.exe');

function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function run(cmd, cwd = ROOT) {
  console.log(`  > ${cmd}`);
  execSync(cmd, { cwd, stdio: 'inherit' });
}

function copyDirSync(src, dest) {
  if (!fs.existsSync(src)) return;
  ensureDir(dest);
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDirSync(s, d);
    else fs.copyFileSync(s, d);
  }
}

// Télécharger node.exe depuis nodejs.org (zip Windows x64)
async function downloadNodeExe() {
  if (fs.existsSync(NODE_EXE)) {
    console.log('✅ node.exe déjà présent');
    return;
  }

  console.log(`📥 Téléchargement Node.js ${NODE_VERSION}...`);
  ensureDir(DIST);

  // Télécharger le zip
  await new Promise((resolve, reject) => {
    const file = fs.createWriteStream(NODE_ZIP);
    https.get(NODE_URL, res => {
      if (res.statusCode === 302 || res.statusCode === 301) {
        https.get(res.headers.location, res2 => {
          res2.pipe(file);
          file.on('finish', () => { file.close(); resolve(); });
        }).on('error', reject);
      } else {
        res.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
      }
    }).on('error', reject);
  });

  // Extraire node.exe du zip avec PowerShell
  console.log('📦 Extraction de node.exe...');
  const extractCmd = `powershell -Command "` +
    `$zip = '${NODE_ZIP.replace(/\\/g, '\\\\')}'; ` +
    `$dest = '${DIST.replace(/\\/g, '\\\\')}'; ` +
    `Add-Type -Assembly System.IO.Compression.FileSystem; ` +
    `$z = [IO.Compression.ZipFile]::OpenRead($zip); ` +
    `$entry = $z.Entries | Where-Object { $_.Name -eq 'node.exe' } | Select-Object -First 1; ` +
    `[IO.Compression.ZipFileExtensions]::ExtractToFile($entry, [IO.Path]::Combine($dest, 'node.exe'), $true); ` +
    `$z.Dispose()"`;
  execSync(extractCmd, { stdio: 'inherit' });

  // Nettoyer le zip
  fs.unlinkSync(NODE_ZIP);
  console.log('✅ node.exe extrait');
}

async function main() {
  console.log('\n============================================================');
  console.log('  LOGESCO - Build Backend Portable (Node.js embarqué)');
  console.log('============================================================\n');

  try {
    // 1. Nettoyer dist-exe (sauf node.exe si déjà là)
    console.log('[1/6] Préparation dist-exe...');
    const nodeExeBackup = fs.existsSync(NODE_EXE) ? fs.readFileSync(NODE_EXE) : null;
    if (fs.existsSync(DIST)) fs.rmSync(DIST, { recursive: true, force: true });
    ensureDir(DIST);
    if (nodeExeBackup) { fs.writeFileSync(NODE_EXE, nodeExeBackup); console.log('  node.exe restauré depuis cache'); }
    console.log('✅ dist-exe prêt');

    // 2. Télécharger node.exe portable
    console.log('\n[2/6] Node.js portable...');
    await downloadNodeExe();

    // 3. Générer Prisma client
    console.log('\n[3/6] Génération Prisma client...');
    run('npx prisma generate');
    console.log('✅ Prisma client généré');

    // 4. Copier le code source backend
    console.log('\n[4/6] Copie du backend...');
    copyDirSync(path.join(ROOT, 'src'),    path.join(DIST, 'src'));
    copyDirSync(path.join(ROOT, 'prisma'), path.join(DIST, 'prisma'));
    // node_modules complet (nécessaire pour Prisma natif)
    copyDirSync(path.join(ROOT, 'node_modules'), path.join(DIST, 'node_modules'));
    fs.copyFileSync(path.join(ROOT, 'package.json'), path.join(DIST, 'package.json'));
    console.log('✅ Backend copié');

    // 5. Créer les dossiers de données et fichiers de config
    console.log('\n[5/6] Fichiers de configuration...');
    ['database', 'logs', 'uploads'].forEach(d => ensureDir(path.join(DIST, d)));

    // .env.example — sera copié en .env seulement si absent (1ère installation)
    // DATABASE_URL utilise un chemin relatif: fonctionne car le backend
    // s'exécute depuis %LOCALAPPDATA%\LOGESCO\backend\
    const envExample = [
      'NODE_ENV=production',
      'PORT=8080',
      'DATABASE_URL=file:./database/logesco.db',
      `JWT_SECRET=logesco-secret-change-me`,
      'JWT_EXPIRES_IN=365d',
      'JWT_REFRESH_EXPIRES_IN=365d',
      'CORS_ORIGIN=*',
      'LOG_LEVEL=info',
    ].join('\n');
    fs.writeFileSync(path.join(DIST, '.env.example'), envExample, 'utf8');

    // Copier schema.prisma à la racine (pour migrations)
    fs.copyFileSync(
      path.join(ROOT, 'prisma', 'schema.prisma'),
      path.join(DIST, 'schema.prisma')
    );
    console.log('✅ Fichiers de config créés');

    // 6. Créer le lanceur (remplace logesco-backend.exe)
    console.log('\n[6/6] Création du lanceur...');

    // logesco-backend.cmd — lanceur principal appelé par BackendService
    const launcherCmd = `@echo off\r\n"%~dp0node.exe" "%~dp0src\\server.js" %*\r\n`;
    fs.writeFileSync(path.join(DIST, 'logesco-backend.cmd'), launcherCmd, 'utf8');

    // logesco-backend.exe = wrapper VBScript compilé en exe via iexpress
    // Plus simple: on crée un .bat renommé en .exe via un wrapper minimal
    // En fait on crée un vrai .exe wrapper avec un script PowerShell
    const wrapperVbs = `Set WshShell = CreateObject("WScript.Shell")\r\n` +
      `strDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)\r\n` +
      `WshShell.Run Chr(34) & strDir & "\\node.exe" & Chr(34) & " " & Chr(34) & strDir & "\\src\\server.js" & Chr(34), 0, False\r\n`;
    fs.writeFileSync(path.join(DIST, 'logesco-backend.vbs'), wrapperVbs, 'utf8');

    // Créer un vrai exe wrapper avec PowerShell + iexpress n'est pas trivial.
    // On utilise une approche plus simple: un .bat qui se lance sans fenêtre via start /b
    // BackendService.dart sera mis à jour pour lancer node.exe directement.
    const readmeTxt = `LOGESCO Backend v2 - Node.js Portable\n` +
      `=====================================\n` +
      `node.exe          Node.js ${NODE_VERSION} portable\n` +
      `src/              Code source backend\n` +
      `node_modules/     Dependances (Prisma inclus)\n` +
      `database/         Base de donnees SQLite\n` +
      `uploads/          Fichiers uploades\n` +
      `logs/             Journaux\n\n` +
      `Demarrage: node.exe src/server.js\n` +
      `Backend sur http://localhost:8080\n`;
    fs.writeFileSync(path.join(DIST, 'README.txt'), readmeTxt, 'utf8');
    console.log('✅ Lanceur créé');

    console.log('\n============================================================');
    console.log('  ✅ BUILD TERMINÉ');
    console.log('============================================================');
    console.log(`\n📁 dist-exe/`);
    console.log(`   node.exe (Node.js ${NODE_VERSION})`);
    console.log(`   src/`);
    console.log(`   node_modules/`);
    console.log(`   .env.example`);
    console.log('\nProchaine étape: compile-installer-only.bat\n');

  } catch (err) {
    console.error('\n❌ ERREUR:', err.message);
    process.exit(1);
  }
}

main();
