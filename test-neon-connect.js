const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://neondb_owner:npg_2gLKZJUC5RSa@ep-sweet-voice-alhik3h7.c-3.eu-central-1.aws.neon.tech/neondb',
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
