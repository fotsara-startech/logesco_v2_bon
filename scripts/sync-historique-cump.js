/**
 * Script pour synchroniser historique_prix_achat et CUMP existants vers Neon
 */

require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function syncHistoriqueAndCump() {
  const prisma = new PrismaClient();
  const cloudUrl = process.env.CLOUD_DB_URL;

  if (!cloudUrl) {
    console.error('❌ CLOUD_DB_URL non défini dans .env');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString: cloudUrl,
    ssl: { rejectUnauthorized: false },
    max: 1,
  });

  try {
    console.log('🔄 Synchronisation historique_prix_achat et CUMP vers Neon\n');
    console.log('═'.repeat(60));

    // Test connexion Neon
    const client = await pool.connect();
    await client.query('SELECT 1');
    console.log('✅ Connexion Neon établie\n');

    // 1. Synchroniser historique_prix_achat
    console.log('📦 Synchronisation historique_prix_achat');
    console.log('─'.repeat(60));
    
    const historique = await prisma.$queryRawUnsafe(
      'SELECT * FROM historique_prix_achat'
    );
    
    console.log(`   ${historique.length} enregistrement(s) trouvé(s) en local`);
    
    let syncedHistorique = 0;
    for (const row of historique) {
      try {
        await client.query(
          `INSERT INTO historique_prix_achat 
           (id, produit_id, prix_achat, quantite, source, reference_id, date_creation)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (id) DO UPDATE SET
             produit_id = EXCLUDED.produit_id,
             prix_achat = EXCLUDED.prix_achat,
             quantite = EXCLUDED.quantite,
             source = EXCLUDED.source,
             reference_id = EXCLUDED.reference_id,
             date_creation = EXCLUDED.date_creation`,
          [
            row.id,
            row.produit_id,
            row.prix_achat,
            row.quantite || 1,
            row.source || 'manuel',
            row.reference_id,
            row.date_creation || new Date().toISOString()
          ]
        );
        syncedHistorique++;
      } catch (e) {
        console.warn(`   ⚠️  Erreur ligne ${row.id}: ${e.message}`);
      }
    }
    
    console.log(`✅ ${syncedHistorique}/${historique.length} enregistrement(s) synchronisé(s)\n`);

    // 2. Synchroniser les CUMP des produits
    console.log('💰 Synchronisation CUMP des produits');
    console.log('─'.repeat(60));
    
    const produits = await prisma.$queryRawUnsafe(
      'SELECT id, cump FROM produits WHERE cump IS NOT NULL'
    );
    
    console.log(`   ${produits.length} produit(s) avec CUMP trouvé(s) en local`);
    
    let syncedCump = 0;
    for (const produit of produits) {
      try {
        await client.query(
          'UPDATE produits SET cump = $1 WHERE id = $2',
          [produit.cump, produit.id]
        );
        syncedCump++;
      } catch (e) {
        console.warn(`   ⚠️  Erreur produit ${produit.id}: ${e.message}`);
      }
    }
    
    console.log(`✅ ${syncedCump}/${produits.length} CUMP synchronisé(s)\n`);

    client.release();

    console.log('═'.repeat(60));
    console.log('✅ Synchronisation terminée avec succès');
    console.log('\nℹ️  Les futures modifications seront synchronisées automatiquement');

  } catch (error) {
    console.error('\n❌ Erreur lors de la synchronisation:');
    console.error('   Message:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

syncHistoriqueAndCump();
