/**
 * Script pour nettoyer la base de données et la préparer pour la production
 * ATTENTION: Supprime TOUTES les données de test !
 * Utilisation: node backend/scripts/clean-for-production.js
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const readline = require('readline');

const prisma = new PrismaClient();

// Interface pour demander confirmation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function cleanDatabase() {
  console.log('\n⚠️  ATTENTION: NETTOYAGE POUR PRODUCTION ⚠️\n');
  console.log('Ce script va:');
  console.log('  1. Supprimer TOUTES les données de test');
  console.log('  2. Garder uniquement la structure de la base');
  console.log('  3. Créer un utilisateur admin initial');
  console.log('  4. Créer les paramètres entreprise de base\n');

  const answer = await askQuestion('Êtes-vous sûr de vouloir continuer? (oui/non): ');
  
  if (answer.toLowerCase() !== 'oui') {
    console.log('\n❌ Opération annulée.');
    rl.close();
    return;
  }

  console.log('\n🗑️  Suppression des données de test...\n');

  try {
    // Supprimer dans l'ordre inverse des dépendances
    await prisma.movementAttachment.deleteMany();
    await prisma.financialMovement.deleteMany();
    await prisma.movementCategory.deleteMany();
    
    await prisma.inventoryItem.deleteMany();
    await prisma.stockInventory.deleteMany();
    
    await prisma.cashMovement.deleteMany();
    await prisma.cashRegister.deleteMany();
    
    await prisma.reimpressionRecu.deleteMany();
    await prisma.historiqueRecu.deleteMany();
    
    await prisma.detailVente.deleteMany();
    await prisma.vente.deleteMany();
    
    await prisma.mouvementStock.deleteMany();
    await prisma.transactionCompte.deleteMany();
    
    await prisma.detailCommandeApprovisionnement.deleteMany();
    await prisma.commandeApprovisionnement.deleteMany();
    
    await prisma.stock.deleteMany();
    await prisma.produit.deleteMany();
    await prisma.category.deleteMany();
    
    await prisma.compteClient.deleteMany();
    await prisma.client.deleteMany();
    
    await prisma.compteFournisseur.deleteMany();
    await prisma.fournisseur.deleteMany();
    
    await prisma.licenseAuditLog.deleteMany();
    await prisma.licenseActivation.deleteMany();
    await prisma.license.deleteMany();
    
    await prisma.utilisateur.deleteMany();
    await prisma.userRole.deleteMany();
    
    await prisma.parametresEntreprise.deleteMany();

    console.log('✅ Toutes les données ont été supprimées\n');

    // Créer les rôles de base
    console.log('📋 Création des rôles de base...');
    const adminRole = await prisma.userRole.create({
      data: {
        nom: 'admin',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: JSON.stringify({
          users: { create: true, read: true, update: true, delete: true },
          products: { create: true, read: true, update: true, delete: true },
          sales: { create: true, read: true, update: true, delete: true },
          inventory: { create: true, read: true, update: true, delete: true },
          reports: { create: true, read: true, update: true, delete: true },
          settings: { create: true, read: true, update: true, delete: true }
        })
      }
    });
    console.log('✅ Rôle administrateur créé\n');

    // Créer l'utilisateur admin
    console.log('👤 Création de l\'utilisateur admin...');
    const adminPassword = await askQuestion('Mot de passe pour admin (laissez vide pour "admin123"): ');
    const password = adminPassword.trim() || 'admin123';
    const hashedPassword = await bcrypt.hash(password, 10);

    await prisma.utilisateur.create({
      data: {
        nomUtilisateur: 'admin',
        email: 'admin@logesco.com',
        motDePasseHash: hashedPassword,
        roleId: adminRole.id,
        isActive: true
      }
    });
    console.log('✅ Utilisateur admin créé\n');

    // Créer les paramètres entreprise
    console.log('🏢 Configuration des paramètres entreprise...');
    const companyName = await askQuestion('Nom de l\'entreprise (laissez vide pour "Mon Entreprise"): ');
    
    await prisma.parametresEntreprise.create({
      data: {
        nomEntreprise: companyName.trim() || 'Mon Entreprise',
        adresse: 'À configurer',
        localisation: 'À configurer',
        telephone: 'À configurer',
        email: 'contact@entreprise.com',
        nuiRccm: 'À configurer'
      }
    });
    console.log('✅ Paramètres entreprise créés\n');

    console.log('═══════════════════════════════════════════════════════');
    console.log('🎉 Base de données nettoyée et prête pour la production !');
    console.log('═══════════════════════════════════════════════════════\n');
    console.log('📝 Informations de connexion:');
    console.log('   Utilisateur: admin');
    console.log('   Email: admin@logesco.com');
    console.log(`   Mot de passe: ${password}`);
    console.log('\n⚠️  N\'oubliez pas de:');
    console.log('   1. Configurer les paramètres de l\'entreprise');
    console.log('   2. Créer les autres utilisateurs nécessaires');
    console.log('   3. Ajouter vos catégories et produits réels');
    console.log('   4. Changer le mot de passe admin\n');

  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error.message);
    throw error;
  } finally {
    rl.close();
    await prisma.$disconnect();
  }
}

cleanDatabase();
