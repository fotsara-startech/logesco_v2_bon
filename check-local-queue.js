/**
 * Check what's in the local sync queue
 * Run: node check-local-queue.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkQueue() {
  try {
    console.log('🔍 Checking local sync queue...\n');

    // Get pending items
    const pending = await prisma.$queryRawUnsafe(
      'SELECT id, table_name, operation, data FROM sync_queue WHERE synced = 0 ORDER BY id'
    );

    console.log(`📊 Pending items: ${pending.length}\n`);

    for (const item of pending) {
      const data = JSON.parse(item.data);
      console.log(`Item ${item.id}: ${item.table_name} (${item.operation})`);
      console.log(`  Full data:`, JSON.stringify(data, null, 2));
      console.log();
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkQueue();
