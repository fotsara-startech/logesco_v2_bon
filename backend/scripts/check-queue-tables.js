require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function run() {
  // Queue par table (non synchronisé)
  const byTable = await prisma.$queryRawUnsafe(
    'SELECT table_name, COUNT(*) as count FROM sync_queue WHERE synced=0 GROUP BY table_name ORDER BY count DESC'
  );
  console.log('Queue en attente par table:');
  byTable.forEach(r => console.log(`  ${r.table_name}: ${r.count}`));

  // Vérifier si mouvements_stock est dans la queue
  const mvtStock = await prisma.$queryRawUnsafe(
    "SELECT COUNT(*) as count FROM sync_queue WHERE table_name = 'mouvements_stock'"
  );
  console.log(`\nmouvements_stock dans queue (total): ${mvtStock[0].count}`);

  // Derniers mouvements de stock locaux
  const mvts = await prisma.mouvementStock.findMany({
    orderBy: { dateMouvement: 'desc' },
    take: 5,
    select: { id: true, typeMouvement: true, changementQuantite: true, produitId: true, boutiqueId: true, dateMouvement: true }
  });
  console.log('\nDerniers mouvements de stock locaux:');
  mvts.forEach(m => console.log(`  ID ${m.id}: ${m.typeMouvement} ${m.changementQuantite > 0 ? '+' : ''}${m.changementQuantite} produit=${m.produitId} boutique=${m.boutiqueId} date=${m.dateMouvement.toISOString().split('T')[0]}`));

  await prisma.$disconnect();
}
run().catch(e => { console.error(e.message); process.exit(1); });
