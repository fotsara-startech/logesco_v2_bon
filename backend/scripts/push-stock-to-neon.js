/**
 * Pousse tous les stock_boutiques et stock locaux vers Neon
 * en prenant le local comme source de vérité pour les stocks
 */

require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function run() {
  const prisma = new PrismaClient();
  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false },
    max: 1,
  });

  const client = await pool.connect();
  try {
    console.log('📤 Push stock_boutiques local → Neon\n');

    // stock_boutiques
    const stockBoutiques = await prisma.$queryRawUnsafe('SELECT * FROM stock_boutiques');
    let pushed = 0;
    for (const row of stockBoutiques) {
      try {
        await client.query(`
          INSERT INTO stock_boutiques (id, boutique_id, produit_id, quantite_disponible, quantite_reservee, derniere_maj)
          VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT (id) DO UPDATE SET
            quantite_disponible = EXCLUDED.quantite_disponible,
            quantite_reservee = EXCLUDED.quantite_reservee,
            derniere_maj = EXCLUDED.derniere_maj
        `, [row.id, row.boutique_id || row.boutiqueId, row.produit_id || row.produitId,
            row.quantite_disponible || row.quantiteDisponible,
            row.quantite_reservee || row.quantiteReservee || 0,
            row.derniere_maj || row.derniereMaj || new Date().toISOString()]);
        pushed++;
      } catch (e) {
        console.warn(`  ⚠️  stock_boutiques id ${row.id}: ${e.message}`);
      }
    }
    console.log(`✅ stock_boutiques: ${pushed}/${stockBoutiques.length} poussés`);

    // stock global
    const stocks = await prisma.$queryRawUnsafe('SELECT * FROM stock');
    pushed = 0;
    for (const row of stocks) {
      try {
        await client.query(`
          INSERT INTO stock (id, produit_id, quantite_disponible, quantite_reservee, derniere_maj)
          VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (id) DO UPDATE SET
            quantite_disponible = EXCLUDED.quantite_disponible,
            quantite_reservee = EXCLUDED.quantite_reservee,
            derniere_maj = EXCLUDED.derniere_maj
        `, [row.id, row.produit_id || row.produitId,
            row.quantite_disponible || row.quantiteDisponible,
            row.quantite_reservee || row.quantiteReservee || 0,
            row.derniere_maj || row.derniereMaj || new Date().toISOString()]);
        pushed++;
      } catch (e) {
        console.warn(`  ⚠️  stock id ${row.id}: ${e.message}`);
      }
    }
    console.log(`✅ stock global: ${pushed}/${stocks.length} poussés`);

  } finally {
    client.release();
    await pool.end();
    await prisma.$disconnect();
  }
}

run().catch(e => { console.error('❌', e.message); process.exit(1); });
