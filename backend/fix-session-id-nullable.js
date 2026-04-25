/**
 * Fix session_id to be nullable
 * Run: node fix-session-id-nullable.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function fix() {
  try {
    console.log('🔧 Fixing session_id to be nullable...\n');

    // SQLite doesn't support ALTER COLUMN, so we need to recreate the table
    console.log('Step 1: Creating backup table...');
    await prisma.$executeRawUnsafe(`
      CREATE TABLE financial_movements_backup AS SELECT * FROM financial_movements
    `);

    console.log('Step 2: Dropping original table...');
    await prisma.$executeRawUnsafe(`DROP TABLE financial_movements`);

    console.log('Step 3: Creating new table with nullable session_id...');
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
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES cash_sessions(id),
        FOREIGN KEY (boutique_id) REFERENCES boutiques(id),
        FOREIGN KEY (categorie_id) REFERENCES movement_categories(id),
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    `);

    console.log('Step 4: Restoring data...');
    await prisma.$executeRawUnsafe(`
      INSERT INTO financial_movements 
      SELECT * FROM financial_movements_backup
    `);

    console.log('Step 5: Dropping backup table...');
    await prisma.$executeRawUnsafe(`DROP TABLE financial_movements_backup`);

    console.log('Step 6: Recreating indexes...');
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_reference ON financial_movements(reference)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_categorie ON financial_movements(categorie_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_utilisateur ON financial_movements(utilisateur_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_session ON financial_movements(session_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_boutique ON financial_movements(boutique_id)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_date ON financial_movements(date)`);
    await prisma.$executeRawUnsafe(`CREATE INDEX idx_financial_movements_montant ON financial_movements(montant)`);

    console.log('\n✅ Done! session_id is now nullable.');
    console.log('   Restart the backend and try creating a new expense.');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

fix();
