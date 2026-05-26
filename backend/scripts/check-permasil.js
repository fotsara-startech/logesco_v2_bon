require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function check() {
  // Trouver Permasil
  const produit = await prisma.produit.findFirst({
    where: { nom: { contains: 'Permasil' } },
    include: { stock: true, stocksBoutiques: true }
  });
  
  if (!produit) { console.log('Produit Permasil non trouvé'); return; }
  
  console.log(`Produit: ${produit.nom} (ID: ${produit.id})`);
  console.log(`Stock global:`, produit.stock);
  console.log(`Stock boutiques:`, produit.stocksBoutiques);

  // Mouvements récents
  const mvts = await prisma.mouvementStock.findMany({
    where: { produitId: produit.id },
    orderBy: { dateMouvement: 'desc' },
    take: 5
  });
  console.log(`\nMouvements récents:`);
  mvts.forEach(m => console.log(`  ID ${m.id}: ${m.typeMouvement} +${m.changementQuantite} boutique=${m.boutiqueId} ref=${m.referenceId} date=${m.dateMouvement.toISOString().split('T')[0]}`));

  // Commandes récentes pour ce produit
  const details = await prisma.detailCommandeApprovisionnement.findMany({
    where: { produitId: produit.id },
    include: { commande: { select: { id: true, numeroCommande: true, boutiqueId: true, statut: true } } },
    orderBy: { id: 'desc' },
    take: 5
  });
  console.log(`\nDétails commandes récents:`);
  details.forEach(d => console.log(`  Commande ${d.commande.numeroCommande} (boutique=${d.commande.boutiqueId}, statut=${d.commande.statut}): commandé=${d.quantiteCommandee}, reçu=${d.quantiteRecue}`));

  // Queue de sync pour ce produit
  const queue = await prisma.$queryRawUnsafe(
    `SELECT id, table_name, operation, record_id, synced, error, created_at FROM sync_queue 
     WHERE (table_name = 'stock_boutiques' OR table_name = 'stock') AND synced = 0
     ORDER BY id DESC LIMIT 10`
  );
  console.log(`\nQueue sync stock (non synchronisé):`, queue.length, 'entrées');
  queue.slice(0, 3).forEach(q => console.log(`  ${q.table_name} op=${q.operation} id=${q.record_id}`));

  await prisma.$disconnect();
}

check().catch(e => { console.error(e.message); process.exit(1); });
