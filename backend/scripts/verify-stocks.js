const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

(async () => {
  try {
    const newStocks = await prisma.stock.findMany({
      where: {
        quantiteDisponible: 0,
        quantiteReservee: 0
      },
      include: {
        produit: {
          select: {
            reference: true,
            nom: true
          }
        }
      },
      take: 10
    });

    console.log('✅ Exemples de produits avec stock à 0:');
    newStocks.forEach(s => {
      console.log(`   - ${s.produit.reference} (${s.produit.nom}): ${s.quantiteDisponible}`);
    });

    const allZeroStocks = await prisma.stock.count({
      where: {
        quantiteDisponible: 0,
        quantiteReservee: 0
      }
    });

    console.log(`\n📊 Total produits avec stock à 0: ${allZeroStocks}`);

    // Vérifier aussi les stocks non-zéro
    const nonZeroStocks = await prisma.stock.count({
      where: {
        OR: [
          { quantiteDisponible: { gt: 0 } },
          { quantiteReservee: { gt: 0 } }
        ]
      }
    });

    console.log(`📊 Total produits avec stock > 0: ${nonZeroStocks}`);

    const totalStocks = await prisma.stock.count();
    console.log(`📊 Total stocks: ${totalStocks}`);

    process.exit(0);
  } catch (error) {
    console.error('Erreur:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
})();
