const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function ensureAdminAndCash() {
  try {
    console.log('🚀 Initialisation des données essentielles...');
    console.log('=' .repeat(60));

    // 1. Vérifier/Créer le rôle admin
    console.log('\n📋 Étape 1: Vérification du rôle admin...');
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

    // 2. Vérifier/Créer l'utilisateur admin
    console.log('\n👤 Étape 2: Vérification de l\'utilisateur admin...');
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

    // 3. Vérifier/Créer la caisse principale
    console.log('\n💵 Étape 3: Vérification de la caisse principale...');
    let caisseExistante = await prisma.cashRegister.findFirst({
      where: { nom: 'Caisse Principale' }
    });

    if (!caisseExistante) {
      console.log('💵 Création de la caisse principale...');
      
      const caisseData = {
        nom: 'Caisse Principale',
        description: 'Caisse principale créée automatiquement lors de l\'initialisation',
        soldeInitial: 0.0,
        soldeActuel: 0.0,
        isActive: true,
        dateOuverture: new Date(),
        utilisateurId: adminUser.id
      };
      
      const caisse = await prisma.cashRegister.create({
        data: caisseData
      });
      
      // Créer un mouvement d'ouverture
      await prisma.cashMovement.create({
        data: {
          caisseId: caisse.id,
          type: 'ouverture',
          montant: 0.0,
          description: 'Ouverture automatique de la caisse principale',
          utilisateurId: adminUser.id,
          metadata: JSON.stringify({ 
            source: 'auto_creation',
            created_at: new Date().toISOString(),
            created_by: 'system'
          })
        }
      });
      
      console.log('✅ Caisse principale créée avec ID:', caisse.id);
      caisseExistante = caisse;
    } else {
      console.log('✅ Caisse principale existe déjà avec ID:', caisseExistante.id);
    }

    // 4. Résumé final
    console.log('\n' + '=' .repeat(60));
    console.log('🎉 INITIALISATION TERMINÉE AVEC SUCCÈS !');
    console.log('=' .repeat(60));
    console.log('\n📋 Résumé des éléments créés/vérifiés:');
    console.log(`   ✅ Rôle admin: ${adminRole.displayName} (ID: ${adminRole.id})`);
    console.log(`   ✅ Utilisateur admin: ${adminUser.nomUtilisateur} (ID: ${adminUser.id})`);
    console.log(`   ✅ Caisse principale: ${caisseExistante.nom} (ID: ${caisseExistante.id})`);
    
    console.log('\n🔑 Identifiants de connexion:');
    console.log(`   📧 Nom d'utilisateur: admin`);
    console.log(`   🔒 Mot de passe: admin123`);
    console.log(`   🌐 Email: admin@logesco.com`);
    
    console.log('\n💵 Caisse disponible:');
    console.log(`   📦 Nom: ${caisseExistante.nom}`);
    console.log(`   💰 Solde actuel: ${caisseExistante.soldeActuel} FCFA`);
    console.log(`   👤 Assignée à: ${adminUser.nomUtilisateur}`);
    console.log(`   ✅ Statut: ${caisseExistante.isActive ? 'Active' : 'Inactive'}`);

    console.log('\n🚀 Vous pouvez maintenant vous connecter à l\'application !');

  } catch (error) {
    console.error('\n❌ Erreur lors de l\'initialisation:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  ensureAdminAndCash()
    .then(() => {
      console.log('\n✨ Initialisation terminée avec succès');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Échec de l\'initialisation:', error);
      process.exit(1);
    });
}

module.exports = { ensureAdminAndCash };