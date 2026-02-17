/**
 * Script pour réinitialiser et remplir la base de données
 * Utilisation: node backend/scripts/reset-and-seed.js
 */

const { PrismaClient } = require('@prisma/client');
const { execSync } = require('child_process');
const path = require('path');

const prisma = new PrismaClient();

async function resetDatabase() {
  console.log('🗑️  Suppression de toutes les données...\n');

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
  } catch (error) {
    console.error('❌ Erreur lors de la suppression:', error.message);
    throw error;
  }
}

async function main() {
  console.log('🔄 Réinitialisation et remplissage de la base de données\n');
  console.log('=' .repeat(60) + '\n');

  try {
    // Étape 1: Réinitialiser la base de données
    await resetDatabase();

    // Étape 2: Exécuter le script de seed
    console.log('🌱 Lancement du script de remplissage...\n');
    const seedScript = path.join(__dirname, 'seed-full-database.js');
    execSync(`node "${seedScript}"`, { stdio: 'inherit' });

    console.log('\n' + '=' .repeat(60));
    console.log('✅ Réinitialisation et remplissage terminés avec succès !');
    console.log('=' .repeat(60) + '\n');

  } catch (error) {
    console.error('\n❌ Erreur:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
