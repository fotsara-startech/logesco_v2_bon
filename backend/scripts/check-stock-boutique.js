require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function check() {
  // Commandes récentes avec boutiqueId
  const commandes = await prisma.commandeApprovisionnement.findMany({
    where: { statut: 'terminee' },
    select: { id: true, numeroCommande: true, boutiqueId: true, dateCommande: true },
    orderBy: { dateCommande: 'desc' },
    take: 5
  });
  console.log('Commandes récentes:');
  commandes.forEach(c => console.log(JSON.stringify(c)));

  // stock_boutiques pour produit 721
  const sb = await prisma.stockBoutique.findMany({ where: { produitId: 721 } });
  console.log('\nstock_boutiques produit 721:', JSON.stringify(sb));

  // stock global produit 721
  const sg = await prisma.stock.findUnique({ where: { produitId: 721 } });
  console.log('stock global produit 721:', JSON.stringify(sg));

  // Vérifier si le upsert stock_boutiques fonctionne manuellement
  console.log('\nTest upsert stock_boutiques...');
  try {
    const result = await prisma.stockBoutique.upsert({
      where: { boutiqueId_produitId: { boutiqueId: 7, produitId: 721 } },
      create: { boutiqueId: 7, produitId: 721, quantiteDisponible: 0, quantiteReservee: 0 },
      update: { quantiteDisponible: { increment: 0 } }
    });
    console.log('Upsert OK:', JSON.stringify(result));
  } catch (e) {
    console.error('Upsert ERREUR:', e.message);
  }

  await prisma.$disconnect();
}

check().catch(e => { console.error(e.message); process.exit(1); });
