/**
 * Script de correction pour les transactions avec mauvais compteId
 * Corrige le bug où compteId = clientId au lieu de compteId = compte.id
 */

const { PrismaClient } = require('@prisma/client');

async function fixTransactionsCompteId() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🔧 CORRECTION: Transactions avec mauvais compteId');
    console.log('===============================================');
    
    // Étape 1: Identifier les transactions problématiques
    console.log('\n📋 Étape 1: Identification des transactions problématiques...');
    
    // Récupérer tous les comptes clients
    const comptesClients = await prisma.compteClient.findMany({
      select: {
        id: true,
        clientId: true
      }
    });
    
    console.log(`✅ ${comptesClients.length} comptes clients trouvés`);
    
    let totalTransactionsCorrigees = 0;
    
    // Pour chaque compte client
    for (const compte of comptesClients) {
      console.log(`\n🔍 Vérification compte client ID ${compte.clientId} (compte ID ${compte.id})...`);
      
      // Chercher les transactions avec compteId = clientId (incorrect)
      const transactionsIncorrectes = await prisma.transactionCompte.findMany({
        where: {
          typeCompte: 'client',
          compteId: compte.clientId // INCORRECT: devrait être compte.id
        }
      });
      
      if (transactionsIncorrectes.length > 0) {
        console.log(`❌ ${transactionsIncorrectes.length} transaction(s) incorrecte(s) trouvée(s)`);
        
        // Corriger chaque transaction
        for (const transaction of transactionsIncorrectes) {
          console.log(`   Correction transaction ID ${transaction.id}:`);
          console.log(`     Ancien compteId: ${transaction.compteId} (clientId)`);
          console.log(`     Nouveau compteId: ${compte.id} (compte.id)`);
          
          await prisma.transactionCompte.update({
            where: { id: transaction.id },
            data: { compteId: compte.id }
          });
          
          totalTransactionsCorrigees++;
        }
        
        console.log(`✅ ${transactionsIncorrectes.length} transaction(s) corrigée(s) pour le client ${compte.clientId}`);
      } else {
        console.log(`✅ Aucune transaction incorrecte pour le client ${compte.clientId}`);
      }
    }
    
    console.log(`\n🎉 CORRECTION TERMINÉE:`);
    console.log(`   Total transactions corrigées: ${totalTransactionsCorrigees}`);
    
    // Étape 2: Vérification pour le client #30 spécifiquement
    console.log('\n📋 Étape 2: Vérification spécifique client #30...');
    
    const compteClient30 = await prisma.compteClient.findUnique({
      where: { clientId: 30 }
    });
    
    if (compteClient30) {
      const transactionsClient30 = await prisma.transactionCompte.findMany({
        where: {
          typeCompte: 'client',
          compteId: compteClient30.id
        },
        orderBy: { dateTransaction: 'desc' }
      });
      
      console.log(`✅ Client #30 - Compte ID: ${compteClient30.id}`);
      console.log(`✅ Transactions trouvées: ${transactionsClient30.length}`);
      
      transactionsClient30.forEach((transaction, index) => {
        console.log(`  ${index + 1}. Transaction ID: ${transaction.id}`);
        console.log(`     - Type: ${transaction.typeTransaction}`);
        console.log(`     - Montant: ${transaction.montant} FCFA`);
        console.log(`     - Date: ${transaction.dateTransaction}`);
      });
      
      if (transactionsClient30.length > 0) {
        console.log('\n✅ SUCCÈS: Les transactions du client #30 sont maintenant correctes !');
      } else {
        console.log('\n❌ PROBLÈME: Aucune transaction trouvée pour le client #30');
        console.log('   Il faut peut-être créer une nouvelle vente pour tester');
      }
    } else {
      console.log('❌ Compte client #30 non trouvé');
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la correction:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script
fixTransactionsCompteId();