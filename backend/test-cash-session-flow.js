const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function testCashSessionFlow() {
  console.log('🧪 Test du flux complet de session de caisse\n');

  try {
    // 1. Créer une session de test
    console.log('1️⃣ Création d\'une session de test...');
    const session = await prisma.cashSession.create({
      data: {
        caisseId: 1,
        utilisateurId: 1,
        soldeOuverture: 10000,
        soldeAttendu: 10000,
        dateOuverture: new Date(),
        isActive: true
      }
    });
    console.log(`✅ Session créée: ID ${session.id}, Solde ouverture: ${session.soldeOuverture} FCFA\n`);

    // 2. Simuler une vente (mise à jour du soldeAttendu)
    console.log('2️⃣ Simulation d\'une vente de 5000 FCFA...');
    const afterSale = await prisma.cashSession.update({
      where: { id: session.id },
      data: {
        soldeAttendu: session.soldeAttendu + 5000
      }
    });
    console.log(`✅ Après vente: Solde attendu = ${afterSale.soldeAttendu} FCFA\n`);

    // 3. Simuler une dépense (réduction du soldeAttendu)
    console.log('3️⃣ Simulation d\'une dépense de 2000 FCFA...');
    const afterExpense = await prisma.cashSession.update({
      where: { id: session.id },
      data: {
        soldeAttendu: afterSale.soldeAttendu - 2000
      }
    });
    console.log(`✅ Après dépense: Solde attendu = ${afterExpense.soldeAttendu} FCFA\n`);

    // 4. Clôturer avec un montant différent
    console.log('4️⃣ Clôture avec 12500 FCFA déclarés...');
    const soldeFermeture = 12500;
    const ecart = soldeFermeture - afterExpense.soldeAttendu;
    
    const closedSession = await prisma.cashSession.update({
      where: { id: session.id },
      data: {
        soldeFermeture: soldeFermeture,
        ecart: ecart,
        dateFermeture: new Date(),
        isActive: false
      }
    });

    console.log(`📊 Résultat de la clôture:`);
    console.log(`   Solde ouverture: ${closedSession.soldeOuverture} FCFA`);
    console.log(`   Solde attendu: ${closedSession.soldeAttendu} FCFA`);
    console.log(`   Solde déclaré: ${closedSession.soldeFermeture} FCFA`);
    console.log(`   Écart: ${closedSession.ecart >= 0 ? '+' : ''}${closedSession.ecart} FCFA`);
    
    if (closedSession.ecart === ecart) {
      console.log(`\n✅ TEST RÉUSSI: L'écart est correctement calculé!`);
    } else {
      console.log(`\n❌ TEST ÉCHOUÉ: Écart attendu ${ecart}, obtenu ${closedSession.ecart}`);
    }

    // 5. Vérifier dans la base
    console.log('\n5️⃣ Vérification dans la base de données...');
    const verification = await prisma.cashSession.findUnique({
      where: { id: session.id }
    });
    
    console.log(`   ID: ${verification.id}`);
    console.log(`   Solde ouverture: ${verification.soldeOuverture}`);
    console.log(`   Solde attendu: ${verification.soldeAttendu}`);
    console.log(`   Solde fermeture: ${verification.soldeFermeture}`);
    console.log(`   Écart: ${verification.ecart}`);
    console.log(`   Active: ${verification.isActive}`);

    // 6. Nettoyer
    console.log('\n6️⃣ Nettoyage de la session de test...');
    await prisma.cashSession.delete({
      where: { id: session.id }
    });
    console.log('✅ Session de test supprimée\n');

    console.log('🎉 Test terminé avec succès!');

  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testCashSessionFlow();
