/**
 * Script pour corriger le solde de la session de caisse via SQL
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function fixCashSession() {
  try {
    console.log('🔧 Correction de la session de caisse...\n');
    
    // Utiliser une requête SQL brute
    const sessions = await prisma.$queryRaw`
      SELECT * FROM cash_sessions 
      WHERE statut = 'ouverte' 
      LIMIT 1
    `;
    
    if (!sessions || sessions.length === 0) {
      console.log('❌ Aucune session active trouvée');
      return;
    }
    
    const session = sessions[0];
    console.log(`📊 Session trouvée: ID ${session.id}`);
    console.log(`   Solde initial: ${session.soldeInitial}`);
    console.log(`   Solde actuel: ${session.soldeActuel}`);
    
    // Corriger le solde si nécessaire
    if (session.soldeActuel === null || session.soldeActuel === undefined) {
      console.log('\n🔧 Correction du solde actuel...');
      
      const soldeInitial = session.soldeInitial || 100000;
      
      await prisma.$executeRaw`
        UPDATE cash_sessions
        SET solde_initial = ${soldeInitial},
            solde_actuel = ${soldeInitial}
        WHERE id = ${session.id}
      `;
      
      console.log(`✅ Solde corrigé: ${soldeInitial} FCFA`);
    } else {
      console.log('\n✅ Le solde est déjà défini');
    }
    
    // Vérifier la correction
    const updatedSessions = await prisma.$queryRaw`
      SELECT * FROM cash_sessions 
      WHERE id = ${session.id}
    `;
    
    const updatedSession = updatedSessions[0];
    console.log('\n📊 Session après correction:');
    console.log(`   Solde initial: ${updatedSession.soldeInitial} FCFA`);
    console.log(`   Solde actuel: ${updatedSession.soldeActuel} FCFA`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

fixCashSession();
