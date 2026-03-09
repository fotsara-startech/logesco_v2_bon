/**
 * Script pour corriger la référence du paiement
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixPaymentReference() {
  console.log('========================================');
  console.log('Correction de la référence du paiement');
  console.log('========================================\n');

  try {
    // Trouver le paiement sans référence
    const paiement = await prisma.transactionCompte.findFirst({
      where: {
        typeCompte: 'fournisseur',
        typeTransaction: 'paiement',
        montant: 29400,
        referenceType: null
      }
    });

    if (!paiement) {
      console.log('❌ Paiement non trouvé');
      return;
    }

    console.log('✅ Paiement trouvé:', paiement.id);
    console.log('   Description:', paiement.description);
    console.log('   Montant:', parseFloat(paiement.montant), 'FCFA');
    console.log('');

    // Mettre à jour avec la référence correcte
    const updated = await prisma.transactionCompte.update({
      where: { id: paiement.id },
      data: {
        referenceType: 'approvisionnement',
        referenceId: 38
      }
    });

    console.log('✅ Référence mise à jour:');
    console.log('   referenceType:', updated.referenceType);
    console.log('   referenceId:', updated.referenceId);
    console.log('');
    console.log('✅ La commande ne devrait plus apparaître dans les impayées');

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixPaymentReference();
