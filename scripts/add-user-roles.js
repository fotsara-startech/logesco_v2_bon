const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function addUserRoles() {
  try {
    console.log('🔐 Ajout des rôles utilisateur...');

    // Définir les rôles avec leurs privilèges
    const roles = [
      {
        nom: 'admin',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: JSON.stringify(['all'])
      },
      {
        nom: 'manager',
        displayName: 'Gestionnaire',
        isAdmin: false,
        privileges: JSON.stringify([
          'canManageProducts',
          'canManageSales',
          'canManageInventory',
          'canViewReports',
          'canManageStock'
        ])
      },
      {
        nom: 'vendeur',
        displayName: 'Vendeur',
        isAdmin: false,
        privileges: JSON.stringify([
          'canMakeSales',
          'canViewReports'
        ])
      },
      {
        nom: 'magasinier',
        displayName: 'Magasinier',
        isAdmin: false,
        privileges: JSON.stringify([
          'canManageInventory',
          'canManageStock',
          'canManageProducts'
        ])
      },
      {
        nom: 'comptable',
        displayName: 'Comptable',
        isAdmin: false,
        privileges: JSON.stringify([
          'canViewReports',
          'canManageReports',
          'canManageCompanySettings'
        ])
      },
      {
        nom: 'user',
        displayName: 'Utilisateur',
        isAdmin: false,
        privileges: JSON.stringify([
          'canViewReports'
        ])
      }
    ];

    for (const role of roles) {
      const existingRole = await prisma.userRole.findUnique({
        where: { nom: role.nom }
      });

      if (existingRole) {
        // Mettre à jour le rôle existant
        await prisma.userRole.update({
          where: { nom: role.nom },
          data: role
        });
        console.log(`✅ Rôle mis à jour: ${role.displayName}`);
      } else {
        // Créer un nouveau rôle
        await prisma.userRole.create({
          data: role
        });
        console.log(`✅ Rôle créé: ${role.displayName}`);
      }
    }

    // Vérifier les rôles créés
    const allRoles = await prisma.userRole.findMany();
    console.log(`\n📊 Total des rôles: ${allRoles.length}`);
    allRoles.forEach(role => {
      console.log(`   - ${role.displayName} (${role.nom}) - Admin: ${role.isAdmin}`);
    });

    console.log('\n🎉 Rôles utilisateur ajoutés avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors de l\'ajout des rôles:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addUserRoles();