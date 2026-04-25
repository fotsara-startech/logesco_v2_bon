/**
 * Check the CORRECT database
 * Run: node check-correct-db.js
 */

const sqlite3 = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'prisma', 'database', 'logesco.db');
console.log(`🔍 Checking database: ${dbPath}\n`);

try {
  const db = sqlite3(dbPath, { readonly: true });
  
  const movements = db.prepare(`
    SELECT id, reference, session_id, boutique_id, montant, description
    FROM financial_movements
    ORDER BY id DESC
    LIMIT 5
  `).all();

  console.log('📋 Last 5 Financial Movements:');
  for (const mov of movements) {
    const sessionStatus = mov.session_id ? `✅ ${mov.session_id}` : '❌ NULL';
    console.log(`   ID: ${mov.id}, Ref: ${mov.reference}, Session: ${sessionStatus}, Boutique: ${mov.boutique_id}`);
  }

  db.close();
} catch (error) {
  console.error('❌ Error:', error.message);
  console.log('\nTrying to install better-sqlite3...');
  console.log('Run: npm install better-sqlite3');
}
