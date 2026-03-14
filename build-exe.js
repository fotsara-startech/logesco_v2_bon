/**
 * build-exe.js
 * Compile le backend Node.js en un seul exécutable Windows (logesco-backend.exe)
 * en utilisant @vercel/pkg.
 *
 * Résultat: dist-exe/logesco-backend.exe (~80-120 MB, Node.js embarqué)
 * Ce fichier est ensuite copié par InnoSetup dans le package client.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const DIST = path.join(ROOT, '..', 'dist-exe');
const BACKEND_EXE = path.join(DIST, 'logesco-backend.exe');

// ─── helpers ────────────────────────────────────────────────────────────────

function run(cmd, cwd = ROOT) {
  console.log(`  > ${cmd}`);
  execSync(cmd, { cwd, stdio: 'inherit' });
}

function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

// ─── étape 1 : vérifier / installer pkg ─────────────────────────────────────

function ensurePkg() {
  try {
    execSync('npx pkg --version', { stdio: 'ignore' });
    console.log('✅ pkg disponible');
  } catch {
    console.log('📦 Installation de @vercel/pkg...');
    run('npm install --save-dev @vercel/pkg');
  }
}

// ─── étape 2 : créer server-entry.js (point d'entrée pkg) ───────────────────
// pkg ne peut pas embarquer les binaires Prisma natifs directement.
// On utilise la stratégie "prisma-client embarqué + binaire query-engine séparé".
// Le .exe extrait le query-engine dans un dossier temp au premier lancement.

function createEntryPoint() {
  const entryPath = path.join(ROOT, 'src', 'server-pkg-entry.js');
  const content = `/**
 * Point d'entrée pour pkg.
 * Gère l'extraction du query-engine Prisma et le démarrage du serveur.
 */
const path = require('path');
const fs   = require('fs');
const os   = require('os');

// ── Résoudre le chemin de travail ──────────────────────────────────────────
// Quand lancé via pkg, __dirname pointe dans le snapshot virtuel.
// On utilise process.execPath pour trouver le dossier réel de l'exe.
const EXE_DIR = path.dirname(process.execPath);

// Dossier de données persistantes (AppData\\Local\\LOGESCO\\backend)
const DATA_DIR = process.env.LOGESCO_DATA_DIR
  || path.join(os.homedir(), 'AppData', 'Local', 'LOGESCO', 'backend');

// S'assurer que les dossiers existent
['database', 'logs', 'uploads'].forEach(d => {
  const p = path.join(DATA_DIR, d);
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
});

// ── Variables d'environnement ──────────────────────────────────────────────
// Charger .env depuis DATA_DIR (créé par l'installeur ou BackendService)
const envFile = path.join(DATA_DIR, '.env');
if (fs.existsSync(envFile)) {
  require('dotenv').config({ path: envFile });
} else {
  // Valeurs par défaut si .env absent
  process.env.NODE_ENV    = process.env.NODE_ENV    || 'production';
  process.env.PORT        = process.env.PORT        || '8080';
  process.env.DATABASE_URL = process.env.DATABASE_URL
    || ('file:' + path.join(DATA_DIR, 'database', 'logesco.db').replace(/\\\\/g, '/'));
  process.env.JWT_SECRET  = process.env.JWT_SECRET  || 'logesco-secret-change-me';
  process.env.CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
}

// Exposer DATA_DIR pour que le reste du code puisse l'utiliser
process.env.LOGESCO_DATA_DIR = DATA_DIR;

// ── Démarrer le serveur ────────────────────────────────────────────────────
require('./server');
`;
  fs.writeFileSync(entryPath, content, 'utf8');
  console.log('✅ server-pkg-entry.js créé');
  return entryPath;
}

// ─── étape 3 : patch package.json pour pkg ──────────────────────────────────

function patchPackageJson() {
  const pkgJsonPath = path.join(ROOT, 'package.json');
  const pkgJson = JSON.parse(fs.readFileSync(pkgJsonPath, 'utf8'));

  // Configuration pkg
  pkgJson.pkg = {
    // Point d'entrée
    scripts: ['src/**/*.js'],
    // Assets à embarquer (schéma Prisma, migrations, seeds)
    assets: [
      'prisma/**/*',
      'src/**/*.json',
    ],
    // Cible: Node 18, Windows x64
    targets: ['node18-win-x64'],
    outputPath: '../dist-exe',
    // Nom de sortie
    output: 'logesco-backend',
  };

  // Script de build
  pkgJson.scripts = pkgJson.scripts || {};
  pkgJson.scripts['build:exe'] = 'node build-exe.js';

  fs.writeFileSync(pkgJsonPath, JSON.stringify(pkgJson, null, 2), 'utf8');
  console.log('✅ package.json patché pour pkg');
}

// ─── étape 4 : copier les binaires Prisma query-engine ──────────────────────
// pkg ne peut pas embarquer les .node natifs de Prisma.
// On les copie à côté de l'exe → l'installeur les inclut aussi.

function copyPrismaEngines() {
  const engineSrc = path.join(ROOT, 'node_modules', '.prisma', 'client');
  const engineDest = path.join(DIST, 'prisma-engines');

  if (!fs.existsSync(engineSrc)) {
    console.log('⚠️  Prisma client non généré. Génération...');
    run('npx prisma generate');
  }

  ensureDir(engineDest);

  // Copier tous les fichiers query-engine-*
  const files = fs.readdirSync(engineSrc);
  let copied = 0;
  for (const f of files) {
    if (f.startsWith('query_engine') || f.startsWith('libquery_engine') || f.endsWith('.node')) {
      fs.copyFileSync(path.join(engineSrc, f), path.join(engineDest, f));
      console.log(`  ✓ ${f}`);
      copied++;
    }
  }

  // Copier aussi le schema.prisma (nécessaire pour Prisma au runtime)
  const schemaSrc = path.join(ROOT, 'prisma', 'schema.prisma');
  const schemaDest = path.join(DIST, 'schema.prisma');
  fs.copyFileSync(schemaSrc, schemaDest);

  console.log(`✅ ${copied} binaire(s) Prisma copiés + schema.prisma`);
}

// ─── étape 5 : compiler avec pkg ────────────────────────────────────────────

function compilePkg() {
  ensureDir(DIST);

  const entryPoint = path.join(ROOT, 'src', 'server-pkg-entry.js');

  console.log('🔨 Compilation avec pkg (peut prendre 1-2 minutes)...');
  run(
    `npx pkg "${entryPoint}" --target node18-win-x64 --output "${BACKEND_EXE}" --compress GZip`,
    ROOT
  );

  if (!fs.existsSync(BACKEND_EXE)) {
    throw new Error('logesco-backend.exe non trouvé après compilation');
  }

  const sizeMB = (fs.statSync(BACKEND_EXE).size / 1024 / 1024).toFixed(1);
  console.log(`✅ logesco-backend.exe créé (${sizeMB} MB)`);
}

// ─── étape 6 : créer les dossiers et fichiers annexes dans dist-exe ──────────

function createAuxFiles() {
  // Dossiers que l'installeur créera aussi, mais utiles pour les tests locaux
  ['database', 'logs', 'uploads'].forEach(d => ensureDir(path.join(DIST, d)));

  // .env.example (l'installeur / BackendService crée le vrai .env)
  const envExample = `# Configuration LOGESCO Backend
# Ce fichier est géré automatiquement par l'application.
NODE_ENV=production
PORT=8080
DATABASE_URL=file:./database/logesco.db
JWT_SECRET=CHANGE_ME_IN_PRODUCTION
JWT_EXPIRES_IN=24h
CORS_ORIGIN=*
LOG_LEVEL=info
`;
  fs.writeFileSync(path.join(DIST, '.env.example'), envExample, 'utf8');

  // README minimal
  const readme = `LOGESCO Backend v2
==================
Ce dossier contient le backend LOGESCO compilé.

Fichiers:
  logesco-backend.exe   Serveur backend autonome
  prisma-engines/       Binaires Prisma (requis)
  schema.prisma         Schéma de la base de données
  database/             Base de données SQLite (créée au 1er lancement)
  uploads/              Fichiers uploadés
  logs/                 Journaux

Démarrage manuel (pour tests):
  logesco-backend.exe

Le backend démarre sur http://localhost:8080
`;
  fs.writeFileSync(path.join(DIST, 'README.txt'), readme, 'utf8');

  console.log('✅ Fichiers annexes créés');
}

// ─── main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║   LOGESCO - Build Backend EXE                    ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');

  try {
    console.log('[1/6] Vérification de pkg...');
    ensurePkg();

    console.log('\n[2/6] Création du point d\'entrée pkg...');
    createEntryPoint();

    console.log('\n[3/6] Patch package.json...');
    patchPackageJson();

    console.log('\n[4/6] Copie des binaires Prisma...');
    copyPrismaEngines();

    console.log('\n[5/6] Compilation pkg...');
    compilePkg();

    console.log('\n[6/6] Fichiers annexes...');
    createAuxFiles();

    console.log('');
    console.log('╔══════════════════════════════════════════════════╗');
    console.log('║   ✅ BUILD TERMINÉ AVEC SUCCÈS                   ║');
    console.log('╚══════════════════════════════════════════════════╝');
    console.log('');
    console.log(`📁 Sortie: dist-exe/`);
    console.log(`   logesco-backend.exe`);
    console.log(`   prisma-engines/`);
    console.log(`   schema.prisma`);
    console.log('');
    console.log('Prochaine étape: lancer build-installer.bat');

  } catch (err) {
    console.error('\n❌ ERREUR BUILD:', err.message);
    console.error('\nSolutions:');
    console.error('  1. npm install dans backend/');
    console.error('  2. npx prisma generate dans backend/');
    console.error('  3. Relancer en administrateur');
    process.exit(1);
  }
}

main();
