/**
 * Cleanup script to clear old sync queue entries
 * Run: node cleanup-sync-queue.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function cleanup() {
  try {
    console.log('🧹 Cleaning up sync queue...\n');

    // Count before
    const countBefore = await prisma.$queryRawUnsafe(
      'SELECT COUNT(*) as count FROM sync_queue'
    );
    console.log(`📊 Queue entries before: ${countBefore[0].count}`);

    // Delete all entries
    const result = await prisma.$queryRawUnsafe(
      'DELETE FROM sync_queue'
    );
    console.log(`🗑️  Deleted: ${result} entries`);

    // Delete sync metadata
    const metaResult = await prisma.$queryRawUnsafe(
      'DELETE FROM sync_meta'
    );
    console.log(`🗑️  Deleted sync_meta: ${metaResult} entries`);

    // Count after
    const countAfter = await prisma.$queryRawUnsafe(
      'SELECT COUNT(*) as count FROM sync_queue'
    );
    console.log(`\n✅ Queue entries after: ${countAfter[0].count}`);
    console.log('✅ Cleanup complete!\n');
    console.log('📝 Next steps:');
    console.log('   1. Restart backend: npm start');
    console.log('   2. Create a new sale in Flutter app');
    console.log('   3. Check logs for: 🔍 Sync ventes');
    console.log('   4. Verify in Neon: psql $CLOUD_DB_URL -c "SELECT COUNT(*) FROM ventes;"');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

cleanup();
