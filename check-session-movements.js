/**
 * Script pour vérifier les mouvements de caisse d'une session
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkSessionMovements() {
  try {
    console.log('🔍 Vérification des mouvements de caisse par session...\n');
    
    // Récupérer les 3 dernières sessions
    const sessions = await prisma.cashSession.findMany({
      orderBy: { dateOuverture: 'desc' },
      take: 3,
      include: {
        caisse: true,
        utilisateur: true
      }
    });
    
    for (const session of sessions) {
      console.log(`\n📋 Session ${session.id} (${session.caisse.nom})`);
      console.log(`   Ouverture: ${session.dateOuverture.toLocaleString('fr-FR')}`);
      console.log(`   Fermeture: ${session.dateFermeture ? session.dateFermeture.toLocaleString('fr-FR') : 'En cours'}`);
      console.log(`   Solde ouverture: ${session.soldeOuverture} FCFA`);
      console.log(`   Solde attendu: ${session.soldeAttendu || 0} FCFA`);
      
      // Vérifier les ventes liées à cette session
      const ventes = await prisma.vente.findMany({
        where: { sessionId: session.id }
      });
      
      console.log(`\n   📦 Ventes (${ventes.length}):`);
      if (ventes.length > 0) {
        for (const vente of ventes) {
          console.log(`      - ${vente.numeroVente}: ${vente.montantPaye} FCFA (sessionId: ${vente.sessionId})`);
        }
      } else {
        console.log(`      Aucune vente liée à cette session`);
      }
      
      // Vérifier les mouvements de caisse liés à cette session
      const mouvements = await prisma.cashMovement.findMany({
        where: { sessionId: session.id },
        orderBy: { dateCreation: 'asc' }
      });
      
      console.log(`\n   💰 Mouvements de caisse (${mouvements.length}):`);
      if (mouvements.length > 0) {
        let totalEntrees = 0;
        let totalSorties = 0;
        
        for (const mouvement of mouvements) {
          const signe = mouvement.type === 'sortie' ? '-' : '+';
          console.log(`      ${signe} ${mouvement.montant} FCFA [${mouvement.type}] - ${mouvement.description || 'Sans description'}`);
          
          if (mouvement.type === 'vente' || mouvement.type === 'entree') {
            totalEntrees += parseFloat(mouvement.montant);
          } else if (mouvement.type === 'sortie') {
            totalSorties += parseFloat(mouvement.montant);
          }
        }
        
        console.log(`\n   📊 Totaux calculés:`);
        console.log(`      Total entrées: ${totalEntrees} FCFA`);
        console.log(`      Total sorties: ${totalSorties} FCFA`);
        console.log(`      Net: ${totalEntrees - totalSorties} FCFA`);
        console.log(`      Solde calculé: ${session.soldeOuverture + totalEntrees - totalSorties} FCFA`);
        console.log(`      Solde attendu: ${session.soldeAttendu || 0} FCFA`);
        
        const difference = Math.abs((session.soldeOuverture + totalEntrees - totalSorties) - (session.soldeAttendu || 0));
        if (difference > 0.01) {
          console.log(`      ⚠️  Écart: ${difference} FCFA`);
        } else {
          console.log(`      ✅ Cohérent`);
        }
      } else {
        console.log(`      Aucun mouvement lié à cette session`);
        console.log(`      ⚠️  C'est probablement le problème!`);
      }
      
      console.log(`\n   ${'─'.repeat(60)}`);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkSessionMovements();
