/**
 * Script to verify table schemas using Prisma
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verifyTables() {
  try {
    // Check clients table
    console.log('=== TABLE: clients ===');
    const clientColumns = await prisma.$queryRaw`PRAGMA table_info(clients)`;
    console.log('Colonnes trouvées:');
    clientColumns.forEach(col => {
      console.log(`  - ${col.name} (${col.type})`);
    });
    
    const hasClientDateMod = clientColumns.some(col => col.name === 'date_modification');
    console.log(hasClientDateMod ? '✅ date_modification existe' : '❌ date_modification MANQUANTE');
    console.log('');

    // Check produits table
    console.log('=== TABLE: produits ===');
    const produitColumns = await prisma.$queryRaw`PRAGMA table_info(produits)`;
    console.log('Colonnes trouvées:');
    produitColumns.forEach(col => {
      console.log(`  - ${col.name} (${col.type})`);
    });
    
    const hasProduitDateMod = produitColumns.some(col => col.name === 'date_modification');
    console.log(hasProduitDateMod ? '✅ date_modification existe' : '❌ date_modification MANQUANTE');
    console.log('');

    // Check stock_boutiques table
    console.log('=== TABLE: stock_boutiques ===');
    const stockBoutiquesColumns = await prisma.$queryRaw`PRAGMA table_info(stock_boutiques)`;
    console.log('Colonnes trouvées:');
    stockBoutiquesColumns.forEach(col => {
      console.log(`  - ${col.name} (${col.type})`);
    });
    
    const hasStockDateMod = stockBoutiquesColumns.some(col => col.name === 'date_modification');
    console.log(hasStockDateMod ? '✅ date_modification existe' : '❌ date_modification MANQUANTE');

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

verifyTables();
