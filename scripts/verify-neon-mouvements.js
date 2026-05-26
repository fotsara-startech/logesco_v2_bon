require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function run() {
  const prisma = new PrismaClient();
  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 8000,
  });

  try {
    const client = await pool.connect();

    const localCount = await prisma.$queryRawUnsafe('SELECT COUNT(*) as count FROM mouvements_stock');
    const neonCount = await client.query('SELECT COUNT(*) as count FROM mouvements_stock');
    const neonSample = await client.query(`
      SELECT id, produit_id, type_mouvement, changement_quantite, boutique_id, date_mouvement
      FROM mouvements_stock ORDER BY date_mouvement DESC LIMIT 5
    `);

    console.log(`mouvements_stock — Local: ${localCount[0].count}, Neon: ${neonCount.rows[0].count}`);
    console.log('\nDerniers mouvements sur Neon:');
    neonSample.rows.forEach(r => console.log(`  ID ${r.id}: ${r.type_mouvement} ${r.changement_quantite > 0 ? '+' : ''}${r.changement_quantite} produit=${r.produit_id} boutique=${r.boutique_id} date=${new Date(r.date_mouvement).toISOString().split('T')[0]}`));

    // Vérifier stock_boutiques sur Neon pour Permasil
    const sb = await client.query('SELECT * FROM stock_boutiques WHERE produit_id = 724');
    console.log('\nstock_boutiques Permasil (724) sur Neon:', sb.rows);

    client.release();
    await pool.end();
  } catch (e) {
    console.error('❌ Neon inaccessible:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}
run().catch(e => { console.error(e.message); process.exit(1); });
