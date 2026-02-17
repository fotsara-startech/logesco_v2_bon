/**
 * Script pour recalculer l'écart des anciennes sessions
 * Les sessions créées avant l'ajout de la colonne 'ecart' ont ecart = NULL
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixOldSessions() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('🔧 CORRECTION DES ANCIENNES SESSIONS');
  console.log('═══════════════════════════════════════════════════════════\n');

  try {
    // Récupérer toutes les sessions fermées avec ecart NULL
    const sessionsToFix = await prisma.cashSession.findMany({
      where: {
        isActive: false,
        dateFermeture: { not: null },
        OR: [
          { ecart: null },
          { soldeAttendu: null }
        ]
      },
      orderBy: { id: 'asc' }
    });

    console.log(`📊 ${sessionsToFix.length} session(s) à corriger\n`);

    if (sessionsToFix.length === 0) {
      console.log('✅ Aucune session à corriger');
      return;
    }

    let corrected = 0;
    let skipped = 0;

    for (const session of sessionsToFix) {
      console.log(`\n📌 Session ${session.id}:`);
      console.log(`   Solde ouverture: ${session.soldeOuverture}`);
      console.log(`   Solde fermeture: ${session.soldeFermeture}`);
      console.log(`   Solde attendu: ${session.soldeAttendu}`);
      console.log(`   Écart actuel: ${session.ecart}`);

      // Si soldeFermeture est NULL, on ne peut pas calculer l'écart
      if (session.soldeFermeture === null) {
        console.log('   ⚠️ Pas de solde de fermeture - ignoré');
        skipped++;
        continue;
      }

      // Calculer le solde attendu si NULL
      // Pour les anciennes sessions, on suppose que soldeAttendu = soldeFermeture (pas d'écart)
      // Ou on peut utiliser soldeOuverture comme base
      const soldeAttendu = session.soldeAttendu !== null 
        ? parseFloat(session.soldeAttendu)
        : parseFloat(session.soldeOuverture); // Utiliser le solde d'ouverture comme référence

      const soldeFermeture = parseFloat(session.soldeFermeture);
      const ecart = soldeFermeture - soldeAttendu;

      console.log(`   ✓ Calcul:`);
      console.log(`     Solde attendu: ${soldeAttendu}`);
      console.log(`     Solde fermeture: ${soldeFermeture}`);
      console.log(`     Écart: ${ecart}`);

      // Mettre à jour la session
      await prisma.cashSession.update({
        where: { id: session.id },
        data: {
          soldeAttendu: soldeAttendu,
          ecart: ecart
        }
      });

      console.log(`   ✅ Session ${session.id} corrigée`);
      corrected++;
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ:');
    console.log(`   Sessions corrigées: ${corrected}`);
    console.log(`   Sessions ignorées: ${skipped}`);
    console.log(`   Total: ${sessionsToFix.length}`);
    console.log('═══════════════════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌ ERREUR:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script
fixOldSessions();
