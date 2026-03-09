/**
 * Script pour créer les mouvements de caisse manquants à partir des ventes existantes
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixMissingCashMovements() {
  try {
    console.log('🔧 Correction des mouvements de caisse manquants...\n');
    
    // Récupérer toutes les sessions
    const sessions = await prisma.cashSession.findMany({
      orderBy: { dateOuverture: 'desc' },
      take: 10
    });
    
    console.log(`✅ ${sessions.length} session(s) trouvée(s)\n`);
    
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
      
      let mouvementsCreated = 0;
      let totalMontant = 0;
      
      for (const vente of ventes) {
        // Vérifier si un mouvement existe déjà pour cette vente
        const existingMovement = await prisma.cashMovement.findFirst({
          where: {
            caisseId: session.caisseId,
            type: 'vente',
            metadata: {
              contains: `"referenceId":${vente.id}`
            }
          }
        });
        
        if (!existingMovement && vente.montantVerse > 0) {
          // Créer le mouvement manquant
          await prisma.cashMovement.create({
            data: {
              caisseId: session.caisseId,
              type: 'vente',
              montant: vente.montantVerse,
              description: `Vente ${vente.reference}${vente.client ? ` - Client: ${vente.client.nom} ${vente.client.prenom || ''}` : ''}`,
              utilisateurId: vente.utilisateurId,
              dateCreation: vente.dateVente,
              metadata: JSON.stringify({
                categorie: 'vente',
                referenceType: 'vente',
                referenceId: vente.id,
                venteReference: vente.reference,
                clientId: vente.clientId,
                clientNom: vente.client ? `${vente.client.nom} ${vente.client.prenom || ''}` : null,
                montantTotal: vente.montantTotal,
                montantVerse: vente.montantVerse,
                montantRestant: vente.montantRestant,
                correctionAutomatique: true
              })
            }
          });
          
          mouvementsCreated++;
          totalMontant += parseFloat(vente.montantVerse);
        }
      }
      
      if (mouvementsCreated > 0) {
        console.log(`   ✅ ${mouvementsCreated} mouvement(s) créé(s) (${totalMontant} FCFA)`);
      } else {
        console.log(`   ℹ️  Aucun mouvement manquant`);
      }
      
      console.log('');
    }
    
    console.log('✅ Correction terminée!\n');
    
    // Afficher un résumé
    console.log('📊 Vérification des totaux après correction:\n');
    
    for (const session of sessions.slice(0, 3)) {
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

fixMissingCashMovements();
