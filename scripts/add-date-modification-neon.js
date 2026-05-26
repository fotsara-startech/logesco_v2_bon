/**
 * Ajoute date_modification à historique_prix_achat sur Neon
 * pour éviter le pull complet à chaque cycle de synchronisation
 */

require('dotenv').config();
const { Pool } = require('pg');

async function run() {
  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false },
    max: 1,
  });

  const client = await pool.connect();
  try {
    console.log('🔧 Ajout de date_modification à historique_prix_achat sur Neon...');

    // Vérifier si la colonne existe déjà
    const check = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'historique_prix_achat' AND column_name = 'date_modification'
    `);

    if (check.rows.length > 0) {
      console.log('✅ Colonne date_modification déjà présente');
    } else {
      await client.query(`
        ALTER TABLE historique_prix_achat
        ADD COLUMN date_modification TIMESTAMPTZ DEFAULT NOW()
      `);
      // Initialiser avec date_creation
      await client.query(`
        UPDATE historique_prix_achat SET date_modification = date_creation
      `);
      console.log('✅ Colonne date_modification ajoutée et initialisée');
    }

    // Vérifier aussi stock_boutiques a bien derniere_maj
    const checkSb = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'stock_boutiques' AND column_name = 'derniere_maj'
    `);
    console.log(`\nstock_boutiques.derniere_maj: ${checkSb.rows.length > 0 ? '✅ présente' : '❌ absente'}`);

    const checkS = await client.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'stock' AND column_name = 'derniere_maj'
    `);
    console.log(`stock.derniere_maj: ${checkS.rows.length > 0 ? '✅ présente' : '❌ absente'}`);

    // Vérifier les valeurs actuelles de stock_boutiques sur Neon
    const sbCount = await client.query(`SELECT COUNT(*) as count FROM stock_boutiques`);
    console.log(`\nstock_boutiques sur Neon: ${sbCount.rows[0].count} entrées`);

    const sbSample = await client.query(`
      SELECT boutique_id, produit_id, quantite_disponible, derniere_maj
      FROM stock_boutiques ORDER BY derniere_maj DESC LIMIT 5
    `);
    console.log('Échantillon stock_boutiques Neon:');
    sbSample.rows.forEach(r => console.log(`  Boutique ${r.boutique_id}, Produit ${r.produit_id}: ${r.quantite_disponible} (maj: ${r.derniere_maj?.toISOString().split('T')[0]})`));

  } finally {
    client.release();
    await pool.end();
  }
}

run().catch(e => { console.error('❌', e.message); process.exit(1); });
