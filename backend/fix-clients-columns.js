/**
 * Ajoute les colonnes manquantes dans clients et fournisseurs
 */
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');
const prisma = new PrismaClient({ datasources: { db: { url: 'file:' + dbPath } } });

const migrations = [
  ['clients', 'nui', 'TEXT'],
  ['clients', 'rccm', 'TEXT'],
  ['fournisseurs', 'nui', 'TEXT'],
  ['fournisseurs', 'rccm', 'TEXT'],
];

async function run() {
  console.log('📂 DB:', dbPath);
  for (const [table, col, type] of migrations) {
    try {
      await prisma.$executeRawUnsafe(`ALTER TABLE "${table}" ADD COLUMN "${col}" ${type}`);
      console.log(`✅ ${table}.${col} ajoutée`);
    } catch(e) {
      if (e.message.includes('duplicate column')) {
        console.log(`⏭  ${table}.${col} existe déjà`);
      } else {
        console.log(`❌ ${table}.${col}: ${e.message.split('\n')[0]}`);
      }
    }
  }

  // Test final
  console.log('\n=== Tests ===');
  try {
    await prisma.client.findFirst();
    console.log('✅ clients OK');
  } catch(e) {
    // Extraire la colonne manquante du message
    const m = e.message.match(/column `([^`]+)`/);
    console.log('❌ clients:', m ? m[0] : e.message.substring(0, 100));
  }

  try {
    await prisma.fournisseur.findFirst();
    console.log('✅ fournisseurs OK');
  } catch(e) {
    const m = e.message.match(/column `([^`]+)`/);
    console.log('❌ fournisseurs:', m ? m[0] : e.message.substring(0, 100));
  }

  try {
    await prisma.commandeApprovisionnement.findFirst();
    console.log('✅ commandes_approvisionnement OK');
  } catch(e) {
    const m = e.message.match(/column `([^`]+)`/);
    console.log('❌ commandes:', m ? m[0] : e.message.substring(0, 100));
  }

  try {
    await prisma.stockInventory.findFirst();
    console.log('✅ stock_inventories OK');
  } catch(e) {
    const m = e.message.match(/column `([^`]+)`/);
    console.log('❌ stock_inventories:', m ? m[0] : e.message.substring(0, 100));
  }

  await prisma.$disconnect();
}

run().catch(e => { console.error(e); process.exit(1); });
