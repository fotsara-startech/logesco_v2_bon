process.env.DATABASE_URL = 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const prisma = getPrismaClient();

// Simuler exactement ce que fait la route POST /boutiques
async function testRoute() {
  try {
    // Simuler req.user.id = 1 (admin)
    const userId = 1;
    
    // isAdminUser
    const user = await prisma.utilisateur.findUnique({
      where: { id: userId },
      include: { role: true }
    });
    console.log('User:', user?.nomUtilisateur, '| isAdmin:', user?.role?.isAdmin);
    
    const isAdmin = user?.role?.isAdmin === true;
    if (!isAdmin) {
      console.log('❌ Pas admin');
      return;
    }
    
    // Créer boutique
    const boutique = await prisma.boutique.create({
      data: {
        nom: 'BEDIMED SARL',
        adresse: 'douala, deido',
        telephone: '698745120',
        email: 'bedimed@logesco.com',
        description: null,
        estPrincipale: false,
        isActive: true
      }
    });
    
    console.log('✅ Boutique créée:', JSON.stringify(boutique));
    
    // Nettoyer
    await prisma.boutique.delete({ where: { id: boutique.id } });
    console.log('🧹 Boutique de test supprimée');
    
  } catch(e) {
    console.error('❌ Erreur:', e.message);
    console.error(e.stack);
  } finally {
    await prisma.$disconnect();
    process.exit(0);
  }
}

testRoute();
