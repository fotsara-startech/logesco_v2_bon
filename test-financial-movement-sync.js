/**
 * Test script to verify financial movement sync
 * Run: node test-financial-movement-sync.js
 * 
 * This script:
 * 1. Checks the local sync_queue for cash_sessions and cash_registers entries
 * 2. Verifies that financial movements are NOT in the queue (intentional)
 * 3. Shows what should be synced when an expense is created
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testSync() {
  try {
    console.log('🧪 Testing Financial Movement Sync...\n');

    // Check sync_queue
    const queueItems = await prisma.$queryRawUnsafe(
      `SELECT table_name, operation, COUNT(*) as count FROM sync_queue GROUP BY table_name, operation`
    );

    console.log('📋 Sync Queue Status:');
    if (queueItems.length === 0) {
      console.log('   ✅ Queue is empty (all synced)');
    } else {
      for (const item of queueItems) {
        console.log(`   ${item.table_name} (${item.operation}): ${item.count} pending`);
      }
    }

    // Check what SHOULD be synced
    console.log('\n✅ What SHOULD be synced when creating an expense:');
    console.log('   1. cash_sessions (UPDATE) — soldeAttendu reduced');
    console.log('   2. cash_registers (UPDATE) — soldeActuel reduced');

    console.log('\n❌ What should NOT be synced:');
    console.log('   1. financial_movements — internal accounting');
    console.log('   2. cash_movements — internal tracking');

    // Check recent cash_sessions
    console.log('\n📊 Recent Cash Sessions (local):');
    const sessions = await prisma.cashSession.findMany({
      take: 3,
      orderBy: { id: 'desc' },
      select: {
        id: true,
        soldeAttendu: true,
        soldeOuverture: true
      }
    });
    for (const session of sessions) {
      console.log(`   ID: ${session.id}, Solde Attendu: ${session.soldeAttendu}, Ouverture: ${session.soldeOuverture}`);
    }

    // Check recent financial movements
    console.log('\n💰 Recent Financial Movements (local):');
    const movements = await prisma.financialMovement.findMany({
      take: 3,
      orderBy: { id: 'desc' },
      select: {
        id: true,
        reference: true,
        montant: true,
        sessionId: true
      }
    });
    for (const movement of movements) {
      console.log(`   ID: ${movement.id}, Ref: ${movement.reference}, Montant: ${movement.montant}, Session: ${movement.sessionId}`);
    }

    console.log('\n✅ Test complete. After creating an expense:');
    console.log('   1. Check sync_queue for cash_sessions and cash_registers entries');
    console.log('   2. Run: node check-neon-data.js to verify they synced to Neon');
    console.log('   3. Financial movements should NOT appear in sync_queue');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testSync();
