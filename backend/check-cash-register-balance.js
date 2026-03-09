/**
 * Script pour vérifier le solde réel de la caisse dans la base de données
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkCashRegisterBalance() {
  try {
    console.log('🔍 Vérification du solde de la caisse...\n');
    
    // Récupérer la caisse principale
    const caisse = await prisma.cashRegister.findFirst({
      where: {
        isActive: true,
        dateOuverture: { not: null },
        dateFermeture: null
      },
      orderBy: { dateOuverture: 'desc' }
    });
    
    if (!caisse) {
      console.log('❌ Aucune caisse active trouvée');
      return;
    }
    
    console.log('✅ Caisse active trouvée:');
    console.log(`   ID: ${caisse.id}`);
    console.log(`   Nom: ${caisse.nom}`);
    console.log(`   Solde actuel (DB): ${caisse.soldeActuel} FCFA`);
    console.log(`   Solde ouverture: ${caisse.soldeOuverture} FCFA`);
    console.log(`   Date ouverture: ${caisse.dateOuverture}`);
    
    // Récupérer la session active
    const session = await prisma.cashSession.findFirst({
      where: {
        caisseId: caisse.id,
        isActive: true,
        dateFermeture: null
      },
      orderBy: { dateOuverture: 'desc' }
    });
    
    if (session) {
      console.log('\n✅ Session active trouvée:');
      console.log(`   ID: ${session.id}`);
      console.log(`   Solde ouverture: ${session.soldeOuverture} FCFA`);
      console.log(`   Solde attendu: ${session.soldeAttendu} FCFA`);
      console.log(`   Date ouverture: ${session.dateOuverture}`);
      
      // Calculer l'écart
      const ecart = parseFloat(caisse.soldeActuel) - parseFloat(session.soldeAttendu || session.soldeOuverture);
      console.log(`\n📊 Analyse:`);
      console.log(`   Solde caisse (DB): ${caisse.soldeActuel} FCFA`);
      console.log(`   Solde session: ${session.soldeAttendu || session.soldeOuverture} FCFA`);
      console.log(`   Écart: ${ecart} FCFA`);
      
      if (Math.abs(ecart) > 0.01) {
        console.log(`\n⚠️  INCOHÉRENCE DÉTECTÉE!`);
        console.log(`   Le solde de la caisse ne correspond pas au solde de la session`);
        console.log(`   Écart: ${ecart} FCFA`);
      } else {
        console.log(`\n✅ Les soldes sont cohérents`);
      }
    } else {
      console.log('\n⚠️  Aucune session active trouvée pour cette caisse');
    }
    
    // Récupérer les derniers mouvements de caisse
    console.log('\n📋 Derniers mouvements de caisse:');
    const mouvements = await prisma.cashMovement.findMany({
      where: { caisseId: caisse.id },
      orderBy: { createdAt: 'desc' },
      take: 5
    });
    
    for (const mouvement of mouvements) {
      const signe = mouvement.type === 'entree' ? '+' : '-';
      console.log(`   ${signe}${mouvement.montant} FCFA - ${mouvement.description} (${mouvement.createdAt})`);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkCashRegisterBalance();
