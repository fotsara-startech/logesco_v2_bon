/**
 * Réinitialise sync_meta pour forcer une nouvelle sync initiale vers Neon
 * A exécuter quand Neon a été vidé et recréé
 */
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  try {
    // Réinitialiser initial_pull_done pour permettre le reset local
    await prisma.$executeRawUnsafe(
      "INSERT INTO sync_meta (key, value) VALUES ('initial_pull_done', '0') ON CONFLICT(key) DO UPDATE SET value = '0'"
    );
    // Réinitialiser last_pull pour forcer un pull complet
    await prisma.$executeRawUnsafe(
      "INSERT INTO sync_meta (key, value) VALUES ('last_pull', '1970-01-01T00:00:00.000Z') ON CONFLICT(key) DO UPDATE SET value = '1970-01-01T00:00:00.000Z'"
    );
    // Vider la sync_queue pour repartir proprement
    await prisma.$executeRawUnsafe("DELETE FROM sync_queue");

    const meta = await prisma.$queryRawUnsafe("SELECT * FROM sync_meta");
    console.log('✅ sync_meta réinitialisé:', meta);
    console.log('✅ sync_queue vidée');
    console.log('\nRedémarre le backend — la sync initiale va pousser toutes les données locales vers Neon.');
  } catch(e) {
    console.error('❌', e.message);
  } finally {
    await prisma.$disconnect();
  }
}
run();
