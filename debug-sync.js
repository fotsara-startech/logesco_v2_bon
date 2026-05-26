/**
 * Debug de la connexion sync vers Neon
 */
const { Pool } = require('pg');

const cloudUrl = process.env.CLOUD_DB_URL || 'postgresql://neondb_owner:npg_2gLKZJUC5RSa@ep-sweet-voice-alhik3h7.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

console.log('URL utilisée:', cloudUrl.replace(/:([^@]+)@/, ':***@'));

const pool = new Pool({
  connectionString: cloudUrl,
  ssl: { rejectUnauthorized: false },
  max: 3,
  idleTimeoutMillis: 10000,
  connectionTimeoutMillis: 5000,
});

pool.connect()
  .then(async client => {
    console.log('✅ Pool connecté');
    const r = await client.query('SELECT COUNT(*) as total FROM utilisateurs');
    console.log('Utilisateurs sur Neon:', r.rows[0].total);
    const tables = await client.query(`
      SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    `);
    console.log('Tables sur Neon:', tables.rows.map(r => r.tablename).join(', '));
    client.release();
    await pool.end();
  })
  .catch(e => {
    console.error('❌ Erreur connexion pool:', e.message);
    console.error('Code:', e.code);
    process.exit(1);
  });
