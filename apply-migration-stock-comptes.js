/**
 * Migration pour ajouter date_modification aux tables stock et comptes_clients
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function applyMigration() {
  try {
    console.log('🔧 Démarrage de la migration...');

    // Vérifier la table stock
    console.log('\n=== Vérification table stock ===');
    const stockColumns = await prisma.$queryRaw`PRAGMA table_info(stock)`;
    const hasStockDateMod = stockColumns.some(col => col.name === 'date_modification');
    console.log('Colonne date_modification dans stock:', hasStockDateMod ? '✅ Existe' : '❌ Manquante');

    if (!hasStockDateMod) {
      console.log('Ajout de date_modification à la table stock...');
      await prisma.$executeRaw`
        ALTER TABLE stock ADD COLUMN date_modification DATETIME;
      `;
      console.log('✅ Colonne date_modification ajoutée à stock');
    }

    // Vérifier la table comptes_clients
    console.log('\n=== Vérification table comptes_clients ===');
    const comptesColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_clients)`;
    const hasComptesDateMod = comptesColumns.some(col => col.name === 'date_modification');
    console.log('Colonne date_modification dans comptes_clients:', hasComptesDateMod ? '✅ Existe' : '❌ Manquante');

    if (!hasComptesDateMod) {
      console.log('Ajout de date_modification à la table comptes_clients...');
      await prisma.$executeRaw`
        ALTER TABLE comptes_clients ADD COLUMN date_modification DATETIME;
      `;
      console.log('✅ Colonne date_modification ajoutée à comptes_clients');
    }

    // Vérifier la table comptes_fournisseurs aussi
    console.log('\n=== Vérification table comptes_fournisseurs ===');
    const comptesFournColumns = await prisma.$queryRaw`PRAGMA table_info(comptes_fournisseurs)`;
    const hasComptesFournDateMod = comptesFournColumns.some(col => col.name === 'date_modification');
    console.log('Colonne date_modification dans comptes_fournisseurs:', hasComptesFournDateMod ? '✅ Existe' : '❌ Manquante');

    if (!hasComptesFournDateMod) {
      console.log('Ajout de date_modification à la table comptes_fournisseurs...');
      await prisma.$executeRaw`
        ALTER TABLE comptes_fournisseurs ADD COLUMN date_modification DATETIME;
      `;
      console.log('✅ Colonne date_modification ajoutée à comptes_fournisseurs');
    }

    console.log('\n✅ Migration terminée avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

applyMigration();
