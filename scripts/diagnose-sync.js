/**
 * Script de diagnostic de synchronisation
 * Affiche l'état complet du système de synchronisation
 */

const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function diagnoseSyncStatus() {
  const prisma = new PrismaClient();
  const cloudUrl = process.env.CLOUD_DB_URL;

  console.log('🔍 Diagnostic de synchronisation LOGESCO\n');
  console.log('═'.repeat(60));

  try {
    // 1. Configuration
    console.log('\n📋 CONFIGURATION');
    console.log('─'.repeat(60));
    console.log(`CLOUD_DB_URL défini: ${cloudUrl ? '✅ OUI' : '❌ NON'}`);
    console.log(`DATABASE_URL: ${process.env.DATABASE_URL || 'Non défini'}`);

    if (!cloudUrl) {
      console.log('\n⚠️  Mode local uniquement (CLOUD_DB_URL non défini)');
      console.log('   La synchronisation cloud est désactivée.');
      await prisma.$disconnect();
      return;
    }

    // 2. Connexion Neon
    console.log('\n☁️  CONNEXION NEON');
    console.log('─'.repeat(60));
    const pool = new Pool({
      connectionString: cloudUrl,
      ssl: { rejectUnauthorized: false },
      max: 1,
      connectionTimeoutMillis: 5000,
    });

    let neonAvailable = false;
    let neonStats = {};
    try {
      const client = await pool.connect();
      await client.query('SELECT 1');
      neonAvailable = true;
      console.log('✅ Connexion Neon établie');

      // Statistiques Neon
      const tables = ['utilisateurs', 'produits', 'clients', 'ventes', 'boutiques'];
      for (const table of tables) {
        try {
          const result = await client.query(`SELECT COUNT(*) as count FROM "${table}"`);
          neonStats[table] = parseInt(result.rows[0].count);
        } catch (e) {
          neonStats[table] = 'Erreur';
        }
      }
      client.release();
    } catch (e) {
      console.log(`❌ Connexion Neon échouée:`);
      console.log(`   Message: ${e.message}`);
      console.log(`   Code: ${e.code || 'N/A'}`);
      if (e.stack) {
        console.log(`   Stack: ${e.stack.split('\n')[0]}`);
      }
    }

    // 3. Base de données locale
    console.log('\n💾 BASE DE DONNÉES LOCALE (SQLite)');
    console.log('─'.repeat(60));
    
    const localStats = {};
    const tables = ['utilisateurs', 'produits', 'clients', 'ventes', 'boutiques'];
    for (const table of tables) {
      try {
        const result = await prisma.$queryRawUnsafe(`SELECT COUNT(*) as count FROM "${table}"`);
        localStats[table] = result[0].count;
      } catch (e) {
        localStats[table] = 'Erreur';
      }
    }

    console.log('Enregistrements par table:');
    for (const table of tables) {
      const local = localStats[table];
      const neon = neonStats[table] || 'N/A';
      console.log(`  ${table.padEnd(20)} Local: ${String(local).padStart(6)}  |  Neon: ${String(neon).padStart(6)}`);
    }

    // 4. Métadonnées de synchronisation
    console.log('\n🔄 MÉTADONNÉES DE SYNCHRONISATION');
    console.log('─'.repeat(60));
    
    try {
      const syncMeta = await prisma.$queryRawUnsafe('SELECT * FROM sync_meta');
      if (syncMeta.length === 0) {
        console.log('⚠️  Aucune métadonnée de synchronisation trouvée');
        console.log('   Exécutez: npm run sync:reset');
      } else {
        for (const meta of syncMeta) {
          console.log(`  ${meta.key.padEnd(20)}: ${meta.value}`);
        }
      }
    } catch (e) {
      console.log(`❌ Erreur lecture sync_meta: ${e.message}`);
      console.log('   La table sync_meta n\'existe peut-être pas encore');
    }

    // 5. Queue de synchronisation
    console.log('\n📤 QUEUE DE SYNCHRONISATION');
    console.log('─'.repeat(60));
    
    try {
      const queueStats = await prisma.$queryRawUnsafe(`
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN synced = 0 THEN 1 ELSE 0 END) as pending,
          SUM(CASE WHEN synced = 1 THEN 1 ELSE 0 END) as synced,
          SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as errors
        FROM sync_queue
      `);
      
      const stats = queueStats[0];
      console.log(`  Total d'opérations:        ${stats.total}`);
      console.log(`  En attente (synced=0):     ${stats.pending}`);
      console.log(`  Synchronisées (synced=1):  ${stats.synced}`);
      console.log(`  Avec erreurs:              ${stats.errors}`);

      if (stats.pending > 0) {
        console.log('\n  Opérations en attente par table:');
        const byTable = await prisma.$queryRawUnsafe(`
          SELECT table_name, COUNT(*) as count
          FROM sync_queue
          WHERE synced = 0
          GROUP BY table_name
          ORDER BY count DESC
          LIMIT 10
        `);
        for (const row of byTable) {
          console.log(`    ${row.table_name.padEnd(30)}: ${row.count}`);
        }
      }

      if (stats.errors > 0) {
        console.log('\n  ⚠️  Erreurs récentes:');
        const errors = await prisma.$queryRawUnsafe(`
          SELECT table_name, operation, error, created_at
          FROM sync_queue
          WHERE error IS NOT NULL
          ORDER BY created_at DESC
          LIMIT 5
        `);
        for (const err of errors) {
          console.log(`    [${err.table_name}] ${err.operation}: ${err.error}`);
        }
      }
    } catch (e) {
      console.log(`❌ Erreur lecture sync_queue: ${e.message}`);
      console.log('   La table sync_queue n\'existe peut-être pas encore');
    }

    // 6. Recommandations
    console.log('\n💡 RECOMMANDATIONS');
    console.log('─'.repeat(60));

    if (!neonAvailable) {
      console.log('❌ Neon inaccessible');
      console.log('   → Vérifiez CLOUD_DB_URL dans .env');
      console.log('   → Vérifiez votre connexion internet');
      console.log('   → Vérifiez les credentials Neon');
    } else if (neonStats.utilisateurs === 0 && localStats.utilisateurs > 0) {
      console.log('⚠️  Neon est vide mais le local contient des données');
      console.log('   → Exécutez: npm run sync:force');
      console.log('   → Puis: npm run sync:reset');
      console.log('   → Redémarrez le serveur');
    } else if (neonStats.utilisateurs > 0 && localStats.utilisateurs === 0) {
      console.log('⚠️  Le local est vide mais Neon contient des données');
      console.log('   → Exécutez: npm run sync:reset');
      console.log('   → Redémarrez le serveur (pull automatique)');
    } else {
      const syncMeta = await prisma.$queryRawUnsafe('SELECT * FROM sync_meta');
      const lastPull = syncMeta.find(m => m.key === 'last_pull')?.value;
      const initialPullDone = syncMeta.find(m => m.key === 'initial_pull_done')?.value;

      if (lastPull === '1970-01-01T00:00:00.000Z' || initialPullDone === '0') {
        console.log('⚠️  Métadonnées de synchronisation non initialisées');
        console.log('   → Redémarrez le serveur pour initialiser la sync');
      } else {
        console.log('✅ Système de synchronisation configuré correctement');
        console.log('   → Vérifiez les logs du serveur pour l\'état en temps réel');
      }
    }

    await pool.end();

  } catch (error) {
    console.error('\n❌ Erreur lors du diagnostic:', error.message);
  } finally {
    await prisma.$disconnect();
  }

  console.log('\n' + '═'.repeat(60));
  console.log('Diagnostic terminé\n');
}

diagnoseSyncStatus();
