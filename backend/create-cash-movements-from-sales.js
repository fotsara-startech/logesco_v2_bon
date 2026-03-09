/**
 * Script pour créer les mouvements de caisse à partir des ventes
 * Ce script crée TOUS les mouvements manquants
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function createCashMovementsFromSales() {
  try {
    console.log('🔧 Création des mouvements de caisse à partir des ventes...\n');
    
    // Récupérer toutes les sessions récentes
    const sessions = await prisma.cashSession.findMany({
      orderBy: { dateOuverture: 'desc' },
      take: 10
    });
    
    console.log(`✅ ${sessions.length} session(s) trouvée(s)\n`);
    
    let totalCreated = 0;
    
    for (const session of sessions) {
      console.log(`📋 Session ${session.id} (${session.dateOuverture.toLocaleDateString()})`);
      
      // Récupérer les ventes de cette session
      const ventes = await prisma.vente.findMany({
        where: {
          dateVente: {
            gte: session.dateOuverture,
            ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
          }
        },
        include: {
          client: true
        }
      });
      
      console.log(`   ${ventes.length} vente(s) trouvée(s)`);
      
      if (ventes.length === 0) {
        console.log(`   ℹ️  Aucune vente dans cette session\n`);
        continue;
      }
      
      // Supprimer les anciens mouvements de type 'vente' pour cette session
      const deleted = await prisma.cashMovement.deleteMany({
        where: {
          caisseId: session.caisseId,
          type: 'vente',
          dateCreation: {
            gte: session.dateOuverture,
            ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
          }
        }
      });
      
      if (deleted.count > 0) {
        console.log(`   🗑️  ${deleted.count} ancien(s) mouvement(s) supprimé(s)`);
      }
      
      let mouvementsCreated = 0;
      let totalMontant = 0;
      
      for (const vente of ventes) {
        if (vente.montantPaye > 0) {
          // Créer le mouvement
          await prisma.cashMovement.create({
            data: {
              caisseId: session.caisseId,
              type: 'vente',
              montant: vente.montantPaye,
              description: `Vente ${vente.numeroVente}${vente.client ? ` - Client: ${vente.client.nom} ${vente.client.prenom || ''}` : ''}`,
              utilisateurId: vente.vendeurId,
              dateCreation: vente.dateVente,
              metadata: JSON.stringify({
                categorie: 'vente',
                referenceType: 'vente',
                referenceId: vente.id,
                venteReference: vente.numeroVente,
                clientId: vente.clientId,
                clientNom: vente.client ? `${vente.client.nom} ${vente.client.prenom || ''}` : null,
                montantTotal: vente.montantTotal,
                montantPaye: vente.montantPaye,
                montantRestant: vente.montantRestant
              })
            }
          });
          
          mouvementsCreated++;
          totalMontant += parseFloat(vente.montantPaye);
        }
      }
      
      console.log(`   ✅ ${mouvementsCreated} mouvement(s) créé(s) (${totalMontant} FCFA)\n`);
      totalCreated += mouvementsCreated;
    }
    
    console.log(`\n✅ Correction terminée! ${totalCreated} mouvement(s) créé(s) au total\n`);
    
    // Afficher un résumé
    console.log('📊 Vérification des totaux après correction:\n');
    
    for (const session of sessions.slice(0, 5)) {
      const entrees = await prisma.cashMovement.aggregate({
        where: {
          caisseId: session.caisseId,
          dateCreation: {
            gte: session.dateOuverture,
            ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
          },
          type: { in: ['entree', 'vente'] }
        },
        _sum: {
          montant: true
        }
      });
      
      const sorties = await prisma.cashMovement.aggregate({
        where: {
          caisseId: session.caisseId,
          dateCreation: {
            gte: session.dateOuverture,
            ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
          },
          type: 'sortie'
        },
        _sum: {
          montant: true
        }
      });
      
      const totalEntrees = entrees._sum.montant || 0;
      const totalSorties = sorties._sum.montant || 0;
      const calculatedSolde = session.soldeOuverture + totalEntrees - totalSorties;
      
      console.log(`Session ${session.id}:`);
      console.log(`   Total entrées: ${totalEntrees} FCFA`);
      console.log(`   Total sorties: ${totalSorties} FCFA`);
      console.log(`   Solde calculé: ${calculatedSolde} FCFA`);
      console.log(`   Solde attendu: ${session.soldeAttendu || session.soldeOuverture} FCFA`);
      
      const difference = Math.abs(calculatedSolde - (session.soldeAttendu || session.soldeOuverture));
      if (difference > 0.01) {
        console.log(`   ⚠️  Écart: ${difference} FCFA`);
      } else {
        console.log(`   ✅ Cohérent`);
      }
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createCashMovementsFromSales();
