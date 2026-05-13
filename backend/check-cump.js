const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const rows = await prisma.$queryRawUnsafe(
    'SELECT id, nom, prix_achat, cump FROM produits WHERE prix_achat IS NOT NULL LIMIT 10'
  );
  console.log('Produits (prix_achat vs cump):');
  rows.forEach(r => console.log(`  id=${r.id} | prix_achat=${r.prix_achat} | cump=${r.cump} | nom=${r.nom}`));

  // Vérifier la requête de valorisation
  const val = await prisma.$queryRawUnsafe(
    'SELECT SUM(s.quantite_disponible * COALESCE(p.cump, p.prix_achat, p.prix_unitaire * 0.8)) as valeurAchat, SUM(s.quantite_disponible * p.prix_unitaire) as valeurVente FROM stock s INNER JOIN produits p ON s.produit_id = p.id WHERE p.est_actif = 1'
  );
  console.log('\nValorisation calculée:', val[0]);

  await prisma.$disconnect();
}
run().catch(e => { console.error(e.message); process.exit(1); });
