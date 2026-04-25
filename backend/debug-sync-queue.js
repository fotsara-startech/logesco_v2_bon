/**
 * Debug script to see what's in the sync queue
 * Run: node debug-sync-queue.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function debugQueue() {
  try {
    console.log('🔍 Debugging Sync Queue...\n');

    // Get all pending items
    const pending = await prisma.$queryRawUnsafe(
      `SELECT * FROM sync_queue WHERE synced = 0 ORDER BY id DESC LIMIT 10`
    );

    if (pending.length === 0) {
      console.log('✅ Queue is empty (all synced)');
    } else {
      console.log(`📋 Found ${pending.length} pending items:\n`);
      
      for (const item of pending) {
        console.log(`─────────────────────────────────────────`);
        console.log(`ID: ${item.id}`);
        console.log(`Table: ${item.table_name}`);
        console.log(`Operation: ${item.operation}`);
        console.log(`Record ID: ${item.record_id}`);
        console.log(`Created: ${item.created_at}`);
        console.log(`Synced: ${item.synced}`);
        console.log(`Error: ${item.error || 'None'}`);
        
        // Parse and show data
        try {
          const data = JSON.parse(item.data);
          console.log(`Data keys: ${Object.keys(data).join(', ')}`);
          console.log(`Data preview:`, JSON.stringify(data).substring(0, 200));
        } catch (e) {
          console.log(`Data: ${item.data}`);
        }
        console.log('');
      }
    }

    // Show all items (synced and pending)
    const all = await prisma.$queryRawUnsafe(
      `SELECT table_name, operation, synced, COUNT(*) as count 
       FROM sync_queue 
       GROUP BY table_name, operation, synced 
       ORDER BY table_name, operation`
    );

    console.log('\n📊 Queue Summary:');
    for (const row of all) {
      const status = row.synced === 1 ? '✅ synced' : '⏳ pending';
      console.log(`   ${row.table_name} (${row.operation}): ${row.count} ${status}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

debugQueue();
