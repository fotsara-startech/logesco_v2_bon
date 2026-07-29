/**
 * Script de migration manuelle pour ajouter les colonnes nui et rccm
 * à la table clients (SQLite)
 * 
 * À exécuter chez les clients qui n'ont pas ces colonnes
 */

const { PrismaClient } = require('@prisma/client');
const path = require('path');

async function addNuiRccmColumns() {
  console.log('╔═══════════════════════════════════════════════════════════════╗');
  console.log('║   MIGRATION: Ajout colonnes NUI et RCCM aux clients         ║');
  console.log('╚═══════════════════════════════════════════════════════════════╝\n');

  // Initialiser Prisma avec la base de données locale
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: `file:${path.join(__dirname, 'database', 'logesco.db')}`
      }
    }
  });

  try {
    // Vérifier si les colonnes existent déjà
    console.log('🔍 Vérification de la structure de la table clients...\n');
    
    const tableInfo = await prisma.$queryRawUnsafe(`
      PRAGMA table_info(clients);
    `);
    
    console.log('📋 Colonnes actuelles:');
    tableInfo.forEach(col => {
      console.log(`   - ${col.name} (${col.type})`);
    });
    
    const hasNui = tableInfo.some(col => col.name === 'nui');
    const hasRccm = tableInfo.some(col => col.name === 'rccm');
    
    console.log('\n📊 État des colonnes:');
    console.log(`   - nui:  ${hasNui ? '✅ Existe déjà' : '❌ Manquante'}`);
    console.log(`   - rccm: ${hasRccm ? '✅ Existe déjà' : '❌ Manquante'}`);
    
    if (hasNui && hasRccm) {
      console.log('\n✅ Les colonnes existent déjà, aucune migration nécessaire.');
      return;
    }
    
    console.log('\n🔧 Application de la migration...\n');
    
    // Ajouter la colonne nui si elle n'existe pas
    if (!hasNui) {
      try {
        await prisma.$executeRawUnsafe(`
          ALTER TABLE clients ADD COLUMN nui TEXT;
        `);
        console.log('✅ Colonne "nui" ajoutée avec succès');
      } catch (error) {
        if (error.message.includes('duplicate column')) {
          console.log('ℹ️ Colonne "nui" existe déjà');
        } else {
          throw error;
        }
      }
    }
    
    // Ajouter la colonne rccm si elle n'existe pas
    if (!hasRccm) {
      try {
        await prisma.$executeRawUnsafe(`
          ALTER TABLE clients ADD COLUMN rccm TEXT;
        `);
        console.log('✅ Colonne "rccm" ajoutée avec succès');
      } catch (error) {
        if (error.message.includes('duplicate column')) {
          console.log('ℹ️ Colonne "rccm" existe déjà');
        } else {
          throw error;
        }
      }
    }
    
    // Vérifier le résultat
    console.log('\n🔍 Vérification après migration...\n');
    const tableInfoAfter = await prisma.$queryRawUnsafe(`
      PRAGMA table_info(clients);
    `);
    
    const hasNuiAfter = tableInfoAfter.some(col => col.name === 'nui');
    const hasRccmAfter = tableInfoAfter.some(col => col.name === 'rccm');
    
    console.log('📊 Colonnes après migration:');
    console.log(`   - nui:  ${hasNuiAfter ? '✅' : '❌'}`);
    console.log(`   - rccm: ${hasRccmAfter ? '✅' : '❌'}`);
    
    if (hasNuiAfter && hasRccmAfter) {
      console.log('\n╔═══════════════════════════════════════════════════════════════╗');
      console.log('║               ✅ MIGRATION RÉUSSIE !                         ║');
      console.log('╚═══════════════════════════════════════════════════════════════╝\n');
      console.log('✓ Les colonnes nui et rccm ont été ajoutées à la table clients');
      console.log('✓ Vous pouvez maintenant redémarrer le backend');
    } else {
      console.log('\n❌ La migration a échoué. Colonnes manquantes.');
    }
    
  } catch (error) {
    console.error('\n❌ Erreur lors de la migration:', error);
    console.error('\nDétails:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration
addNuiRccmColumns()
  .then(() => {
    console.log('\n✓ Script terminé');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Erreur fatale:', error);
    process.exit(1);
  });
