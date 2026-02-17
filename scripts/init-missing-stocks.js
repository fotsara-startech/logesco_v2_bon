#!/usr/bin/env node

/**
 * Script d'initialisation du stock pour tous les produits n'ayant pas de stock
 * Exécuter avec: node backend/scripts/init-missing-stocks.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function initializeMissingStocks() {
  try {
    console.log('🔄 Initialisation des stocks manquants...');
    console.log('');

    // 1. Compter les produits sans stock
    const productsWithoutStock = await prisma.produit.findMany({
      where: {
        estActif: true,
        estService: false,
        stock: {
          is: null
        }
      },
      select: {
        id: true,
        reference: true,
        nom: true
      }
    });

    console.log(`📊 Produits sans stock détectés: ${productsWithoutStock.length}`);
    console.log('');

    if (productsWithoutStock.length === 0) {
      console.log('✅ Tous les produits actifs ont un stock!');
      process.exit(0);
    }

    // 2. Créer des stocks pour tous les produits sans stock
    console.log('📝 Création des stocks manquants...');
    console.log('');

    let successCount = 0;
    let errorCount = 0;

    for (const product of productsWithoutStock) {
      try {
        await prisma.stock.create({
          data: {
            produitId: product.id,
            quantiteDisponible: 0,
            quantiteReservee: 0
          }
        });
        successCount++;
        console.log(`✅ ${product.reference} - ${product.nom}`);
      } catch (error) {
        errorCount++;
        console.log(`❌ ${product.reference} - ${product.nom}: ${error.message}`);
      }
    }

    console.log('');
    console.log('════════════════════════════════════════════');
    console.log(`✅ Stocks créés avec succès: ${successCount}`);
    console.log(`❌ Erreurs: ${errorCount}`);
    console.log('════════════════════════════════════════════');

    // 3. Vérifier le résultat final
    const finalStats = await prisma.produit.findMany({
      where: {
        estActif: true,
        estService: false
      },
      select: {
        stock: {
          select: {
            quantiteDisponible: true
          }
        }
      }
    });

    const withStock = finalStats.filter(p => p.stock !== null).length;
    const withoutStock = finalStats.filter(p => p.stock === null).length;

    console.log('');
    console.log('📈 Vérification finale:');
    console.log(`   Produits physiques actifs avec stock: ${withStock}`);
    console.log(`   Produits physiques actifs sans stock: ${withoutStock}`);
    console.log('');

    if (withoutStock === 0) {
      console.log('🎉 Migration complète!');
    } else {
      console.log('⚠️ Certains produits n\'ont toujours pas de stock');
    }

    process.exit(0);

  } catch (error) {
    console.error('💥 Erreur lors de l\'initialisation:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration
initializeMissingStocks();
