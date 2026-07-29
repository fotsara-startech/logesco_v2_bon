require('dotenv').config();

// Utiliser le client Prisma du backend embarqué
const { PrismaClient } = require(`${process.env.LOCALAPPDATA}/LOGESCO/backend/node_modules/@prisma/client`);

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${process.env.LOCALAPPDATA}/LOGESCO/backend/database/logesco.db`
    }
  }
});

async function test() {
  try {
    console.log('🧪 Test création client avec nui et rccm...');
    
    const client = await prisma.client.create({
      data: {
        nom: 'TEST_NUI_RCCM',
        nui: 'NUI123TEST',
        rccm: 'RCCM456TEST'
      }
    });
    
    console.log('✅ Client créé:', JSON.stringify(client, null, 2));
    
    // Nettoyer
    await prisma.client.delete({ where: { id: client.id } });
    console.log('🗑️ Client de test supprimé');
    
  } catch(e) {
    console.error('❌ ERREUR:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

test();
