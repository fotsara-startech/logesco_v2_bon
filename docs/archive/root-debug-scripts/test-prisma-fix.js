/**
 * Test et correction du problème Prisma
 */

console.log('🔧 Test du client Prisma');
console.log('========================\n');

async function testPrismaClient() {
  try {
    // Test 1: Import du client Prisma
    console.log('1️⃣ Test import PrismaClient...');
    const { PrismaClient } = require('./backend/node_modules/@prisma/client');
    console.log('✅ Import PrismaClient réussi');

    // Test 2: Création d'une instance
    console.log('\n2️⃣ Test création instance...');
    const prisma = new PrismaClient();
    console.log('✅ Instance Prisma créée');

    // Test 3: Vérification des modèles disponibles
    console.log('\n3️⃣ Test modèles disponibles...');
    
    // Lister les propriétés du client Prisma
    const models = Object.getOwnPropertyNames(prisma).filter(prop => 
      !prop.startsWith('_') && 
      !prop.startsWith('$') && 
      typeof prisma[prop] === 'object' &&
      prisma[prop] !== null
    );
    
    console.log('📋 Modèles détectés:', models);
    
    // Test spécifique pour le modèle produit
    if (prisma.produit) {
      console.log('✅ Modèle "produit" accessible');
      
      // Test d'une méthode
      if (typeof prisma.produit.findFirst === 'function') {
        console.log('✅ Méthode "findFirst" disponible');
      } else {
        console.log('❌ Méthode "findFirst" non disponible');
      }
    } else {
      console.log('❌ Modèle "produit" non accessible');
      
      // Vérifier les alternatives
      if (prisma.Produit) {
        console.log('⚠️  Modèle "Produit" (majuscule) trouvé');
      }
    }

    // Test 4: Test de connexion à la base
    console.log('\n4️⃣ Test connexion base de données...');
    try {
      await prisma.$connect();
      console.log('✅ Connexion à la base réussie');
      
      // Test d'une requête simple
      const count = await prisma.produit.count();
      console.log(`✅ Requête test réussie: ${count} produits en base`);
      
    } catch (dbError) {
      console.log('❌ Erreur connexion base:', dbError.message);
    }

    await prisma.$disconnect();
    
  } catch (error) {
    console.log('❌ Erreur:', error.message);
    console.log('📄 Stack:', error.stack);
  }
}

// Test de la structure du schéma
function analyzeSchema() {
  console.log('\n5️⃣ Analyse du schéma Prisma...');
  
  try {
    const fs = require('fs');
    const schemaPath = './backend/prisma/schema.prisma';
    
    if (fs.existsSync(schemaPath)) {
      const schema = fs.readFileSync(schemaPath, 'utf8');
      
      // Rechercher les modèles
      const modelMatches = schema.match(/model\s+(\w+)\s*{/g);
      if (modelMatches) {
        const models = modelMatches.map(match => match.match(/model\s+(\w+)/)[1]);
        console.log('📋 Modèles dans le schéma:', models);
        
        if (models.includes('Produit')) {
          console.log('✅ Modèle "Produit" trouvé dans le schéma');
        }
      }
    } else {
      console.log('❌ Fichier schema.prisma non trouvé');
    }
  } catch (error) {
    console.log('❌ Erreur analyse schéma:', error.message);
  }
}

// Exécuter les tests
async function runTests() {
  analyzeSchema();
  await testPrismaClient();
  
  console.log('\n🎯 Résumé des corrections nécessaires:');
  console.log('=====================================');
  console.log('1. Vérifier que le client Prisma est correctement généré');
  console.log('2. S\'assurer que le modèle "produit" (minuscule) est accessible');
  console.log('3. Redémarrer le backend après régénération');
  console.log('4. Vérifier les permissions de fichiers sur Windows');
}

runTests().catch(console.error);