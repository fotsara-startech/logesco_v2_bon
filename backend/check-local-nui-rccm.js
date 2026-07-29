const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${process.env.LOCALAPPDATA}/LOGESCO/backend/database/logesco.db`
    }
  }
});

async function checkLocal() {
  try {
    console.log('💾 Base SQLite locale\n');
    
    // Vérifier les colonnes
    console.log('📋 Structure de la table clients:');
    const columns = await prisma.$queryRawUnsafe("PRAGMA table_info(clients)");
    columns.forEach(col => {
      console.log(`  - ${col.name} (${col.type})`);
    });
    
    // Vérifier les données
    console.log('\n📊 Données clients (5 premiers):');
    const clients = await prisma.$queryRawUnsafe(`
      SELECT id, nom, prenom, nui, rccm 
      FROM clients 
      ORDER BY id DESC 
      LIMIT 5
    `);
    
    if (clients.length === 0) {
      console.log('  Aucun client trouvé');
    } else {
      clients.forEach(c => {
        console.log(`  #${c.id}: ${c.nom} ${c.prenom || ''}`);
        console.log(`    NUI: ${c.nui || '(vide)'}`);
        console.log(`    RCCM: ${c.rccm || '(vide)'}`);
      });
    }
    
    // Statistiques
    const stats = await prisma.$queryRawUnsafe(`
      SELECT 
        COUNT(*) as total,
        COUNT(nui) as avec_nui,
        COUNT(rccm) as avec_rccm
      FROM clients
    `);
    
    console.log('\n📈 Statistiques:');
    console.log(`  Total clients: ${stats[0].total}`);
    console.log(`  Avec NUI: ${stats[0].avec_nui}`);
    console.log(`  Avec RCCM: ${stats[0].avec_rccm}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkLocal();
