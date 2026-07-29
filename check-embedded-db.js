/**
 * Vérification directe de la base embarquée
 */

const path = require('path');
const { PrismaClient } = require('@prisma/client');

// Forcer l'utilisation de la base embarquée
const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'logesco.db');
const databaseUrl = `file:${dbPath}`;

console.log('📂 Base de données:', dbPath);
console.log('📂 URL:', databaseUrl);

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
    
    // Vérifier comptes_clients
    console.log('\n=== TABLE comptes_clients ===');
    const comptesColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_clients)`;
    console.log('Colonnes:');
    comptesColumns.forEach(col => console.log(`  ${col.name} (${col.type})`));

    // Essayer une requête qui échoue selon les logs
    console.log('\n=== Test requête produits ===');
    try {
      const produits = await prisma.produit.findMany({
        take: 1,
        include: { stock: true }
      });
      console.log('✅ Requête réussie, nombre de produits:', produits.length);
    } catch (error) {
      console.error('❌ Erreur requête:', error.message);
    }

    console.log('\n=== Test requête clients ===');
    try {
      const clients = await prisma.client.findMany({
        take: 1,
        include: { compte: true }
      });
      console.log('✅ Requête réussie, nombre de clients:', clients.length);
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
