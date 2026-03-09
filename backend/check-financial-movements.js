/**
 * Script pour vérifier les mouvements financiers récents
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkFinancialMovements() {
  console.log('========================================');
  console.log('Vérification des mouvements financiers');
  console.log('========================================\n');

  try {
    // Récupérer les 10 derniers mouvements financiers
    const mouvements = await prisma.financialMovement.findMany({
      orderBy: { dateCreation: 'desc' },
      take: 10,
      include: {
        utilisateur: {
          select: { nomUtilisateur: true, email: true }
        },
        caisse: {
          select: { nom: true }
        },
        sessionCaisse: {
          select: { id: true, soldeActuel: true }
        }
      }
    });

    console.log(`📊 ${mouvements.length} mouvement(s) récent(s):\n`);

    mouvements.forEach((m, index) => {
      console.log(`${index + 1}. ${m.dateCreation.toISOString().split('T')[0]} - ${m.type.toUpperCase()}`);
      console.log(`   Catégorie: ${m.categorie}`);
      console.log(`   Montant: ${parseFloat(m.montant)} FCFA`);
      console.log(`   Description: "${m.description}"`);
      console.log(`   Caisse: ${m.caisse.nom}`);
      console.log(`   Utilisateur: ${m.utilisateur.nomUtilisateur}`);
      if (m.sessionCaisse) {
        console.log(`   Session caisse: #${m.sessionCaisse.id} (Solde: ${parseFloat(m.sessionCaisse.soldeActuel)} FCFA)`);
      }
      if (m.referenceType && m.referenceId) {
        console.log(`   Référence: ${m.referenceType} #${m.referenceId}`);
      }
      console.log('');
    });

    // Vérifier les mouvements de paiement fournisseur
    const paiementsFournisseurs = mouvements.filter(m => m.categorie === 'paiement_fournisseur');
    console.log('========================================');
    console.log(`✅ ${paiementsFournisseurs.length} paiement(s) fournisseur trouvé(s)`);
    console.log('========================================\n');

    // Vérifier les sessions de caisse actives
    const sessionsActives = await prisma.sessionCaisse.findMany({
      where: { statut: 'ouverte' },
      include: {
        utilisateur: {
          select: { nomUtilisateur: true, email: true }
        },
        caisse: {
          select: { nom: true }
        }
      }
    });

    console.log('========================================');
    console.log('Sessions de caisse actives:');
    console.log('========================================\n');

    if (sessionsActives.length === 0) {
      console.log('⚠️  Aucune session de caisse active');
    } else {
      sessionsActives.forEach((s, index) => {
        console.log(`${index + 1}. Session #${s.id}`);
        console.log(`   Caisse: ${s.caisse.nom}`);
        console.log(`   Utilisateur: ${s.utilisateur.nomUtilisateur}`);
        console.log(`   Solde actuel: ${parseFloat(s.soldeActuel)} FCFA`);
        console.log(`   Ouverture: ${s.dateOuverture.toISOString()}`);
        console.log('');
      });
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkFinancialMovements();
