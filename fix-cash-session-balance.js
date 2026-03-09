/**
 * Script pour corriger l'incohérence entre le solde de la caisse et de la session
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixCashSessionBalance() {
  try {
    console.log('🔧 Correction de l\'incohérence du solde de caisse...\n');
    
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
    
    // Récupérer la session active
    const session = await prisma.cashSession.findFirst({
      where: {
        caisseId: caisse.id,
        isActive: true,
        dateFermeture: null
      },
      orderBy: { dateOuverture: 'desc' }
    });
    
    if (!session) {
      console.log('❌ Aucune session active trouvée');
      return;
    }
    
    console.log('\n✅ Session active trouvée:');
    console.log(`   ID: ${session.id}`);
    console.log(`   Solde ouverture: ${session.soldeOuverture} FCFA`);
    console.log(`   Solde attendu: ${session.soldeAttendu} FCFA`);
    
    // Calculer l'écart
    const ecart = parseFloat(caisse.soldeActuel) - parseFloat(session.soldeAttendu || session.soldeOuverture);
    console.log(`\n📊 Analyse:`);
    console.log(`   Solde caisse (DB): ${caisse.soldeActuel} FCFA`);
    console.log(`   Solde session: ${session.soldeAttendu || session.soldeOuverture} FCFA`);
    console.log(`   Écart: ${ecart} FCFA`);
    
    if (Math.abs(ecart) > 0.01) {
      console.log(`\n⚠️  INCOHÉRENCE DÉTECTÉE!`);
      console.log(`   Correction en cours...`);
      
      // Mettre à jour le solde attendu de la session pour correspondre au solde de la caisse
      await prisma.cashSession.update({
        where: { id: session.id },
        data: {
          soldeAttendu: parseFloat(caisse.soldeActuel)
        }
      });
      
      console.log(`\n✅ CORRECTION APPLIQUÉE:`);
      console.log(`   Solde attendu de la session mis à jour: ${caisse.soldeActuel} FCFA`);
      console.log(`   Les soldes sont maintenant cohérents`);
    } else {
      console.log(`\n✅ Les soldes sont déjà cohérents`);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixCashSessionBalance();
