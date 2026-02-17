/**
 * Test de la ModelFactory pour identifier le problème
 */

const { PrismaClient } = require('@prisma/client');
const { ModelFactory } = require('./src/models');

async function testModelsFactory() {
  console.log('🧪 Test de la ModelFactory');
  console.log('==========================\n');

  const prisma = new PrismaClient();

  try {
    console.log('1️⃣ Test du client Prisma direct...');
    
    // Test direct du client Prisma
    console.log('Propriétés du client Prisma:');
    const prismaProps = Object.getOwnPropertyNames(prisma).filter(prop => 
      !prop.startsWith('_') && 
      !prop.startsWith('$') && 
      typeof prisma[prop] === 'object' &&
      prisma[prop] !== null
    );
    console.log('  Modèles disponibles:', prismaProps);
    
    if (prisma.produit) {
      console.log('✅ prisma.produit existe');
      console.log('  Type:', typeof prisma.produit);
      console.log('  findFirst:', typeof prisma.produit.findFirst);
    } else {
      console.log('❌ prisma.produit n\'existe pas');
    }

    console.log('\n2️⃣ Test de la ModelFactory...');
    
    // Test de la ModelFactory
    const models = new ModelFactory(prisma);
    
    console.log('Propriétés de models:');
    const modelProps = Object.getOwnPropertyNames(models).filter(prop => !prop.startsWith('_'));
    console.log('  Modèles dans factory:', modelProps);
    
    if (models.produit) {
      console.log('✅ models.produit existe');
      console.log('  Type:', typeof models.produit);
      
      if (models.produit.model) {
        console.log('✅ models.produit.model existe');
        console.log('  Type model:', typeof models.produit.model);
        
        if (typeof models.produit.findFirst === 'function') {
          console.log('✅ models.produit.findFirst est une fonction');
        } else {
          console.log('❌ models.produit.findFirst n\'est pas une fonction');
          console.log('  Type findFirst:', typeof models.produit.findFirst);
        }
      } else {
        console.log('❌ models.produit.model n\'existe pas');
      }
    } else {
      console.log('❌ models.produit n\'existe pas');
    }

    console.log('\n3️⃣ Test des méthodes héritées...');
    
    if (models.produit) {
      // Test des méthodes héritées de BaseModel
      const methods = ['findById', 'findMany', 'count', 'create', 'update', 'delete'];
      
      for (const method of methods) {
        if (typeof models.produit[method] === 'function') {
          console.log(`✅ models.produit.${method} disponible`);
        } else {
          console.log(`❌ models.produit.${method} non disponible`);
        }
      }
    }

    console.log('\n4️⃣ Test simulation findFirst...');
    
    try {
      await prisma.$connect();
      
      // Test direct avec Prisma
      const directResult = await prisma.produit.findFirst();
      console.log('✅ prisma.produit.findFirst() fonctionne');
      
      // Test avec ModelFactory
      if (models.produit && typeof models.produit.findFirst === 'function') {
        const factoryResult = await models.produit.findFirst();
        console.log('✅ models.produit.findFirst() fonctionne');
      } else {
        console.log('❌ models.produit.findFirst() non disponible');
      }
      
    } catch (error) {
      console.log('❌ Erreur lors du test findFirst:', error.message);
    }

  } catch (error) {
    console.log('❌ Erreur générale:', error.message);
    console.log('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }

  console.log('\n🎯 Diagnostic:');
  console.log('==============');
  console.log('Ce test identifie où se situe exactement le problème');
  console.log('dans la chaîne Prisma -> ModelFactory -> Route');
}

testModelsFactory().catch(console.error);