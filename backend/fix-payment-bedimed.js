/**
 * Script pour corriger les paiements du fournisseur BEDIMED
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixPayments() {
  console.log('========================================');
  console.log('Correction des paiements BEDIMED');
  console.log('========================================\n');

  try {
    // Trouver le paiement de 8000 FCFA sans référence
    const paiement8000 = await prisma.transactionCompte.findFirst({
      where: {
        typeCompte: 'fournisseur',
        typeTransaction: 'paiement',
        montant: 8000,
        referenceType: null
      }
    });

    if (paiement8000) {
      console.log('✅ Paiement 8000 FCFA trouvé:', paiement8000.id);
      console.log('   Description:', paiement8000.description);
      
      // Mettre à jour avec la référence à la commande #44
      await prisma.transactionCompte.update({
        where: { id: paiement8000.id },
        data: {
          referenceType: 'approvisionnement',
          referenceId: 44
        }
      });
      
      console.log('✅ Référence mise à jour pour commande #44');
    } else {
      console.log('⚠️  Paiement 8000 FCFA non trouvé ou déjà corrigé');
    }

    console.log('');
    console.log('✅ Correction terminée');

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixPayments();
