/**
 * Script pour vérifier les paiements d'un fournisseur
 * Usage: node check-supplier-payments.js <fournisseurId>
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkSupplierPayments(fournisseurId) {
  console.log('========================================');
  console.log(`Vérification fournisseur ID: ${fournisseurId}`);
  console.log('========================================\n');

  try {
    // 1. Récupérer le fournisseur
    const fournisseur = await prisma.fournisseur.findUnique({
      where: { id: parseInt(fournisseurId) }
    });

    if (!fournisseur) {
      console.log('❌ Fournisseur non trouvé');
      return;
    }

    console.log('✅ Fournisseur:', fournisseur.nom);
    console.log('');

    // 2. Récupérer le compte fournisseur
    const compte = await prisma.compteFournisseur.findUnique({
      where: { fournisseurId: parseInt(fournisseurId) }
    });

    if (compte) {
      console.log('💰 Solde du compte:', parseFloat(compte.soldeActuel), 'FCFA');
      console.log('');
    } else {
      console.log('⚠️  Pas de compte fournisseur');
      console.log('');
    }

    // 3. Récupérer toutes les commandes
    const commandes = await prisma.commandeApprovisionnement.findMany({
      where: {
        fournisseurId: parseInt(fournisseurId),
        statut: { not: 'annulee' }
      },
      orderBy: { dateCommande: 'desc' }
    });

    console.log(`📦 ${commandes.length} commande(s) trouvée(s):\n`);

    // 4. Pour chaque commande, calculer les paiements
    for (const commande of commandes) {
      console.log(`Commande #${commande.numeroCommande} (ID: ${commande.id})`);
      console.log(`  Date: ${commande.dateCommande.toISOString().split('T')[0]}`);
      console.log(`  Montant total: ${parseFloat(commande.montantTotal)} FCFA`);
      console.log(`  Statut: ${commande.statut}`);

      if (compte) {
        // Récupérer les paiements pour cette commande
        const paiements = await prisma.transactionCompte.findMany({
          where: {
            typeCompte: 'fournisseur',
            compteId: compte.id,
            referenceType: 'approvisionnement',
            referenceId: commande.id,
            typeTransaction: { in: ['paiement', 'credit'] }
          },
          orderBy: { dateTransaction: 'asc' }
        });

        let totalPaye = 0;
        if (paiements.length > 0) {
          console.log(`  💳 ${paiements.length} paiement(s):`);
          paiements.forEach((p, index) => {
            const montant = parseFloat(p.montant);
            totalPaye += montant;
            console.log(`    ${index + 1}. ${p.dateTransaction.toISOString().split('T')[0]} - ${montant} FCFA (${p.typeTransaction})`);
            if (p.description) {
              console.log(`       "${p.description}"`);
            }
          });
          console.log(`  ✅ Total payé: ${totalPaye} FCFA`);
        } else {
          console.log(`  ⚠️  Aucun paiement enregistré`);
        }

        const montantRestant = parseFloat(commande.montantTotal) - totalPaye;
        console.log(`  📊 Montant restant: ${montantRestant} FCFA`);
        
        if (montantRestant > 0) {
          console.log(`  ✅ COMMANDE IMPAYÉE (apparaîtra dans la liste)`);
        } else if (montantRestant === 0) {
          console.log(`  ✅ COMMANDE PAYÉE COMPLÈTEMENT (ne devrait PAS apparaître)`);
        } else {
          console.log(`  ⚠️  TROP PAYÉ de ${Math.abs(montantRestant)} FCFA`);
        }
      }

      console.log('');
    }

    // 5. Récupérer toutes les transactions du compte
    if (compte) {
      console.log('========================================');
      console.log('Historique complet des transactions:');
      console.log('========================================\n');

      const transactions = await prisma.transactionCompte.findMany({
        where: {
          typeCompte: 'fournisseur',
          compteId: compte.id
        },
        orderBy: { dateTransaction: 'desc' }
      });

      transactions.forEach((t, index) => {
        console.log(`${index + 1}. ${t.dateTransaction.toISOString().split('T')[0]} - ${t.typeTransaction}`);
        console.log(`   Montant: ${parseFloat(t.montant)} FCFA`);
        console.log(`   Solde après: ${parseFloat(t.soldeApres)} FCFA`);
        if (t.referenceType && t.referenceId) {
          console.log(`   Référence: ${t.referenceType} #${t.referenceId}`);
        }
        if (t.description) {
          console.log(`   Description: "${t.description}"`);
        }
        console.log('');
      });
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Récupérer l'ID du fournisseur depuis les arguments
const fournisseurId = process.argv[2];

if (!fournisseurId) {
  console.log('Usage: node check-supplier-payments.js <fournisseurId>');
  console.log('Exemple: node check-supplier-payments.js 16');
  process.exit(1);
}

checkSupplierPayments(fournisseurId);
