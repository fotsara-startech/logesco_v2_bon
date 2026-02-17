const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function addTestProductsWithPrices() {
  try {
    console.log('🚀 Ajout de produits de test avec prix...');

    // Créer une catégorie de test
    const category = await prisma.category.upsert({
      where: { nom: 'Électronique' },
      update: {},
      create: {
        nom: 'Électronique',
        description: 'Produits électroniques'
      }
    });

    // Créer des produits avec des prix
    const products = [
      {
        reference: 'PHONE001',
        nom: 'Smartphone Samsung Galaxy',
        description: 'Smartphone Android dernière génération',
        prixUnitaire: 250000,
        prixAchat: 200000,
        categorieId: category.id,
        seuilStockMinimum: 5
      },
      {
        reference: 'LAPTOP001',
        nom: 'Ordinateur Portable HP',
        description: 'Laptop HP 15 pouces',
        prixUnitaire: 450000,
        prixAchat: 380000,
        categorieId: category.id,
        seuilStockMinimum: 3
      },
      {
        reference: 'TABLET001',
        nom: 'Tablette iPad',
        description: 'Tablette Apple iPad',
        prixUnitaire: 320000,
        prixAchat: 280000,
        categorieId: category.id,
        seuilStockMinimum: 2
      },
      {
        reference: 'WATCH001',
        nom: 'Montre Connectée',
        description: 'Smartwatch avec GPS',
        prixUnitaire: 85000,
        prixAchat: 65000,
        categorieId: category.id,
        seuilStockMinimum: 10
      },
      {
        reference: 'HEADPHONE001',
        nom: 'Casque Bluetooth',
        description: 'Casque sans fil haute qualité',
        prixUnitaire: 45000,
        prixAchat: 35000,
        categorieId: category.id,
        seuilStockMinimum: 15
      }
    ];

    for (const product of products) {
      const createdProduct = await prisma.produit.upsert({
        where: { reference: product.reference },
        update: product,
        create: product
      });

      // Créer le stock pour chaque produit
      await prisma.stock.upsert({
        where: { produitId: createdProduct.id },
        update: { quantiteDisponible: Math.floor(Math.random() * 100) + 20 },
        create: {
          produitId: createdProduct.id,
          quantiteDisponible: Math.floor(Math.random() * 100) + 20,
          quantiteReservee: 0
        }
      });

      console.log(`✅ Produit créé: ${product.nom} - Prix: ${product.prixUnitaire} FCFA`);
    }

    console.log('🎉 Produits de test avec prix ajoutés avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors de l\'ajout des produits:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addTestProductsWithPrices();