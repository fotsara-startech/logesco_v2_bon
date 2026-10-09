/**
 * Reproduit exactement la connexion Neon du backend (sync-service.js) et
 * affiche l'erreur réelle, que le service, lui, avale silencieusement.
 *
 * Usage (depuis le dossier backend installé) :
 *   node scripts/diagnose-neon-connection.js
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { Pool } = require('pg');

const url = process.env.CLOUD_DB_URL;
console.log('Node          :', process.version);
console.log('.env lu depuis:', path.join(__dirname, '../.env'));

if (!url) {
  console.log('\n❌ CLOUD_DB_URL est ABSENT du .env → le poste ne peut pas synchroniser.');
  process.exit(1);
}

const m = url.match(/^postgres(?:ql)?:\/\/([^:]+):[^@]*@([^/?]+)\/([^?]*)/);
console.log('Utilisateur   :', m ? m[1] : '(format illisible)');
console.log('Hôte          :', m ? m[2] : '(format illisible)');
console.log('Base          :', m ? m[3] : '(format illisible)');

async function essai(label, timeoutMs) {
  const pool = new Pool({
    connectionString: url,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: timeoutMs,
  });
  const t = Date.now();
  try {
    const c = await pool.connect();
    await c.query('SELECT 1');
    c.release();
    console.log(`✅ ${label} : OK en ${Date.now() - t} ms`);
  } catch (e) {
    console.log(`❌ ${label} : ÉCHEC après ${Date.now() - t} ms`);
    console.log('   code    :', e.code);
    console.log('   message :', e.message);
  } finally {
    await pool.end().catch(() => {});
  }
}

(async () => {
  console.log('');
  await essai('Délai 10 s (réglage actuel du backend)', 10000);
  await essai('Délai 30 s', 30000);
  await essai('Délai 30 s (2e essai, connexion à chaud)', 30000);
})();
