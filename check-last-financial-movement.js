/**
 * Check the last financial movement to verify sessionId
 * Run: node check-last-financial-movement.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');

const prisma = new PrismaClient();

async function check() {
  try {
    console.log('🔍 Checking Last Financial Movement...\n');

    // Check local
    console.log('📍 LOCAL (SQLite):');
    const localMovement = await prisma.financialMovement.findFirst({
      orderBy: { id: 'desc' },
      include: {
        session: {
          select: {
            id: true,
            caisseId: true,
            utilisateurId: true
          }
        }
      }
    });

    if (localMovement) {
      console.log(`   ID: ${localMovement.id}`);
      console.log(`   Reference: ${localMovement.reference}`);
      console.log(`   Montant: ${localMovement.montant} FCFA`);
      console.log(`   Description: ${localMovement.description}`);
      console.log(`   Session ID: ${localMovement.sessionId || 'NULL ❌'}`);
      if (localMovement.session) {
        console.log(`   Session Details: Caisse ${localMovement.session.caisseId}, User ${localMovement.session.utilisateurId}`);
      }
      console.log(`   Boutique ID: ${localMovement.boutiqueId}`);
    }

    // Check Neon
    if (!process.env.CLOUD_DB_URL) {
      console.log('\n⚠️  CLOUD_DB_URL not set');
      return;
    }

    const pool = new Pool({
      connectionString: process.env.CLOUD_DB_URL,
      ssl: { rejectUnauthorized: false }
    });

    console.log('\n☁️  NEON (PostgreSQL):');
    const result = await pool.query(`
      SELECT 
        fm.id,
        fm.reference,
        fm.montant,
        fm.description,
        fm.session_id,
        fm.boutique_id,
        cs.caisse_id,
        cs.utilisateur_id
      FROM financial_movements fm
      LEFT JOIN cash_sessions cs ON fm.session_id = cs.id
      ORDER BY fm.id DESC
      LIMIT 1
    `);

    if (result.rows.length > 0) {
      const neonMovement = result.rows[0];
      console.log(`   ID: ${neonMovement.id}`);
      console.log(`   Reference: ${neonMovement.reference}`);
      console.log(`   Montant: ${neonMovement.montant} FCFA`);
      console.log(`   Description: ${neonMovement.description}`);
      console.log(`   Session ID: ${neonMovement.session_id || 'NULL ❌'}`);
      if (neonMovement.session_id) {
        console.log(`   Session Details: Caisse ${neonMovement.caisse_id}, User ${neonMovement.utilisateur_id}`);
      }
      console.log(`   Boutique ID: ${neonMovement.boutique_id}`);
    }

    // Comparison
    if (localMovement && result.rows.length > 0) {
      const neonMovement = result.rows[0];
      console.log('\n🔄 COMPARISON:');
      
      if (localMovement.reference === neonMovement.reference) {
        console.log(`   ✅ Même mouvement: ${localMovement.reference}`);
      } else {
        console.log(`   ⚠️  Mouvements différents:`);
        console.log(`      Local: ${localMovement.reference}`);
        console.log(`      Neon: ${neonMovement.reference}`);
      }

      if (localMovement.sessionId && neonMovement.session_id) {
        console.log(`   ✅ Session ID renseigné: ${localMovement.sessionId}`);
      } else if (!localMovement.sessionId && !neonMovement.session_id) {
        console.log(`   ❌ Session ID NULL dans les deux bases`);
      } else {
        console.log(`   ⚠️  Session ID différent:`);
        console.log(`      Local: ${localMovement.sessionId || 'NULL'}`);
        console.log(`      Neon: ${neonMovement.session_id || 'NULL'}`);
      }
    }

    await pool.end();

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

check();
