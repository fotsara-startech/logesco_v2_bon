#!/usr/bin/env node

/**
 * Validation des migrations de schéma
 * Vérifie que toutes les colonnes date_modification existent
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function validateSchema() {
  console.log('🔍 Validation du schéma...\n');

  const tablesToCheck = [
    { table: 'transactions_comptes', columns: ['id', 'date_transaction', 'date_modification'] },
    { table: 'stock_inventories', columns: ['id', 'date_creation', 'date_modification'] },
    { table: 'inventory_items', columns: ['id', 'date_comptage', 'date_modification'] },
    { table: 'comptes_fournisseurs', columns: ['id', 'date_derniere_maj'] },
    { table: 'comptes_clients', columns: ['id', 'date_derniere_maj'] },
  ];

  let hasErrors = false;

  for (const { table, columns } of tablesToCheck) {
    try {
      const query = `PRAGMA table_info(${table})`;
      const info = await prisma.$queryRawUnsafe(query);
      
      console.log(`✅ Table: ${table}`);
      
      const existingCols = info.map(col => col.name);
      
      for (const col of columns) {
        if (existingCols.includes(col)) {
          console.log(`   ✓ ${col}`);
        } else {
          console.log(`   ✗ ${col} - MANQUANTE`);
          hasErrors = true;
        }
      }
      
      console.log('');
    } catch (e) {
      console.error(`❌ Erreur ${table}:`, e.message);
      hasErrors = true;
    }
  }

  if (!hasErrors) {
    console.log('✅ Toutes les migrations sont appliquées correctement!');
    process.exit(0);
  } else {
    console.log('❌ Des colonnes sont manquantes. Appliquez les migrations:');
    console.log('   npx prisma migrate deploy');
    process.exit(1);
  }
}

validateSchema()
  .catch(e => {
    console.error('❌ Erreur validation:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
