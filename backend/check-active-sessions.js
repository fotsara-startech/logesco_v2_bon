/**
 * Check active cash sessions
 * Run: node check-active-sessions.js [userId] [boutiqueId]
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkActiveSessions() {
  try {
    const userId = process.argv[2] ? parseInt(process.argv[2]) : null;
    const boutiqueId = process.argv[3] ? parseInt(process.argv[3]) : null;

    console.log('🔍 Checking Active Cash Sessions...\n');

    if (userId) {
      console.log(`Filtering by User ID: ${userId}`);
    }
    if (boutiqueId) {
      console.log(`Filtering by Boutique ID: ${boutiqueId}`);
    }
    console.log('');

    // Build where clause
    const where = {
      isActive: true,
      dateFermeture: null
    };
    if (userId) where.utilisateurId = userId;
    if (boutiqueId) where.boutiqueId = boutiqueId;

    // Find active sessions
    const activeSessions = await prisma.cashSession.findMany({
      where,
      include: {
        caisse: true,
        utilisateur: {
          select: {
            id: true,
            nomUtilisateur: true
          }
        },
        boutique: true
      },
      orderBy: { id: 'desc' }
    });

    if (activeSessions.length === 0) {
      console.log('❌ Aucune session active trouvée');
      console.log('\nCritères de recherche:');
      console.log('  - isActive = true');
      console.log('  - dateFermeture = null');
      if (userId) console.log(`  - utilisateurId = ${userId}`);
      if (boutiqueId) console.log(`  - boutiqueId = ${boutiqueId}`);
      
      // Show all sessions
      console.log('\n📋 Toutes les sessions (actives et fermées):');
      const allSessions = await prisma.cashSession.findMany({
        take: 10,
        orderBy: { id: 'desc' },
        include: {
          caisse: true,
          utilisateur: {
            select: {
              id: true,
              nomUtilisateur: true
            }
          }
        }
      });

      for (const session of allSessions) {
        const status = session.isActive && !session.dateFermeture ? '🟢 Active' : '🔴 Fermée';
        console.log(`\n   ${status} Session ID: ${session.id}`);
        console.log(`   Caisse: ${session.caisse.nom}`);
        console.log(`   Utilisateur: ${session.utilisateur.nomUtilisateur} (ID: ${session.utilisateurId})`);
        console.log(`   Boutique ID: ${session.boutiqueId || 'N/A'}`);
        console.log(`   isActive: ${session.isActive}`);
        console.log(`   Date Ouverture: ${session.dateOuverture}`);
        console.log(`   Date Fermeture: ${session.dateFermeture || 'N/A'}`);
      }

    } else {
      console.log(`✅ ${activeSessions.length} session(s) active(s) trouvée(s):\n`);

      for (const session of activeSessions) {
        console.log(`─────────────────────────────────────────`);
        console.log(`Session ID: ${session.id}`);
        console.log(`Caisse: ${session.caisse.nom}`);
        console.log(`Utilisateur: ${session.utilisateur.nomUtilisateur} (ID: ${session.utilisateurId})`);
        console.log(`Boutique: ${session.boutique?.nom || 'N/A'} (ID: ${session.boutiqueId || 'N/A'})`);
        console.log(`Solde Ouverture: ${session.soldeOuverture} FCFA`);
        console.log(`Solde Attendu: ${session.soldeAttendu || session.soldeOuverture} FCFA`);
        console.log(`Date Ouverture: ${session.dateOuverture}`);
        console.log(`isActive: ${session.isActive}`);
        console.log(`Date Fermeture: ${session.dateFermeture || 'N/A'}`);
        console.log('');
      }
    }

    // Show what the financial movement service is looking for
    console.log('\n🔍 Ce que le service recherche:');
    console.log('   WHERE:');
    console.log('     isActive = true');
    console.log('     dateFermeture IS NULL');
    if (userId) console.log(`     utilisateurId = ${userId}`);
    if (boutiqueId) console.log(`     boutiqueId = ${boutiqueId}`);

    console.log('\n💡 Pour créer une dépense avec sessionId:');
    console.log('   1. Ouvrir une session de caisse dans l\'app');
    console.log('   2. Vérifier que isActive = true');
    console.log('   3. Vérifier que dateFermeture = null');
    console.log('   4. Vérifier que boutiqueId correspond');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkActiveSessions();
