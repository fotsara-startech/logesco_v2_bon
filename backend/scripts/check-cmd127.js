require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function check() {
  const commande = await prisma.commandeApprovisionnement.findUnique({
    where: { id: 127 },
    include: { details: { include: { produit: { select: { id: true, nom: true } } } } }
  });
  console.log('Commande 127:', JSON.stringify({
    id: commande.id,
    numero: commande.numeroCommande,
    boutiqueId: commande.boutiqueId,
    statut: commande.statut,
    details: commande.details.map(d => ({
      id: d.id,
      produit: d.produit.nom,
      produitId: d.produitId,
      commandee: d.quantiteCommandee,
      recue: d.quantiteRecue
    }))
  }, null, 2));

  // Vérifier stock_boutiques pour produit 724 boutique 7
  const sb = await prisma.stockBoutique.findUnique({
    where: { boutiqueId_produitId: { boutiqueId: 7, produitId: 724 } }
  });
  console.log('\nstock_boutiques produit 724 boutique 7:', sb);

  // Tester le upsert manuellement
  console.log('\nTest upsert manuel...');
  const result = await prisma.stockBoutique.upsert({
    where: { boutiqueId_produitId: { boutiqueId: 7, produitId: 724 } },
    create: { boutiqueId: 7, produitId: 724, quantiteDisponible: 11, quantiteReservee: 0 },
    update: { quantiteDisponible: { increment: 11 } }
  });
  console.log('Résultat upsert:', result);

  await prisma.$disconnect();
}
check().catch(e => { console.error(e.message); process.exit(1); });
