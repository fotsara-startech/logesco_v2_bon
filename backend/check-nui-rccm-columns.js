/**
 * Script de diagnostic pour vérifier la présence des colonnes NUI et RCCM
 * Exécution: node check-nui-rccm-columns.js
 */

const { PrismaClient } = require('@prisma/client');
const path = require('path');
const fs = require('fs');

async function checkColumns() {
  console.log('╔═══════════════════════════════════════════════════════════════╗');
  console.log('║   DIAGNOSTIC: Colonnes NUI et RCCM                          ║');
  console.log('╚═══════════════════════════════════════════════════════════════╝\n');

  // Chemins possibles de la base de données
  const dbPaths = [
    path.join(__dirname, 'database', 'logesco.db'),
    path.join(process.env.LOCALAPPDATA || '', 'LOGESCO', 'backend', 'database', 'logesco.db')
  ];

  for (const dbPath of dbPaths) {
    if (fs.existsSync(dbPath)) {
      console.log(`📁 Base de données trouvée: ${dbPath}\n`);
      await checkDatabase(dbPath);
    } else {
      console.log(`⚠️ Base de données non trouvée: ${dbPath}\n`);
    }
  }
}

async function checkDatabase(dbPath) {
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: `file:${dbPath}`
      }
    }
  });

  try {
    // Obtenir la structure de la table clients
    const tableInfo = await prisma.$queryRawUnsafe(`
      PRAGMA table_info(clients);
    `);

    console.log('📋 Structure de la table "clients":\n');
    console.log('┌──────┬─────────────────────┬───────────┬──────────┐');
    console.log('│ ID   │ Nom Colonne         │ Type      │ Nullable │');
    console.log('├──────┼─────────────────────┼───────────┼──────────┤');
    
    tableInfo.forEach(col => {
      const name = col.name.padEnd(19);
      const type = col.type.padEnd(9);
      const nullable = col.notnull === 0 ? 'Oui' : 'Non';
      console.log(`│ ${String(col.cid).padEnd(4)} │ ${name} │ ${type} │ ${nullable.padEnd(8)} │`);
    });
    
    console.log('└──────┴─────────────────────┴───────────┴──────────┘\n');

    // Vérifier la présence des colonnes NUI et RCCM
    const hasNui = tableInfo.some(col => col.name === 'nui');
    const hasRccm = tableInfo.some(col => col.name === 'rccm');

    console.log('🔍 Vérification des colonnes NUI/RCCM:\n');
    console.log(`   ┌─────────────────────────────────────┐`);
    console.log(`   │ nui:  ${hasNui ? '✅ Présente' : '❌ MANQUANTE'}              │`);
    console.log(`   │ rccm: ${hasRccm ? '✅ Présente' : '❌ MANQUANTE'}              │`);
    console.log(`   └─────────────────────────────────────┘\n`);

    if (!hasNui || !hasRccm) {
      console.log('⚠️ ACTION REQUISE:\n');
      console.log('   Les colonnes NUI et/ou RCCM sont manquantes.');
      console.log('   Exécutez le script de migration:\n');
      console.log('   - Développement : AJOUTER-COLONNES-NUI-RCCM.bat');
      console.log('   - Production    : AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat\n');
    } else {
      console.log('✅ Les colonnes NUI et RCCM sont présentes.\n');
      
      // Compter les clients avec NUI/RCCM renseignés
      const clientsWithNui = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*) as count FROM clients WHERE nui IS NOT NULL AND nui != '';
      `);
      
      const clientsWithRccm = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*) as count FROM clients WHERE rccm IS NOT NULL AND rccm != '';
      `);
      
      const totalClients = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*) as count FROM clients;
      `);
      
      console.log('📊 Statistiques:\n');
      console.log(`   Total clients     : ${totalClients[0].count}`);
      console.log(`   Avec NUI renseigné: ${clientsWithNui[0].count}`);
      console.log(`   Avec RCCM renseigné: ${clientsWithRccm[0].count}\n`);
    }

    console.log('─────────────────────────────────────────────────────────────\n');

  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le diagnostic
checkColumns()
  .then(() => {
    console.log('✓ Diagnostic terminé\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  });
