/**
 * Manually enqueue session 52 to sync
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function enqueue() {
  try {
    // Get session 52
    const session = await prisma.$queryRawUnsafe(
      'SELECT * FROM cash_sessions WHERE id = 52'
    );
    
    if (!session || session.length === 0) {
      console.log('❌ Session 52 not found');
      return;
    }

    // Enqueue it
    await prisma.$executeRawUnsafe(
      'INSERT INTO sync_queue (table_name, operation, record_id, data) VALUES (?, ?, ?, ?)',
      'cash_sessions', 'INSERT', '52', JSON.stringify(session[0])
    );

    console.log('✅ Session 52 enqueued to sync_queue');
    console.log('📝 Next: Restart backend and it will sync automatically');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

enqueue();
