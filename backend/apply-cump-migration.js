/**
 * Script d'application de la migration CUMP
 * Exécuter avec: node apply-cump-migration.js
 */

const fs = require('fs');
const path = require('path');

async function applyMigration() {
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();

  try {
    console.log('🔄 Application de la migration CUMP...');

    const sqlPath = path.join(__dirname, 'prisma/migrations/add_cump_historique_prix_achat.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Exécuter chaque statement séparément
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      try {
        await prisma.$executeRawUnsafe(statement);
        console.log(`✅ Exécuté: ${statement.substring(0, 60)}...`);
      } catch (err) {
        // Ignorer les erreurs "column already exists" ou "table already exists"
        if (err.message.includes('already exists') || err.message.includes('duplicate column')) {
          console.log(`⚠️  Déjà existant (ignoré): ${statement.substring(0, 60)}...`);
        } else {
          console.error(`❌ Erreur: ${err.message}`);
          console.error(`   Statement: ${statement}`);
        }
      }
    }

    console.log('\n✅ Migration CUMP appliquée avec succès!');
    console.log('📊 Résumé:');

    const countHistorique = await prisma.$queryRaw`SELECT COUNT(*) as count FROM historique_prix_achat`;
    const countCump = await prisma.$queryRaw`SELECT COUNT(*) as count FROM produits WHERE cump IS NOT NULL`;
    
    console.log(`   - Entrées historique initialisées: ${countHistorique[0].count}`);
    console.log(`   - Produits avec CUMP initialisé: ${countCump[0].count}`);

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

applyMigration();
