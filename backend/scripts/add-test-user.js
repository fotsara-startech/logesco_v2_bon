const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function addTestUser() {
  try {
    console.log('🚀 Ajout d\'un utilisateur de test...');

    // Créer un rôle admin
    const adminRole = await prisma.userRole.upsert({
      where: { nom: 'admin' },
      update: {},
      create: {
        nom: 'admin',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: JSON.stringify(['all'])
      }
    });

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash('admin123', 10);

    // Créer l'utilisateur admin
    const adminUser = await prisma.utilisateur.upsert({
      where: { nomUtilisateur: 'admin' },
      update: {},
      create: {
        nomUtilisateur: 'admin',
        email: 'admin@logesco.com',
        motDePasseHash: hashedPassword,
        roleId: adminRole.id,
        isActive: true
      }
    });

    console.log('✅ Utilisateur admin créé:');
    console.log('   - Nom d\'utilisateur: admin');
    console.log('   - Mot de passe: admin123');
    console.log('   - Email: admin@logesco.com');

  } catch (error) {
    console.error('❌ Erreur lors de l\'ajout de l\'utilisateur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addTestUser();