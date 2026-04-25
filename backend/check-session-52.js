/**
 * Check if session 52 exists locally
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  try {
    // Check local
    const localSession = await prisma.$queryRawUnsafe(
      'SELECT * FROM cash_sessions WHERE id = 52'
    );
    
    console.log('📊 Local Session 52:');
    if (localSession && localSession.length > 0) {
      console.log(JSON.stringify(localSession[0], null, 2));
    } else {
      console.log('❌ Not found locally');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

check();
