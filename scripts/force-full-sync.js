/**
 * Script pour forcer une synchronisation complète local → Neon
 * À utiliser après avoir recréé manuellement la base Neon
 */

const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function forceFullSync() {
  const prisma = new PrismaClient();
  const cloudUrl = process.env.CLOUD_DB_URL;

  if (!cloudUrl) {
    console.error('❌ CLOUD_DB_URL non défini dans .env');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString: cloudUrl,
    ssl: { rejectUnauthorized: false },
    max: 3,
  });

  try {
    console.log('🔄 Démarrage de la synchronisation complète local → Neon...\n');

    // Test de connexion Neon
    const client = await pool.connect();
    await client.query('SELECT 1');
    console.log('✅ Connexion Neon établie\n');

    // Tables dans l'ordre des dépendances FK
    const tables = [
      'user_roles',
      'utilisateurs',
      'boutiques',
      'user_boutique_assignments',
      'categories',
      'produits',
      'stock',
      'stock_boutiques',
      'fournisseurs',
      'comptes_fournisseurs',
      'clients',
      'comptes_clients',
      'cash_registers',
      'cash_sessions',
      'cash_movements',
      'movement_categories',
      'financial_movements',
      'commandes_approvisionnement',
      'details_commandes_approvisionnement',
      'ventes',
      'details_ventes',
      'ventes_proforma',
      'details_ventes_proforma',
      'mouvements_stock',
      'transferts_stock',
      'transactions_comptes',
      'parametres_entreprise',
      'dates_peremption',
      'stock_inventories',
      'inventory_items',
      'historique_recus',
    ];

    let totalSynced = 0;

    for (const table of tables) {
      try {
        // Récupérer les données locales
        const rows = await prisma.$queryRawUnsafe(`SELECT * FROM "${table}"`);
        
        if (rows.length === 0) {
          console.log(`⏭️  ${table}: aucune donnée locale`);
          continue;
        }

        let synced = 0;
        for (const row of rows) {
          try {
            // Convertir camelCase → snake_case et filtrer les relations
            const data = {};
            for (const [key, value] of Object.entries(row)) {
              if (Array.isArray(value)) continue;
              if (value !== null && typeof value === 'object' && !(value instanceof Date)) continue;
              
              const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
              data[snakeKey] = value instanceof Date ? value.toISOString() : value;
            }

            // Filtrer les clés undefined/null
            const keys = Object.keys(data).filter(k => {
              if (data[k] === undefined) return false;
              if (data[k] === null) return false;
              if (k.startsWith('_')) return false;
              return true;
            });
            const values = keys.map(k => data[k]);

            if (keys.length === 0) continue;

            // INSERT avec ON CONFLICT DO UPDATE
            const cols = keys.map(k => `"${k}"`).join(', ');
            const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
            const updates = keys.filter(k => k !== 'id').map(k => `"${k}" = EXCLUDED."${k}"`).join(', ');

            await client.query(
              `INSERT INTO "${table}" (${cols}) VALUES (${placeholders}) 
               ON CONFLICT (id) DO UPDATE SET ${updates}`,
              values
            );
            synced++;
          } catch (rowErr) {
            console.warn(`  ⚠️  Erreur ligne ${row.id}:`, rowErr.message);
          }
        }

        totalSynced += synced;
        console.log(`✅ ${table}: ${synced}/${rows.length} enregistrement(s) synchronisé(s)`);
      } catch (tableErr) {
        console.warn(`❌ ${table}: ${tableErr.message}`);
      }
    }

    client.release();

    console.log(`\n✅ Synchronisation complète terminée: ${totalSynced} enregistrement(s) envoyés vers Neon`);
    console.log('\nℹ️  Prochaines étapes:');
    console.log('1. Exécutez: node scripts/reset-sync-metadata.js');
    console.log('2. Redémarrez le serveur');

  } catch (error) {
    console.error('❌ Erreur lors de la synchronisation:');
    console.error('   Message:', error.message);
    console.error('   Code:', error.code || 'N/A');
    if (error.stack) {
      console.error('   Stack:', error.stack.split('\n').slice(0, 3).join('\n   '));
    }
    process.exit(1);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

forceFullSync();
