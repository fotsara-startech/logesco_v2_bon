/**
 * Check cash session balance in local and Neon
 * Run: node check-session-balance.js [sessionId]
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');

const prisma = new PrismaClient();

async function checkBalance() {
  try {
    const sessionId = process.argv[2] || 52; // Default to session 52
    
    console.log(`🔍 Checking balance for session ${sessionId}...\n`);

    // Check local
    console.log('📍 LOCAL (SQLite):');
    const localSession = await prisma.cashSession.findUnique({
      where: { id: parseInt(sessionId) },
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

    if (localSession) {
      console.log(`   Session ID: ${localSession.id}`);
      console.log(`   Caisse: ${localSession.caisse.nom}`);
      console.log(`   Utilisateur: ${localSession.utilisateur.nomUtilisateur}`);
      console.log(`   Solde Ouverture: ${localSession.soldeOuverture} FCFA`);
      console.log(`   Solde Attendu: ${localSession.soldeAttendu} FCFA`);
      console.log(`   Solde Fermeture: ${localSession.soldeFermeture || 'N/A'}`);
      console.log(`   Active: ${localSession.isActive ? 'Oui' : 'Non'}`);
    } else {
      console.log(`   ❌ Session ${sessionId} not found in local`);
    }

    // Check Neon
    if (process.env.CLOUD_DB_URL) {
      console.log('\n☁️  NEON (PostgreSQL):');
      const pool = new Pool({
        connectionString: process.env.CLOUD_DB_URL,
        ssl: { rejectUnauthorized: false }
      });

      const result = await pool.query(
        'SELECT id, caisse_id, utilisateur_id, solde_ouverture, solde_attendu, solde_fermeture, is_active FROM cash_sessions WHERE id = $1',
        [parseInt(sessionId)]
      );

      if (result.rows.length > 0) {
        const neonSession = result.rows[0];
        console.log(`   Session ID: ${neonSession.id}`);
        console.log(`   Caisse ID: ${neonSession.caisse_id}`);
        console.log(`   Utilisateur ID: ${neonSession.utilisateur_id}`);
        console.log(`   Solde Ouverture: ${neonSession.solde_ouverture} FCFA`);
        console.log(`   Solde Attendu: ${neonSession.solde_attendu} FCFA`);
        console.log(`   Solde Fermeture: ${neonSession.solde_fermeture || 'N/A'}`);
        console.log(`   Active: ${neonSession.is_active ? 'Oui' : 'Non'}`);

        // Compare
        console.log('\n🔄 COMPARISON:');
        if (localSession) {
          const localAttendu = parseFloat(localSession.soldeAttendu || 0);
          const neonAttendu = parseFloat(neonSession.solde_attendu || 0);
          
          if (Math.abs(localAttendu - neonAttendu) < 0.01) {
            console.log(`   ✅ Soldes synchronisés: ${localAttendu} FCFA`);
          } else {
            console.log(`   ⚠️  Différence détectée:`);
            console.log(`      Local: ${localAttendu} FCFA`);
            console.log(`      Neon: ${neonAttendu} FCFA`);
            console.log(`      Écart: ${localAttendu - neonAttendu} FCFA`);
          }
        }
      } else {
        console.log(`   ❌ Session ${sessionId} not found in Neon`);
      }

      await pool.end();
    } else {
      console.log('\n⚠️  CLOUD_DB_URL not set - cannot check Neon');
    }

    // Check recent financial movements for this session
    console.log('\n💰 Recent Financial Movements for this session:');
    const movements = await prisma.financialMovement.findMany({
      where: { sessionId: parseInt(sessionId) },
      orderBy: { id: 'desc' },
      take: 5,
      select: {
        id: true,
        reference: true,
        montant: true,
        description: true,
        date: true
      }
    });

    if (movements.length > 0) {
      for (const mov of movements) {
        console.log(`   ${mov.reference}: -${mov.montant} FCFA - ${mov.description}`);
      }
    } else {
      console.log(`   Aucun mouvement financier pour cette session`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkBalance();
