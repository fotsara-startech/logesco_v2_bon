/**
 * Script de diagnostic pour les remises
 * Vérifie les données de remises dans la base de données
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function debugDiscounts() {
  console.log('🔍 Diagnostic des remises dans la base de données');
  console.log('=' .repeat(60));

  try {
    // 1. Vérifier toutes les ventes
    const totalSales = await prisma.vente.count();
    console.log(`📊 Total des ventes: ${totalSales}`);

    // 2. Vérifier les détails de vente avec remises
    const detailsWithDiscounts = await prisma.detailVente.findMany({
      where: {
        remiseAppliquee: {
          gt: 0
        }
      },
      include: {
        vente: {
          select: {
            id: true,
            numeroVente: true,
            dateVente: true,
            vendeur: {
              select: {
                id: true,
                nomUtilisateur: true
              }
            }
          }
        },
        produit: {
          select: {
            id: true,
            nom: true,
            reference: true
          }
        }
      },
      orderBy: {
        id: 'desc'
      },
      take: 10
    });

    console.log(`💰 Détails avec remises trouvés: ${detailsWithDiscounts.length}`);
    
    if (detailsWithDiscounts.length > 0) {
      console.log('\\n📋 Dernières remises accordées:');
      detailsWithDiscounts.forEach((detail, index) => {
        console.log(`${index + 1}. Vente: ${detail.vente.numeroVente}`);
        console.log(`   Produit: ${detail.produit.nom} (${detail.produit.reference})`);
        console.log(`   Remise: ${detail.remiseAppliquee} FCFA`);
        console.log(`   Prix affiché: ${detail.prixAffiche} FCFA`);
        console.log(`   Prix final: ${detail.prixUnitaire} FCFA`);
        console.log(`   Justification: ${detail.justificationRemise || 'Aucune'}`);
        console.log(`   Date: ${detail.vente.dateVente}`);
        console.log(`   Vendeur: ${detail.vente.vendeur?.nomUtilisateur || 'Inconnu'}`);
        console.log('   ---');
      });
    }

    // 3. Vérifier les ventes avec remises globales
    const salesWithGlobalDiscounts = await prisma.vente.findMany({
      where: {
        montantRemise: {
          gt: 0
        }
      },
      select: {
        id: true,
        numeroVente: true,
        dateVente: true,
        montantRemise: true,
        vendeur: {
          select: {
            nomUtilisateur: true
          }
        }
      },
      orderBy: {
        dateVente: 'desc'
      },
      take: 5
    });

    console.log(`\\n🎯 Ventes avec remises globales: ${salesWithGlobalDiscounts.length}`);
    if (salesWithGlobalDiscounts.length > 0) {
      salesWithGlobalDiscounts.forEach((sale, index) => {
        console.log(`${index + 1}. ${sale.numeroVente} - ${sale.montantRemise} FCFA - ${sale.vendeur?.nomUtilisateur || 'Inconnu'}`);
      });
    }

    // 4. Statistiques générales
    const stats = await prisma.detailVente.aggregate({
      where: {
        remiseAppliquee: {
          gt: 0
        }
      },
      _sum: {
        remiseAppliquee: true
      },
      _count: {
        remiseAppliquee: true
      },
      _avg: {
        remiseAppliquee: true
      },
      _max: {
        remiseAppliquee: true
      }
    });

    console.log('\\n📈 Statistiques des remises:');
    console.log(`   Total des remises: ${stats._sum.remiseAppliquee || 0} FCFA`);
    console.log(`   Nombre de remises: ${stats._count.remiseAppliquee || 0}`);
    console.log(`   Remise moyenne: ${stats._avg.remiseAppliquee?.toFixed(2) || 0} FCFA`);
    console.log(`   Remise maximale: ${stats._max.remiseAppliquee || 0} FCFA`);

    // 5. Tester la requête de l'API (nouvelle logique)
    console.log('\\n🔍 Test de la requête API (nouvelle logique):');
    const apiQuery = await prisma.vente.findMany({
      where: {
        OR: [
          {
            montantRemise: {
              gt: 0
            }
          },
          {
            details: {
              some: {
                remiseAppliquee: {
                  gt: 0
                }
              }
            }
          }
        ]
      },
      include: {
        vendeur: {
          select: {
            id: true,
            nomUtilisateur: true
          }
        },
        details: {
          include: {
            produit: {
              select: {
                id: true,
                nom: true,
                reference: true
              }
            }
          }
        }
      }
    });

    console.log(`   Ventes trouvées par l'API: ${apiQuery.length}`);
    
    if (apiQuery.length > 0) {
      console.log('   Première vente trouvée:');
      const firstSale = apiQuery[0];
      console.log(`   - Numéro: ${firstSale.numeroVente}`);
      console.log(`   - Vendeur: ${firstSale.vendeur?.nomUtilisateur || 'Inconnu'}`);
      console.log(`   - Remise globale: ${firstSale.montantRemise} FCFA`);
      console.log(`   - Nombre de détails: ${firstSale.details.length}`);
      
      const detailsWithDiscounts = firstSale.details.filter(d => d.remiseAppliquee > 0);
      console.log(`   - Détails avec remises: ${detailsWithDiscounts.length}`);
      
      detailsWithDiscounts.forEach((detail, i) => {
        console.log(`     ${i + 1}. ${detail.produit.nom}: ${detail.remiseAppliquee} FCFA`);
      });
    }

  } catch (error) {
    console.error('❌ Erreur lors du diagnostic:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le diagnostic
debugDiscounts().catch(console.error);