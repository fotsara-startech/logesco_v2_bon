/**
 * Migre le stock global (table `stock`) vers `stock_boutiques` pour la boutique principale.
 * À exécuter une seule fois sur les bases existantes.
 */
process.env.DATABASE_URL = process.env.DATABASE_URL || 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const prisma = getPrismaClient();

async function main() {
  console.log('🔄 Migration du stock global vers stock_boutiques...\n');

  // Trouver la boutique principale
  const boutiquePrincipale = await prisma.boutique.findFirst({ where: { estPrincipale: true } });
  if (!boutiquePrincipale) {
    console.error('❌ Aucune boutique principale trouvée. Exécutez d\'abord init-boutique-principale.js');
    process.exit(1);
  }
  console.log(`✅ Boutique principale: "${boutiquePrincipale.nom}" (id: ${boutiquePrincipale.id})`);

  // Récupérer tout le stock global
  const stocks = await prisma.stock.findMany({
    include: { produit: { select: { nom: true, reference: true } } }
  });
  console.log(`📦 ${stocks.length} entrées de stock à migrer\n`);

  let created = 0, updated = 0, skipped = 0;

  for (const stock of stocks) {
    if (stock.quantiteDisponible <= 0 && stock.quantiteReservee <= 0) {
      skipped++;
      continue;
    }

    try {
      await prisma.stockBoutique.upsert({
        where: { boutiqueId_produitId: { boutiqueId: boutiquePrincipale.id, produitId: stock.produitId } },
        update: {
          quantiteDisponible: stock.quantiteDisponible,
          quantiteReservee: stock.quantiteReservee
        },
        create: {
          boutiqueId: boutiquePrincipale.id,
          produitId: stock.produitId,
          quantiteDisponible: stock.quantiteDisponible,
          quantiteReservee: stock.quantiteReservee
        }
      });

      const existing = await prisma.stockBoutique.findUnique({
        where: { boutiqueId_produitId: { boutiqueId: boutiquePrincipale.id, produitId: stock.produitId } }
      });
      if (existing) updated++; else created++;

    } catch (e) {
      console.warn(`  ⚠️ Erreur pour produit ${stock.produitId} (${stock.produit?.nom}): ${e.message}`);
    }
  }

  console.log(`\n✅ Migration terminée:`);
  console.log(`   - Créés/mis à jour: ${created + updated}`);
  console.log(`   - Ignorés (stock 0): ${skipped}`);

  // Vérification
  const total = await prisma.stockBoutique.count({ where: { boutiqueId: boutiquePrincipale.id } });
  console.log(`   - Total dans stock_boutiques pour boutique principale: ${total}`);

  await prisma.$disconnect();
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
