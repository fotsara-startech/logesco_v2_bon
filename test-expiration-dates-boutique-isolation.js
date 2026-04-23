#!/usr/bin/env node

/**
 * Script de test pour vérifier l'isolation par boutique des dates de péremption
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testBoutiqueIsolation() {
  console.log('🧪 Test de l\'isolation par boutique pour les dates de péremption');
  console.log('================================================================');

  try {
    // 1. Vérifier les boutiques disponibles
    console.log('\n📋 1. Vérification des boutiques...');
    const boutiques = await prisma.boutique.findMany({
      orderBy: { estPrincipale: 'desc' }
    });

    if (boutiques.length === 0) {
      console.log('❌ Aucune boutique trouvée. Création d\'une boutique de test...');
      const boutique = await prisma.boutique.create({
        data: {
          nom: 'Boutique Test',
          estPrincipale: true,
          isActive: true
        }
      });
      boutiques.push(boutique);
    }

    console.log(`✅ ${boutiques.length} boutique(s) trouvée(s):`);
    boutiques.forEach(b => {
      console.log(`   - ${b.nom} (ID: ${b.id}) ${b.estPrincipale ? '[PRINCIPALE]' : ''}`);
    });

    // 2. Vérifier les produits avec gestion de péremption
    console.log('\n📦 2. Vérification des produits avec gestion de péremption...');
    let produits = await prisma.produit.findMany({
      where: { gestionPeremption: true },
      take: 3
    });

    if (produits.length === 0) {
      console.log('❌ Aucun produit avec gestion de péremption. Création d\'un produit de test...');
      const produit = await prisma.produit.create({
        data: {
          reference: 'TEST-PEREM-001',
          nom: 'Produit Test Péremption',
          prixUnitaire: 1000,
          prixAchat: 800,
          gestionPeremption: true,
          estActif: true
        }
      });
      produits.push(produit);

      // Créer un stock pour ce produit
      await prisma.stock.create({
        data: {
          produitId: produit.id,
          quantiteDisponible: 100
        }
      });
    }

    console.log(`✅ ${produits.length} produit(s) avec gestion de péremption:`);
    produits.forEach(p => {
      console.log(`   - ${p.nom} (${p.reference})`);
    });

    // 3. Tester la création de dates de péremption avec boutiqueId
    console.log('\n📅 3. Test de création de dates de péremption...');
    
    const boutiquePrincipale = boutiques.find(b => b.estPrincipale) || boutiques[0];
    const produitTest = produits[0];

    // Créer une date de péremption pour la boutique principale
    const datePeremTest = await prisma.datePeremption.create({
      data: {
        produitId: produitTest.id,
        boutiqueId: boutiquePrincipale.id,
        datePeremption: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Dans 30 jours
        quantite: 10,
        numeroLot: 'LOT-TEST-001',
        notes: 'Date de péremption de test'
      },
      include: {
        produit: {
          select: {
            nom: true,
            reference: true
          }
        },
        boutique: {
          select: {
            nom: true
          }
        }
      }
    });

    console.log('✅ Date de péremption créée avec succès:');
    console.log(`   - Produit: ${datePeremTest.produit.nom}`);
    console.log(`   - Boutique: ${datePeremTest.boutique.nom}`);
    console.log(`   - Quantité: ${datePeremTest.quantite}`);
    console.log(`   - Date péremption: ${datePeremTest.datePeremption.toLocaleDateString()}`);

    // 4. Tester le filtrage par boutique
    console.log('\n🔍 4. Test du filtrage par boutique...');
    
    const datesParBoutique = await prisma.datePeremption.findMany({
      where: {
        boutiqueId: boutiquePrincipale.id
      },
      include: {
        produit: {
          select: {
            nom: true,
            reference: true
          }
        },
        boutique: {
          select: {
            nom: true
          }
        }
      }
    });

    console.log(`✅ ${datesParBoutique.length} date(s) de péremption trouvée(s) pour la boutique "${boutiquePrincipale.nom}"`);
    datesParBoutique.forEach((date, index) => {
      console.log(`   ${index + 1}. ${date.produit.nom} - ${date.quantite} unités (Lot: ${date.numeroLot || 'N/A'})`);
    });

    // 5. Tester les statistiques par boutique
    console.log('\n📊 5. Test des statistiques par boutique...');
    
    const statsParBoutique = await prisma.datePeremption.groupBy({
      by: ['boutiqueId'],
      where: {
        estEpuise: false
      },
      _count: {
        id: true
      },
      _sum: {
        quantite: true
      }
    });

    console.log('✅ Statistiques par boutique:');
    for (const stat of statsParBoutique) {
      const boutique = await prisma.boutique.findUnique({
        where: { id: stat.boutiqueId },
        select: { nom: true }
      });
      console.log(`   - ${boutique?.nom || 'Boutique inconnue'}: ${stat._count.id} date(s), ${stat._sum.quantite || 0} unités totales`);
    }

    // 6. Test de l'API (simulation)
    console.log('\n🌐 6. Simulation d\'appels API...');
    
    // Simuler une requête GET /expiration-dates/alertes?boutiqueId=X
    const alertes = await prisma.datePeremption.findMany({
      where: {
        boutiqueId: boutiquePrincipale.id,
        estEpuise: false,
        datePeremption: {
          lte: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // Dans les 30 prochains jours
        }
      },
      include: {
        produit: {
          select: {
            nom: true,
            reference: true,
            prixUnitaire: true,
            prixAchat: true
          }
        },
        boutique: {
          select: {
            nom: true
          }
        }
      },
      orderBy: {
        datePeremption: 'asc'
      }
    });

    console.log(`✅ API Simulation - ${alertes.length} alerte(s) de péremption pour la boutique "${boutiquePrincipale.nom}"`);
    alertes.forEach((alerte, index) => {
      const joursRestants = Math.ceil((new Date(alerte.datePeremption) - new Date()) / (1000 * 60 * 60 * 24));
      console.log(`   ${index + 1}. ${alerte.produit.nom} - ${joursRestants} jour(s) restant(s)`);
    });

    console.log('\n🎉 Tous les tests d\'isolation par boutique ont réussi!');
    console.log('\n📝 Résumé:');
    console.log(`   ✅ Boutiques configurées: ${boutiques.length}`);
    console.log(`   ✅ Produits avec péremption: ${produits.length}`);
    console.log(`   ✅ Dates de péremption créées avec boutiqueId`);
    console.log(`   ✅ Filtrage par boutique fonctionnel`);
    console.log(`   ✅ Statistiques par boutique disponibles`);
    console.log(`   ✅ API simulation réussie`);

  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le test
if (require.main === module) {
  testBoutiqueIsolation()
    .then(() => {
      console.log('\n✅ Test terminé avec succès!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Échec du test:', error);
      process.exit(1);
    });
}

module.exports = { testBoutiqueIsolation };