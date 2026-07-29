/**
 * Vérification de la VRAIE base embarquée
 */

const path = require('path');
const { PrismaClient } = require('@prisma/client');

// La vraie base utilisée par le backend embarqué
const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');
const databaseUrl = `file:${dbPath}`;

console.log('📂 Base de données:', dbPath);

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseUrl
    }
  }
});

async function checkDatabase() {
  try {
    // Vérifier stock
    console.log('\n=== TABLE stock ===');
    const stockColumns = await prisma.$queryRaw`PRAGMA table_info(stock)`;
    console.log('Colonnes:');
    stockColumns.forEach(col => console.log(`  ${col.name} (${col.type})`));
    const hasStockDateMod = stockColumns.some(col => col.name === 'date_modification');
    console.log(hasStockDateMod ? '✅ date_modification existe' : '❌ date_modification MANQUANTE');
    
    // Vérifier comptes_clients
    console.log('\n=== TABLE comptes_clients ===');
    const comptesColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_clients)`;
    console.log('Colonnes:');
    comptesColumns.forEach(col => console.log(`  ${col.name} (${col.type})`));
    const hasComptesDateMod = comptesColumns.some(col => col.name === 'date_modification');
    console.log(hasComptesDateMod ? '✅ date_modification existe' : '❌ date_modification MANQUANTE');

    // Essayer une requête qui échoue selon les logs
    console.log('\n=== Test requête produits ===');
    try {
      const produits = await prisma.produit.findMany({
        take: 2,
        include: { stock: true }
      });
      console.log('✅ Requête réussie, nombre de produits:', produits.length);
      if (produits.length > 0) {
        console.log('Premier produit:', produits[0].nom);
      }
    } catch (error) {
      console.error('❌ Erreur requête:', error.message);
    }

    console.log('\n=== Test requête clients ===');
    try {
      const clients = await prisma.client.findMany({
        take: 2,
        include: { compte: true }
      });
      console.log('✅ Requête réussie, nombre de clients:', clients.length);
      if (clients.length > 0) {
        console.log('Premier client:', clients[0].nom);
      }
    } catch (error) {
      console.error('❌ Erreur requête:', error.message);
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkDatabase();
