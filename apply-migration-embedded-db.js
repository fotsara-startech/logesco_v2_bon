/**
 * Migration complète pour la base de données embarquée
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

async function applyMigrations() {
  try {
    console.log('🔧 Démarrage des migrations...\n');

    // 1. Ajouter date_modification à stock
    console.log('=== Migration table stock ===');
    const stockColumns = await prisma.$queryRaw`PRAGMA table_info(stock)`;
    const hasStockDateMod = stockColumns.some(col => col.name === 'date_modification');
    
    if (!hasStockDateMod) {
      console.log('Ajout de date_modification à stock...');
      await prisma.$executeRaw`ALTER TABLE stock ADD COLUMN date_modification DATETIME`;
      console.log('✅ Colonne date_modification ajoutée à stock');
    } else {
      console.log('✅ date_modification existe déjà dans stock');
    }

    // 2. Ajouter date_modification à comptes_clients
    console.log('\n=== Migration table comptes_clients ===');
    const comptesClientsColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_clients)`;
    const hasComptesClientsDateMod = comptesClientsColumns.some(col => col.name === 'date_modification');
    
    if (!hasComptesClientsDateMod) {
      console.log('Ajout de date_modification à comptes_clients...');
      await prisma.$executeRaw`ALTER TABLE comptes_clients ADD COLUMN date_modification DATETIME`;
      console.log('✅ Colonne date_modification ajoutée à comptes_clients');
    } else {
      console.log('✅ date_modification existe déjà dans comptes_clients');
    }

    // 3. Ajouter date_modification à comptes_fournisseurs
    console.log('\n=== Migration table comptes_fournisseurs ===');
    const comptesFournColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_fournisseurs)`;
    const hasComptesFournDateMod = comptesFournColumns.some(col => col.name === 'date_modification');
    
    if (!hasComptesFournDateMod) {
      console.log('Ajout de date_modification à comptes_fournisseurs...');
      await prisma.$executeRaw`ALTER TABLE comptes_fournisseurs ADD COLUMN date_modification DATETIME`;
      console.log('✅ Colonne date_modification ajoutée à comptes_fournisseurs');
    } else {
      console.log('✅ date_modification existe déjà dans comptes_fournisseurs');
    }

    // 4. Ajouter image_url à produits si manquante
    console.log('\n=== Migration table produits ===');
    const produitsColumns = await prisma.$queryRaw`PRAGMA table_info(produits)`;
    const hasImageUrl = produitsColumns.some(col => col.name === 'image_url');
    
    if (!hasImageUrl) {
      console.log('Ajout de image_url à produits...');
      await prisma.$executeRaw`ALTER TABLE produits ADD COLUMN image_url TEXT`;
      console.log('✅ Colonne image_url ajoutée à produits');
    } else {
      console.log('✅ image_url existe déjà dans produits');
    }

    console.log('\n=== Vérification finale ===');
    
    // Test requête produits
    try {
      const produits = await prisma.produit.findMany({ take: 1, include: { stock: true } });
      console.log('✅ Requête produits réussie');
    } catch (error) {
      console.error('❌ Requête produits échouée:', error.message);
    }

    // Test requête clients
    try {
      const clients = await prisma.client.findMany({ take: 1, include: { compte: true } });
      console.log('✅ Requête clients réussie');
    } catch (error) {
      console.error('❌ Requête clients échouée:', error.message);
    }

    console.log('\n✅ Migrations terminées avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors des migrations:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

applyMigrations();
