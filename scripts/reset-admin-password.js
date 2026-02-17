const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function resetAdminPassword() {
  try {
    console.log('🔑 Réinitialisation du mot de passe admin...');

    // Chercher l'utilisateur admin
    const adminUser = await prisma.utilisateur.findFirst({
      where: { nomUtilisateur: 'admin' }
    });

    if (!adminUser) {
      console.error('❌ Utilisateur admin non trouvé');
      process.exit(1);
    }

    // Hash du nouveau mot de passe
    const newPassword = 'admin123';
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Mettre à jour le mot de passe
    await prisma.utilisateur.update({
      where: { id: adminUser.id },
      data: { motDePasseHash: hashedPassword }
    });

    console.log('✅ Mot de passe réinitialisé avec succès!');
    console.log('');
    console.log('🔐 Identifiants:');
    console.log(`   Nom d'utilisateur: admin`);
    console.log(`   Mot de passe: ${newPassword}`);
    console.log('');
    console.log('Vous pouvez maintenant vous connecter!');

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

resetAdminPassword();
