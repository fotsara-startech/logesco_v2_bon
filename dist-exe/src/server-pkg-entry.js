/**
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

// Dossier de données persistantes (AppData\Local\LOGESCO\backend)
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
    || ('file:' + path.join(DATA_DIR, 'database', 'logesco.db').replace(/\\/g, '/'));
  process.env.JWT_SECRET  = process.env.JWT_SECRET  || 'logesco-secret-change-me';
  process.env.CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
}

// Exposer DATA_DIR pour que le reste du code puisse l'utiliser
process.env.LOGESCO_DATA_DIR = DATA_DIR;

// ── Démarrer le serveur ────────────────────────────────────────────────────
require('./server');
