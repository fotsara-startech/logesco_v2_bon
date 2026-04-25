/**
 * Check what data exists in Neon
 * Run: node check-neon-data.js
 */

require('dotenv').config();
const { Pool } = require('pg');

async function checkNeon() {
  if (!process.env.CLOUD_DB_URL) {
    console.error('❌ CLOUD_DB_URL not set in .env');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔍 Checking Neon data...\n');

    // Check sessions
    const sessions = await pool.query('SELECT COUNT(*) as count FROM cash_sessions');
    console.log(`📊 Cash Sessions in Neon: ${sessions.rows[0].count}`);

    // Check ventes
    const ventes = await pool.query('SELECT COUNT(*) as count FROM ventes');
    console.log(`📊 Ventes in Neon: ${ventes.rows[0].count}`);

    // Check for orphaned ventes (ventes without sessions)
    const orphaned = await pool.query(`
      SELECT COUNT(*) as count FROM ventes v 
      WHERE v.session_id NOT IN (SELECT id FROM cash_sessions)
    `);
    console.log(`⚠️  Orphaned Ventes (no session): ${orphaned.rows[0].count}`);

    // Show some details
    console.log('\n📋 Recent Ventes:');
    const recentVentes = await pool.query(`
      SELECT id, numero_vente, session_id FROM ventes 
      ORDER BY id DESC LIMIT 5
    `);
    for (const row of recentVentes.rows) {
      console.log(`   ID: ${row.id}, Numero: ${row.numero_vente}, Session: ${row.session_id}`);
    }

    console.log('\n📋 Recent Sessions:');
    const recentSessions = await pool.query(`
      SELECT id, caisse_id, utilisateur_id FROM cash_sessions 
      ORDER BY id DESC LIMIT 5
    `);
    for (const row of recentSessions.rows) {
      console.log(`   ID: ${row.id}, Caisse: ${row.caisse_id}, User: ${row.utilisateur_id}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkNeon();
