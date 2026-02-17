/**
 * Script de nettoyage des utilisateurs de test
 * Supprime les utilisateurs créés pendant les tests
 */

const { PrismaClient } = require('@prisma/client');

async function cleanupTestUsers() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🧹 Nettoyage des utilisateurs de test...');
    
    await prisma.$connect();
    
    // Supprimer les utilisateurs de test
    const result = await prisma.utilisateur.deleteMany({
      where: {
        OR: [
          { nomUtilisateur: { contains: 'test' } },
          { email: { contains: 'test' } },
          { email: { contains: 'logesco.com' } }
        ]
      }
    });
    
    console.log(`✅ ${result.count} utilisateurs de test supprimés`);
    
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  cleanupTestUsers()
    .then(() => {
      console.log('🎉 Nettoyage terminé');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec du nettoyage:', error);
      process.exit(1);
    });
}

module.exports = { cleanupTestUsers };