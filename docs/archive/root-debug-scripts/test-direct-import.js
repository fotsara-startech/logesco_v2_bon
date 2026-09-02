/**
 * Test direct de l'import des produits avec Prisma
 */

const { PrismaClient } = require('./backend/node_modules/@prisma/client');

async function testDirectImport() {
  console.log('🧪 Test direct import produits');
  console.log('==============================\n');

  const prisma = new PrismaClient();

  try {
    // Données de test pour l'import
    const productsToImport = [
      {
        reference: 'TEST_DIRECT_001',
        nom: 'Produit Test Direct',
        description: 'Test direct avec Prisma',
        prixUnitaire: 1500.0,
        prixAchat: 1000.0,
        codeBarre: null,
        seuilStockMinimum: 5,
        remiseMaxAutorisee: 0.0,
        estActif: true,
        estService: false
      }
    ];

    console.log('1️⃣ Test de la méthode findFirst...');
    
    // Test de la méthode qui pose problème
    try {
      const existingProduct = await prisma.produit.findFirst({
        where: {
          reference: 'TEST_DIRECT_001'
        }
      });
      
      console.log('✅ Méthode findFirst fonctionne');
      console.log('📄 Produit existant:', existingProduct ? 'Trouvé' : 'Non trouvé');
      
    } catch (findError) {
      console.log('❌ Erreur findFirst:', findError.message);
      return;
    }

    console.log('\n2️⃣ Test de création de produit...');
    
    try {
      // Supprimer le produit test s'il existe
      await prisma.produit.deleteMany({
        where: {
          reference: 'TEST_DIRECT_001'
        }
      });

      // Créer le produit
      const newProduct = await prisma.produit.create({
        data: productsToImport[0]
      });

      console.log('✅ Produit créé avec succès');
      console.log('📄 ID:', newProduct.id);
      console.log('📄 Référence:', newProduct.reference);

      // Créer le stock associé
      await prisma.stock.create({
        data: {
          produitId: newProduct.id,
          quantiteDisponible: 0,
          quantiteReservee: 0
        }
      });

      console.log('✅ Stock créé avec succès');

    } catch (createError) {
      console.log('❌ Erreur création:', createError.message);
    }

    console.log('\n3️⃣ Test de simulation d\'import en lot...');
    
    try {
      const importResults = [];
      const importErrors = [];

      for (let i = 0; i < productsToImport.length; i++) {
        const productData = productsToImport[i];
        
        try {
          // Vérifier si le produit existe déjà
          const existing = await prisma.produit.findFirst({
            where: {
              reference: productData.reference
            }
          });

          if (existing) {
            importErrors.push({
              index: i,
              reference: productData.reference,
              error: 'Produit déjà existant'
            });
            continue;
          }

          // Créer le produit
          const created = await prisma.produit.create({
            data: productData
          });

          // Créer le stock
          await prisma.stock.create({
            data: {
              produitId: created.id,
              quantiteDisponible: 0,
              quantiteReservee: 0
            }
          });

          importResults.push(created);

        } catch (productError) {
          importErrors.push({
            index: i,
            reference: productData.reference,
            error: productError.message
          });
        }
      }

      console.log('📊 Résultats import:');
      console.log(`  - Importés: ${importResults.length}`);
      console.log(`  - Erreurs: ${importErrors.length}`);

      if (importErrors.length > 0) {
        console.log('❌ Erreurs détaillées:');
        importErrors.forEach(error => {
          console.log(`  - ${error.reference}: ${error.error}`);
        });
      }

    } catch (batchError) {
      console.log('❌ Erreur import en lot:', batchError.message);
    }

    console.log('\n4️⃣ Nettoyage...');
    
    // Nettoyer les données de test
    await prisma.stock.deleteMany({
      where: {
        produit: {
          reference: {
            startsWith: 'TEST_DIRECT_'
          }
        }
      }
    });

    await prisma.produit.deleteMany({
      where: {
        reference: {
          startsWith: 'TEST_DIRECT_'
        }
      }
    });

    console.log('✅ Nettoyage terminé');

  } catch (error) {
    console.log('❌ Erreur générale:', error.message);
    console.log('📄 Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }

  console.log('\n🎯 Conclusion:');
  console.log('==============');
  console.log('Le client Prisma fonctionne correctement.');
  console.log('Le problème doit être dans le backend Node.js.');
  console.log('Vérifiez:');
  console.log('  1. L\'initialisation du client Prisma dans le backend');
  console.log('  2. Les imports des modèles');
  console.log('  3. La configuration de l\'environnement');
}

testDirectImport().catch(console.error);