/**
 * Check table schema
 * Run: node check-table-schema.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function check() {
  try {
    console.log('🔍 Checking financial_movements table schema...\n');

    const schema = await prisma.$queryRawUnsafe(`
      PRAGMA table_info(financial_movements)
    `);

    console.log('📋 Columns in financial_movements:');
    for (const col of schema) {
      const nullable = col.notnull === 0 ? 'NULL' : 'NOT NULL';
      console.log(`   ${col.name} (${col.type}) ${nullable}`);
    }

    // Check if session_id exists
    const hasSessionId = schema.some(col => col.name === 'session_id');
    console.log(`\n🔍 session_id column exists: ${hasSessionId ? '✅ YES' : '❌ NO'}`);

    if (!hasSessionId) {
      console.log('\n❌ PROBLEM: session_id column does not exist!');
      console.log('   You need to run a migration to add it.');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

check();
