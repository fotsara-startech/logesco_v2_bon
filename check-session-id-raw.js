/**
 * Check sessionId using raw SQL
 * Run: node check-session-id-raw.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function check() {
  try {
    console.log('🔍 Checking sessionId with RAW SQL...\n');
    console.log(`📁 Database path: ${process.env.DATABASE_URL}\n`);

    // Check last 5 movements with raw SQL
    const movements = await prisma.$queryRawUnsafe(`
      SELECT id, reference, session_id, boutique_id, montant, description
      FROM financial_movements
      ORDER BY id DESC
      LIMIT 5
    `);

    console.log('📋 Last 5 Financial Movements (RAW SQL):');
    for (const mov of movements) {
      const sessionStatus = mov.session_id ? `✅ ${mov.session_id}` : '❌ NULL';
      console.log(`   ID: ${mov.id}, Ref: ${mov.reference}, Session: ${sessionStatus}, Boutique: ${mov.boutique_id}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

check();
