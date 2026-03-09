/**
 * Script pour initialiser les champs montantPaye et montantRestant des commandes existantes
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function updateCommandes() {
  try {
    console.log('🔄 Mise à jour des commandes existantes...');

    // Récupérer toutes les commandes
    const commandes = await prisma.commandeApprovisionnement.findMany({
      select: {
        id: true,
        numeroCommande: true,
        montantTotal: true
      }
    });

    console.log(`📦 ${commandes.length} commande(s) trouvée(s)`);

    // Mettre à jour chaque commande
    for (const commande of commandes) {
      const montantTotal = parseFloat(commande.montantTotal || 0);
      
      await prisma.commandeApprovisionnement.update({
        where: { id: commande.id },
        data: {
          montantPaye: 0,
          montantRestant: montantTotal
        }
      });

      console.log(`✅ Commande ${commande.numeroCommande}: montantTotal=${montantTotal}, montantRestant=${montantTotal}`);
    }

    console.log('✅ Mise à jour terminée avec succès');
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateCommandes();
