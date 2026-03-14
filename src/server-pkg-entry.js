/**
 * server-pkg-entry.js
 * Point d'entrée pour la compilation pkg.
 * Résout les chemins de données et démarre le serveur.
 */
const path = require('path');
const fs   = require('fs');
const os   = require('os');

// ── Dossier de données persistantes ───────────────────────────────────────
// Séparé de l'exe pour que les MAJ n'écrasent jamais les données client.
const DATA_DIR = process.env.LOGESCO_DATA_DIR
  || path.join(os.homedir(), 'AppData', 'Local', 'LOGESCO', 'backend');

// Créer les dossiers si absents (premier lancement)
['database', 'logs', 'uploads'].forEach(d => {
  const p = path.join(DATA_DIR, d);
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
});

// ── Charger .env ───────────────────────────────────────────────────────────
const envFile = path.join(DATA_DIR, '.env');
if (fs.existsSync(envFile)) {
  require('dotenv').config({ path: envFile });
} else {
  // Valeurs par défaut robustes
  const dbUrl = 'file:' + path.join(DATA_DIR, 'database', 'logesco.db').replace(/\\/g, '/');
  process.env.NODE_ENV     = 'production';
  process.env.PORT         = '8080';
  process.env.DATABASE_URL = dbUrl;
  process.env.JWT_SECRET   = 'logesco-jwt-' + Date.now();
  process.env.CORS_ORIGIN  = '*';
  process.env.LOG_LEVEL    = 'info';

  // Écrire le .env pour les prochains lancements
  const envContent = [
    'NODE_ENV=production',
    'PORT=8080',
    `DATABASE_URL="${dbUrl}"`,
    `JWT_SECRET="logesco-jwt-${Date.now()}"`,
    'JWT_EXPIRES_IN=24h',
    'CORS_ORIGIN=*',
    'LOG_LEVEL=info',
  ].join('\n');
  try { fs.writeFileSync(envFile, envContent, 'utf8'); } catch (_) {}
}

// Exposer DATA_DIR globalement
process.env.LOGESCO_DATA_DIR = DATA_DIR;

// ── Démarrer le serveur ────────────────────────────────────────────────────
require('./server');
