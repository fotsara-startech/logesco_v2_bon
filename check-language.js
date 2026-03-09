const { PrismaClient } = require('./src/config/prisma-client.js');

async function checkLanguage() {
  const prisma = new PrismaClient();
  
  try {
    const settings = await prisma.parametresEntreprise.findFirst();
    
    if (settings) {
      console.log('✅ Paramètres entreprise trouvés:');
      console.log('  Nom:', settings.nomEntreprise);
      console.log('  Langue facture:', settings.langueFacture);
    } else {
      console.log('❌ Aucun paramètre entreprise trouvé');
    }
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkLanguage();
