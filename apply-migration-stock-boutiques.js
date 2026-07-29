/**
 * Script pour appliquer la migration date_modification à stock_boutiques
 */

const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

async function applyMigration() {
  const prisma = new PrismaClient();
  
  try {
    console.log('📊 Application de la migration date_modification...');
    
    // Appliquer directement les 3 commandes SQL sans parser le fichier
    console.log('1. Ajout de la colonne date_modification...');
    await prisma.$executeRawUnsafe(`ALTER TABLE stock_boutiques ADD COLUMN date_modification TEXT`);
    console.log('  ✅ Colonne ajoutée');
    
    console.log('2. Création de l index...');
    await prisma.$executeRawUnsafe(`CREATE INDEX IF NOT EXISTS idx_stock_boutique_date_modification ON stock_boutiques(date_modification)`);
    console.log('  ✅ Index créé');
    
    console.log('3. Initialisation des valeurs...');
    await prisma.$executeRawUnsafe(`UPDATE stock_boutiques SET date_modification = derniere_maj WHERE date_modification IS NULL`);
    console.log('  ✅ Valeurs initialisées');
    
    console.log('✅ Migration appliquée avec succès');
    
    // Vérifier que la colonne existe
    const result = await prisma.$queryRaw`
      SELECT name FROM pragma_table_info('stock_boutiques') WHERE name = 'date_modification'
    `;
    
    if (result.length > 0) {
      console.log('✅ Colonne date_modification confirmée dans stock_boutiques');
    } else {
      console.log('⚠️  Colonne non trouvée après migration');
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

applyMigration();
