const http = require('http');

/**
 * Test de débogage pour l'import des produits
 * Identifie le problème "models.produit.findFirst is not a function"
 */

async function testBackendImport() {
  console.log('🔍 Test de débogage - Import des produits');
  console.log('==========================================\n');

  // Test 1: Vérifier que le backend répond
  await testBackendHealth();
  
  // Test 2: Tester l'import avec un produit simple
  await testSimpleImport();
  
  // Test 3: Analyser l'erreur Prisma
  await analyzePrismaError();
}

async function testBackendHealth() {
  console.log('1️⃣ Test de santé du backend');
  console.log('---------------------------');
  
  try {
    const response = await makeRequest('GET', '/api/v1/products', null);
    console.log(`✅ Backend accessible - Status: ${response.statusCode}`);
  } catch (error) {
    console.log(`❌ Backend inaccessible: ${error.message}`);
  }
  console.log('');
}

async function testSimpleImport() {
  console.log('2️⃣ Test d\'import simple');
  console.log('------------------------');
  
  const testProduct = {
    products: [{
      reference: 'TEST_DEBUG_001',
      nom: 'Produit Test Debug',
      description: 'Test pour déboguer l\'import',
      prixUnitaire: 1000.0,
      prixAchat: 500.0,
      codeBarre: null,
      categorie: 'TEST',
      seuilStockMinimum: 1,
      remiseMaxAutorisee: 0.0,
      estActif: true,
      estService: false
    }]
  };

  try {
    const response = await makeRequest('POST', '/api/v1/products/import', testProduct);
    console.log(`📡 Réponse: Status ${response.statusCode}`);
    console.log(`📄 Body: ${response.body}`);
    
    if (response.statusCode === 201) {
      const data = JSON.parse(response.body);
      console.log('✅ Réponse parsée avec succès');
      
      if (data.data && data.data.errors && data.data.errors.length > 0) {
        console.log('❌ Erreurs détectées:');
        data.data.errors.forEach(error => {
          console.log(`  - ${error.reference}: ${error.error}`);
        });
      }
      
      if (data.data && data.data.summary) {
        console.log(`📊 Résumé: ${data.data.summary.imported} importés, ${data.data.summary.errors} erreurs`);
      }
    }
  } catch (error) {
    console.log(`❌ Erreur lors du test: ${error.message}`);
  }
  console.log('');
}

async function analyzePrismaError() {
  console.log('3️⃣ Analyse de l\'erreur Prisma');
  console.log('------------------------------');
  
  console.log('🔍 Erreur détectée: "models.produit.findFirst is not a function"');
  console.log('');
  console.log('💡 Causes possibles:');
  console.log('  1. Le modèle Prisma n\'est pas correctement initialisé');
  console.log('  2. Le nom du modèle est incorrect (produit vs Product)');
  console.log('  3. Le client Prisma n\'est pas correctement importé');
  console.log('  4. Problème de génération du client Prisma');
  console.log('');
  console.log('🛠️ Solutions suggérées:');
  console.log('  1. Vérifier le schéma Prisma (schema.prisma)');
  console.log('  2. Régénérer le client Prisma: npx prisma generate');
  console.log('  3. Vérifier l\'import du client dans le backend');
  console.log('  4. Redémarrer le backend après régénération');
  console.log('');
  
  // Test pour vérifier les routes disponibles
  await testAvailableRoutes();
}

async function testAvailableRoutes() {
  console.log('4️⃣ Test des routes disponibles');
  console.log('-------------------------------');
  
  const routes = [
    '/api/v1/products',
    '/api/v1/products/categories',
    '/api/v1/auth/me'
  ];
  
  for (const route of routes) {
    try {
      const response = await makeRequest('GET', route, null);
      console.log(`✅ ${route} - Status: ${response.statusCode}`);
    } catch (error) {
      console.log(`❌ ${route} - Erreur: ${error.message}`);
    }
  }
  console.log('');
}

function makeRequest(method, path, data) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: body
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Exécuter les tests
testBackendImport().catch(console.error);