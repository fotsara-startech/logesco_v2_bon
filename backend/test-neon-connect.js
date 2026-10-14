const { Client } = require('pg');
if (!process.env.CLOUD_DB_URL) {
  console.error("CLOUD_DB_URL est requis : l'URL de la base Neon doit etre passee en variable d'environnement (jamais ecrite dans le code).");
  process.exit(1);
}

const client = new Client({
  connectionString: process.env.CLOUD_DB_URL,
  ssl: { rejectUnauthorized: false }
});

client.connect()
  .then(() => {
    console.log('✅ Connexion réussie');
    return client.query('SELECT version()');
  })
  .then(r => {
    console.log('Version:', r.rows[0].version.substring(0, 50));
    return client.end();
  })
  .catch(e => {
    console.error('❌ Erreur connexion:', e.message);
    process.exit(1);
  });
