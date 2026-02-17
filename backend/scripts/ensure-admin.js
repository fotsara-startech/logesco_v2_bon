const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function ensureAdminExists() {
  try {
    console.log('🔍 Vérification de l\'existence de l\'utilisateur admin...');

    // 1. Vérifier si le rôle admin existe
    let adminRole = await prisma.userRole.findFirst({
      where: { nom: 'admin' }
    });

    if (!adminRole) {
      console.log('📝 Création du rôle admin...');
      adminRole = await prisma.userRole.create({
        data: {
          nom: 'admin',
          displayName: 'Administrateur',
          isAdmin: true,
          privileges: JSON.stringify({
            users: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
            products: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
            sales: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
            inventory: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'ADJUST'],
            reports: ['READ', 'EXPORT'],
            company_settings: ['UPDATE'],
            cash_registers: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
            dashboard: ['STATS'],
            stock_inventory: ['COUNT'],
            financial_movements: ['CREATE', 'READ', 'UPDATE', 'DELETE']
          })
        }
      });
      console.log('✅ Rôle admin créé avec ID:', adminRole.id);
    } else {
      console.log('✅ Rôle admin existe déjà avec ID:', adminRole.id);
    }

    // 2. Vérifier si l'utilisateur admin existe
    let adminUser = await prisma.utilisateur.findFirst({
      where: { nomUtilisateur: 'admin' }
    });

    if (!adminUser) {
      console.log('👤 Création de l\'utilisateur admin...');
      
      // Hash du mot de passe "admin123"
      const hashedPassword = await bcrypt.hash('admin123', 10);
      
      adminUser = await prisma.utilisateur.create({
        data: {
          nomUtilisateur: 'admin',
          email: 'admin@logesco.com',
          motDePasseHash: hashedPassword,
          roleId: adminRole.id,
          isActive: true
        }
      });
      console.log('✅ Utilisateur admin créé avec ID:', adminUser.id);
      console.log('🔑 Identifiants: admin / admin123');
    } else {
      console.log('✅ Utilisateur admin existe déjà avec ID:', adminUser.id);
      
      // Vérifier que l'utilisateur admin a bien le bon rôle
      if (adminUser.roleId !== adminRole.id) {
        console.log('🔄 Mise à jour du rôle de l\'utilisateur admin...');
        await prisma.utilisateur.update({
          where: { id: adminUser.id },
          data: { roleId: adminRole.id }
        });
        console.log('✅ Rôle de l\'utilisateur admin mis à jour');
      }
    }

    console.log('\n🎉 Utilisateur admin disponible !');
    console.log('📋 Résumé:');
    console.log(`   - Nom d'utilisateur: admin`);
    console.log(`   - Mot de passe: admin123`);
    console.log(`   - Email: admin@logesco.com`);
    console.log(`   - Rôle: ${adminRole.displayName}`);
    console.log(`   - Privilèges: Administrateur complet`);

  } catch (error) {
    console.error('❌ Erreur lors de la vérification/création de l\'admin:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  ensureAdminExists()
    .then(() => {
      console.log('✨ Vérification admin terminée');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la vérification admin:', error);
      process.exit(1);
    });
}

module.exports = { ensureAdminExists };