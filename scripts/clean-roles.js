const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function cleanRoles() {
  try {
    console.log('🧹 Nettoyage complet des rôles et utilisateurs...');

    // 1. Désactiver temporairement les contraintes de clé étrangère
    await prisma.$executeRaw`PRAGMA foreign_keys = OFF`;
    
    // 2. Supprimer tous les utilisateurs
    await prisma.$executeRaw`DELETE FROM utilisateurs`;
    console.log(`✅ Utilisateurs supprimés`);

    // 3. Supprimer tous les rôles
    await prisma.$executeRaw`DELETE FROM user_roles`;
    console.log(`✅ Rôles supprimés`);
    
    // 4. Réactiver les contraintes de clé étrangère
    await prisma.$executeRaw`PRAGMA foreign_keys = ON`;

    // 3. Réinitialiser les compteurs auto-increment
    await prisma.$executeRaw`DELETE FROM sqlite_sequence WHERE name IN ('utilisateurs', 'user_roles')`;
    console.log('✅ Compteurs auto-increment réinitialisés');

    console.log('\n🎉 Base de données nettoyée avec succès !');
    console.log('📝 Vous pouvez maintenant créer vos rôles et utilisateurs via l\'interface');

  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  cleanRoles()
    .then(() => {
      console.log('✨ Nettoyage terminé');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec du nettoyage:', error);
      process.exit(1);
    });
}

module.exports = { cleanRoles };