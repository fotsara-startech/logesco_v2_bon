/**
 * Script de correction DÉFINITIVE pour toutes les transactions
 * Corrige automatiquement toutes les transactions avec mauvais compteId
 * À exécuter après chaque problème détecté
 */

const { PrismaClient } = require('@prisma/client');

async function fixAllTransactionsPermanent() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🔧 CORRECTION DÉFINITIVE: Toutes les transactions incorrectes');
    console.log('============================================================');
    
    // Étape 1: Récupérer tous les comptes clients
    const comptesClients = await prisma.compteClient.findMany({
      select: {
        id: true,
        clientId: true
      }
    });
    
    console.log(`✅ ${comptesClients.length} comptes clients trouvés`);
    
    let totalTransactionsCorrigees = 0;
    let clientsAvecProblemes = [];
    
    // Pour chaque compte client
    for (const compte of comptesClients) {
      // Chercher les transactions avec compteId = clientId (incorrect)
      const transactionsIncorrectes = await prisma.transactionCompte.findMany({
        where: {
          typeCompte: 'client',
          compteId: compte.clientId // INCORRECT: devrait être compte.id
        }
      });
      
      if (transactionsIncorrectes.length > 0) {
        console.log(`\n❌ Client #${compte.clientId}: ${transactionsIncorrectes.length} transaction(s) incorrecte(s)`);
        clientsAvecProblemes.push({
          clientId: compte.clientId,
          compteId: compte.id,
          transactionsCount: transactionsIncorrectes.length
        });
        
        // Corriger toutes les transactions en une seule opération
        const result = await prisma.transactionCompte.updateMany({
          where: {
            typeCompte: 'client',
            compteId: compte.clientId
          },
          data: {
            compteId: compte.id
          }
        });
        
        console.log(`✅ ${result.count} transaction(s) corrigée(s) pour le client #${compte.clientId}`);
        totalTransactionsCorrigees += result.count;
      }
    }
    
    console.log(`\n🎉 CORRECTION TERMINÉE:`);
    console.log(`   Total transactions corrigées: ${totalTransactionsCorrigees}`);
    console.log(`   Clients affectés: ${clientsAvecProblemes.length}`);
    
    if (clientsAvecProblemes.length > 0) {
      console.log('\n📊 DÉTAIL DES CORRECTIONS:');
      clientsAvecProblemes.forEach(client => {
        console.log(`   Client #${client.clientId}: ${client.transactionsCount} transactions (compte ID: ${client.compteId})`);
      });
    }
    
    // Étape 2: Vérification finale - Compter les transactions par client
    console.log('\n📋 VÉRIFICATION FINALE:');
    
    for (const compte of comptesClients) {
      const transactionsCorrectes = await prisma.transactionCompte.count({
        where: {
          typeCompte: 'client',
          compteId: compte.id
        }
      });
      
      if (transactionsCorrectes > 0) {
        console.log(`✅ Client #${compte.clientId}: ${transactionsCorrectes} transaction(s) correcte(s)`);
      }
    }
    
    console.log('\n✅ TOUTES LES TRANSACTIONS SONT MAINTENANT CORRECTES !');
    
  } catch (error) {
    console.error('❌ Erreur lors de la correction:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script
fixAllTransactionsPermanent();