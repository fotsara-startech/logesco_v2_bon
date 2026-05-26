/**
 * Script pour réinitialiser les métadonnées de synchronisation
 * À utiliser après avoir recréé manuellement la base Neon
 */

const { PrismaClient } = require('../src/config/prisma-client');

async function resetSyncMetadata() {
  const prisma = new PrismaClient();

  try {
    console.log('🔄 Réinitialisation des métadonnées de synchronisation...');

    // 1. Réinitialiser last_pull pour forcer un pull complet
    await prisma.$executeRawUnsafe(
      `INSERT INTO sync_meta (key, value) VALUES ('last_pull', '1970-01-01T00:00:00.000Z')
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`
    );
    console.log('✅ last_pull réinitialisé à epoch');

    // 2. Réinitialiser initial_pull_done pour permettre un nouveau pull initial
    await prisma.$executeRawUnsafe(
      `INSERT INTO sync_meta (key, value) VALUES ('initial_pull_done', '0')
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`
    );
    console.log('✅ initial_pull_done réinitialisé à 0');

    // 3. Marquer toutes les entrées de la queue comme non synchronisées
    const result = await prisma.$executeRawUnsafe(
      `UPDATE sync_queue SET synced = 0, error = NULL WHERE synced = 1`
    );
    console.log(`✅ ${result} entrée(s) de sync_queue marquées comme non synchronisées`);

    // 4. Afficher le nombre d'entrées en attente
    const pending = await prisma.$queryRawUnsafe(
      `SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0`
    );
    console.log(`📊 ${pending[0].count} opération(s) en attente de synchronisation`);

    console.log('\n✅ Métadonnées de synchronisation réinitialisées avec succès');
    console.log('ℹ️  Redémarrez le serveur pour que les changements prennent effet');

  } catch (error) {
    console.error('❌ Erreur lors de la réinitialisation:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

resetSyncMetadata();
