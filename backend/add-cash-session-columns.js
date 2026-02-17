const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function addColumns() {
  try {
    console.log('🔧 Ajout des colonnes solde_attendu et ecart...');
    
    // Vérifier si les colonnes existent déjà
    const result = await prisma.$queryRaw`PRAGMA table_info(cash_sessions)`;
    console.log('Colonnes actuelles:', result.map(r => r.name));
    
    const hassoldeAttendu = result.some(r => r.name === 'solde_attendu');
    const hasEcart = result.some(r => r.name === 'ecart');
    
    if (!hassoldeAttendu) {
      console.log('➕ Ajout de la colonne solde_attendu...');
      await prisma.$executeRawUnsafe('ALTER TABLE cash_sessions ADD COLUMN solde_attendu REAL');
      console.log('✅ Colonne solde_attendu ajoutée');
    } else {
      console.log('ℹ️  La colonne solde_attendu existe déjà');
    }
    
    if (!hasEcart) {
      console.log('➕ Ajout de la colonne ecart...');
      await prisma.$executeRawUnsafe('ALTER TABLE cash_sessions ADD COLUMN ecart REAL');
      console.log('✅ Colonne ecart ajoutée');
    } else {
      console.log('ℹ️  La colonne ecart existe déjà');
    }
    
    // Vérifier les colonnes après ajout
    const resultAfter = await prisma.$queryRaw`PRAGMA table_info(cash_sessions)`;
    console.log('\n📋 Colonnes finales:', resultAfter.map(r => r.name));
    
    console.log('\n✅ Migration terminée avec succès!');
  } catch (error) {
    console.error('❌ Erreur lors de l\'ajout des colonnes:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

addColumns();
