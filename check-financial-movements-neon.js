/**
 * Check financial_movements and cash_movements in Neon
 * Run: node check-financial-movements-neon.js
 */

require('dotenv').config();
const { Pool } = require('pg');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function check() {
  try {
    console.log('🔍 Checking Financial & Cash Movements...\n');

    // Check local first
    console.log('📍 LOCAL (SQLite):');
    const localFM = await prisma.financialMovement.count();
    const localCM = await prisma.cashMovement.count();
    console.log(`   Financial Movements: ${localFM}`);
    console.log(`   Cash Movements: ${localCM}`);

    // Check Neon
    if (!process.env.CLOUD_DB_URL) {
      console.log('\n⚠️  CLOUD_DB_URL not set - cannot check Neon');
      return;
    }

    const pool = new Pool({
      connectionString: process.env.CLOUD_DB_URL,
      ssl: { rejectUnauthorized: false }
    });

    console.log('\n☁️  NEON (PostgreSQL):');

    // Check financial_movements
    const fm = await pool.query(
      'SELECT COUNT(*) as count FROM financial_movements'
    );
    console.log(`   Financial Movements: ${fm.rows[0].count}`);

    // Check cash_movements
    const cm = await pool.query(
      'SELECT COUNT(*) as count FROM cash_movements'
    );
    console.log(`   Cash Movements: ${cm.rows[0].count}`);

    // Recent financial movements
    console.log('\n💰 Recent Financial Movements (Neon):');
    const recentFM = await pool.query(
      'SELECT id, reference, montant, boutique_id, description FROM financial_movements ORDER BY id DESC LIMIT 5'
    );
    if (recentFM.rows.length > 0) {
      for (const row of recentFM.rows) {
        console.log(`   ${row.reference}: ${row.montant} FCFA (Boutique ${row.boutique_id}) - ${row.description}`);
      }
    } else {
      console.log('   Aucun mouvement financier dans Neon');
    }

    // Recent cash movements
    console.log('\n💵 Recent Cash Movements (Neon):');
    const recentCM = await pool.query(
      'SELECT id, type, montant, boutique_id, description FROM cash_movements ORDER BY id DESC LIMIT 5'
    );
    if (recentCM.rows.length > 0) {
      for (const row of recentCM.rows) {
        console.log(`   ${row.type}: ${row.montant} FCFA (Boutique ${row.boutique_id}) - ${row.description}`);
      }
    } else {
      console.log('   Aucun mouvement de caisse dans Neon');
    }

    // Comparison
    console.log('\n🔄 COMPARISON:');
    const fmDiff = localFM - parseInt(fm.rows[0].count);
    const cmDiff = localCM - parseInt(cm.rows[0].count);

    if (fmDiff === 0) {
      console.log(`   ✅ Financial Movements synchronisés: ${localFM} local = ${fm.rows[0].count} Neon`);
    } else {
      console.log(`   ⚠️  Financial Movements différence: ${localFM} local vs ${fm.rows[0].count} Neon (écart: ${fmDiff})`);
    }

    if (cmDiff === 0) {
      console.log(`   ✅ Cash Movements synchronisés: ${localCM} local = ${cm.rows[0].count} Neon`);
    } else {
      console.log(`   ⚠️  Cash Movements différence: ${localCM} local vs ${cm.rows[0].count} Neon (écart: ${cmDiff})`);
    }

    // Check by boutique
    console.log('\n🏪 Par Boutique (Neon):');
    const byBoutique = await pool.query(`
      SELECT 
        boutique_id,
        COUNT(*) as count,
        SUM(montant) as total
      FROM financial_movements
      WHERE boutique_id IS NOT NULL
      GROUP BY boutique_id
      ORDER BY boutique_id
    `);

    if (byBoutique.rows.length > 0) {
      for (const row of byBoutique.rows) {
        console.log(`   Boutique ${row.boutique_id}: ${row.count} mouvements, Total: ${row.total} FCFA`);
      }
    } else {
      console.log('   Aucune donnée par boutique');
    }

    await pool.end();

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

check();
