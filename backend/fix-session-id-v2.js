/**
 * Fix session_id to be nullable - Version 2
 * Run: node fix-session-id-v2.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function fix() {
  try {
    console.log('🔧 Fixing session_id to be nullable (V2)...\n');

    // Get current schema
    const schema = await prisma.$executeRawUnsafe(`
      SELECT sql FROM sqlite_master WHERE type='table' AND name='financial_movements'
    `);
    
    console.log('Current CREATE TABLE statement:');
    console.log(schema[0]?.sql || 'Not found');
    console.log('');

    // Step 1: Rename old table
    console.log('Step 1: Renaming old table...');
    await prisma.$executeRawUnsafe(`ALTER TABLE financial_movements RENAME TO financial_movements_old`);

    // Step 2: Create new table with correct schema
    console.log('Step 2: Creating new table with nullable session_id...');
    await prisma.$executeRawUnsafe(`
      CREATE TABLE financial_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference TEXT NOT NULL UNIQUE,
        session_id INTEGER,
        boutique_id INTEGER,
        montant REAL NOT NULL,
        categorie_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        date DATETIME NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        notes TEXT
      )
    `);

    // Step 3: Copy data
    console.log('Step 3: Copying data...');
    await prisma.$executeRawUnsafe(`
      INSERT INTO financial_movements (id, reference, session_id, boutique_id, montant, categorie_id, description, date, utilisateur_id, date_creation, date_modification, notes)
      SELECT id, reference, session_id, boutique_id, montant, categorie_id, description, date, utilisateur_id, date_creation, date_modification, notes
      FROM financial_movements_old
    `);

    // Step 4: Drop old table
    console.log('Step 4: Dropping old table...');
    await prisma.$executeRawUnsafe(`DROP TABLE financial_movements_old`);

    // Step 5: Recreate indexes
    console.log('Step 5: Recreating indexes...');
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_reference ON financial_movements(reference)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_categorie ON financial_movements(categorie_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_utilisateur ON financial_movements(utilisateur_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_session ON financial_movements(session_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_boutique ON financial_movements(boutique_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_date ON financial_movements(date)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_montant ON financial_movements(montant)`);

    // Verify
    console.log('\nStep 6: Verifying...');
    const newSchema = await prisma.$queryRawUnsafe(`PRAGMA table_info(financial_movements)`);
    const sessionCol = newSchema.find(col => col.name === 'session_id');
    console.log(`session_id nullable: ${sessionCol.notnull === 0 ? '✅ YES' : '❌ NO'}`);

    console.log('\n✅ Done! Restart the backend and try creating a new expense.');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

fix();
