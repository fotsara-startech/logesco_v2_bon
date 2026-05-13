const { PrismaClient } = require('@prisma/client');
const { recalculerCump, enregistrerPrixAchatEtRecalculerCump } = require('./src/services/cump-service');
const prisma = new PrismaClient();

async function run() {
  console.log('=== Test formule CUMP pondérée ===\n');

  // Vérifier Olay cleanse (id=709) : prix_achat=12000, cump attendu=10500
  const olay = await prisma.$queryRawUnsafe(
    'SELECT id, nom, prix_achat, cump FROM produits WHERE id = 709'
  );
  console.log('Olay cleanse:', olay[0]);

  const hist = await prisma.$queryRawUnsafe(
    'SELECT prix_achat, quantite, source FROM historique_prix_achat WHERE produit_id = 709'
  );
  console.log('Historique:', hist);

  // Recalculer manuellement pour vérifier
  const totalQte  = hist.reduce((s, r) => s + (r.quantite || 1), 0);
  const totalCout = hist.reduce((s, r) => s + ((r.prix_achat || 0) * (r.quantite || 1)), 0);
  console.log(`\nFormule: (${hist.map(r => `${r.quantite}×${r.prix_achat}`).join(' + ')}) / ${totalQte} = ${totalCout/totalQte}`);

  await prisma.$disconnect();
}
run().catch(e => { console.error(e.message); process.exit(1); });
