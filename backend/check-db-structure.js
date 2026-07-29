const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${process.env.LOCALAPPDATA}/LOGESCO/backend/database/logesco.db`
    }
  }
});

async function checkStructure() {
  try {
    console.log('📂 DB:', `${process.env.LOCALAPPDATA}/LOGESCO/backend/database/logesco.db`);
    
    const result = await prisma.$queryRawUnsafe("PRAGMA table_info(clients)");
    
    console.log('\n📋 Structure de la table clients:');
    result.forEach(row => {
      console.log(`  ${row.name} (${row.type})`);
    });
    
    const hasNui = result.some(r => r.name === 'nui');
    const hasRccm = result.some(r => r.name === 'rccm');
    const hasNuiRccm = result.some(r => r.name === 'nui_rccm');
    
    console.log('\n🔍 Vérification des colonnes:');
    console.log(`  - nui: ${hasNui ? '✅' : '❌'}`);
    console.log(`  - rccm: ${hasRccm ? '✅' : '❌'}`);
    console.log(`  - nui_rccm: ${hasNuiRccm ? '✅' : '❌'}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkStructure();
