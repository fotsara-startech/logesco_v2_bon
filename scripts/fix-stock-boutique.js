/**
 * Corrige les stocks boutique manquants en recalculant depuis les mouvements de stock
 * Pour les commandes dont le stock_boutiques n'a pas été mis à jour
 */

require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function fixStockBoutique() {
  console.log('🔧 Correction des stocks boutique manquants\n');
  console.log('═'.repeat(60));

  try {
    // Trouver tous les mouvements de stock de type achat avec boutiqueId
    // et vérifier si le stock_boutiques a bien été mis à jour
    const mouvements = await prisma.mouvementStock.findMany({
      where: {
        typeMouvement: 'achat',
        boutiqueId: { not: null }
      },
      orderBy: { dateMouvement: 'asc' }
    });

    console.log(`📊 ${mouvements.length} mouvements d'achat avec boutique trouvés\n`);

    // Grouper par (boutiqueId, produitId) et calculer le total des achats
    const stockMap = {};
    for (const mvt of mouvements) {
      const key = `${mvt.boutiqueId}_${mvt.produitId}`;
      if (!stockMap[key]) {
        stockMap[key] = { boutiqueId: mvt.boutiqueId, produitId: mvt.produitId, totalAchats: 0 };
      }
      stockMap[key].totalAchats += mvt.changementQuantite;
    }

    // Aussi prendre en compte les mouvements de vente (sorties)
    const mouvementsVente = await prisma.mouvementStock.findMany({
      where: {
        typeMouvement: { in: ['vente', 'sortie', 'ajustement_negatif'] },
        boutiqueId: { not: null }
      }
    });

    for (const mvt of mouvementsVente) {
      const key = `${mvt.boutiqueId}_${mvt.produitId}`;
      if (stockMap[key]) {
        stockMap[key].totalAchats += mvt.changementQuantite; // changementQuantite est négatif pour les sorties
      }
    }

    let fixed = 0;
    let skipped = 0;

    for (const [key, data] of Object.entries(stockMap)) {
      const { boutiqueId, produitId, totalAchats } = data;

      // Récupérer le stock actuel
      const stockActuel = await prisma.stockBoutique.findUnique({
        where: { boutiqueId_produitId: { boutiqueId, produitId } }
      });

      const qteActuelle = stockActuel?.quantiteDisponible || 0;
      const qteTotale = Math.max(0, totalAchats); // Ne pas aller en négatif

      if (qteActuelle !== qteTotale) {
        console.log(`🔧 Produit ${produitId} Boutique ${boutiqueId}: ${qteActuelle} → ${qteTotale} (diff: ${qteTotale - qteActuelle})`);

        await prisma.stockBoutique.upsert({
          where: { boutiqueId_produitId: { boutiqueId, produitId } },
          create: {
            boutiqueId,
            produitId,
            quantiteDisponible: qteTotale,
            quantiteReservee: 0
          },
          update: {
            quantiteDisponible: qteTotale
          }
        });
        fixed++;
      } else {
        skipped++;
      }
    }

    console.log(`\n✅ ${fixed} stock(s) corrigé(s), ${skipped} déjà correct(s)`);
    console.log('\nℹ️  Redémarrez le serveur pour que les changements soient synchronisés vers Neon');

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

fixStockBoutique();
