/**
 * Test des modèles Prisma après régénération
 */

const { PrismaClient } = require('@prisma/client');

async function testPrismaModels() {
  console.log('🧪 Test des modèles Prisma');
  console.log('=========================\n');

  const prisma = new PrismaClient();

  try {
    console.log('1️⃣ Test import PrismaClient...');
    console.log('✅ Client Prisma importé avec succès');

    console.log('\n2️⃣ Test modèle produit...');
    
    if (prisma.produit) {
      console.log('✅ Modèle produit accessible');
      
      if (typeof prisma.produit.findFirst === 'function') {
        console.log('✅ Méthode findFirst disponible');
      } else {
        console.log('❌ Méthode findFirst non disponible');
        console.log('Type de produit.findFirst:', typeof prisma.produit.findFirst);
      }

      if (typeof prisma.produit.create === 'function') {
        console.log('✅ Méthode create disponible');
      } else {
        console.log('❌ Méthode create non disponible');
      }

      if (typeof prisma.produit.findMany === 'function') {
        console.log('✅ Méthode findMany disponible');
      } else {
        console.log('❌ Méthode findMany non disponible');
      }

    } else {
      console.log('❌ Modèle produit non accessible');
      console.log('Modèles disponibles:', Object.keys(prisma).filter(key => !key.startsWith('_') && !key.startsWith('$')));
    }

    console.log('\n3️⃣ Test connexion base de données...');
    
    try {
      await prisma.$connect();
      console.log('✅ Connexion à la base réussie');

      // Test d'une requête simple
      const count = await prisma.produit.count();
      console.log(`✅ Requête count réussie: ${count} produits`);

      // Test findFirst
      const firstProduct = await prisma.produit.findFirst();
      console.log('✅ Requête findFirst réussie:', firstProduct ? 'Produit trouvé' : 'Aucun produit');

    } catch (dbError) {
      console.log('❌ Erreur base de données:', dbError.message);
    }

    console.log('\n4️⃣ Test simulation import...');
    
    try {
      // Simuler la vérification d'un produit existant (comme dans l'import)
      const existingProduct = await prisma.produit.findFirst({
        where: {
          reference: 'TEST_SIMULATION'
        }
      });

      console.log('✅ Simulation findFirst réussie');
      console.log('Produit existant:', existingProduct ? 'Trouvé' : 'Non trouvé');

    } catch (simulationError) {
      console.log('❌ Erreur simulation:', simulationError.message);
    }

  } catch (error) {
    console.log('❌ Erreur générale:', error.message);
    console.log('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }

  console.log('\n🎯 Résultat du test:');
  console.log('===================');
  console.log('Si tous les tests sont ✅, le problème backend devrait être résolu.');
  console.log('Redémarrez le backend avec: npm run dev');
}

testPrismaModels().catch(console.error);