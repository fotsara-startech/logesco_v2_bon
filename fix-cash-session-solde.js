/**
 * Script pour corriger le solde de la session de caisse
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function fixCashSession() {
  try {
    console.log('🔧 Correction de la session de caisse...\n');
    
    // Trouver la session active
    const session = await prisma.sessionCaisse.findFirst({
      where: {
        statut: 'ouverte'
      }
    });
    
    if (!session) {
      console.log('❌ Aucune session active trouvée');
      return;
    }
    
    console.log(`📊 Session trouvée: ID ${session.id}`);
    console.log(`   Solde initial: ${session.soldeInitial}`);
    console.log(`   Solde actuel: ${session.soldeActuel}`);
    
    // Corriger le solde si nécessaire
    if (session.soldeActuel === null || session.soldeActuel === undefined) {
      console.log('\n🔧 Correction du solde actuel...');
      
      const soldeInitial = session.soldeInitial || 100000;
      
      await prisma.sessionCaisse.update({
        where: { id: session.id },
        data: {
          soldeInitial: soldeInitial,
          soldeActuel: soldeInitial
        }
      });
      
      console.log(`✅ Solde corrigé: ${soldeInitial} FCFA`);
    } else {
      console.log('\n✅ Le solde est déjà défini');
    }
    
    // Vérifier la correction
    const updatedSession = await prisma.sessionCaisse.findUnique({
      where: { id: session.id }
    });
    
    console.log('\n📊 Session après correction:');
    console.log(`   Solde initial: ${updatedSession.soldeInitial} FCFA`);
    console.log(`   Solde actuel: ${updatedSession.soldeActuel} FCFA`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

fixCashSession();
