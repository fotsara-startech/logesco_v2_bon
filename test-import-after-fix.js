/**
 * Test de l'import après correction Prisma
 */

const http = require('http');

async function testImportAfterFix() {
  console.log('🧪 Test import après correction Prisma');
  console.log('======================================\n');

  // Données de test pour l'import
  const testProducts = {
    products: [
      {
        reference: 'TEST_FIX_001',
        nom: 'Produit Test Fix',
        description: 'Test après correction Prisma',
        prixUnitaire: 1500.0,
        prixAchat: 1000.0,
        codeBarre: null,
        categorie: 'TEST',
        seuilStockMinimum: 5,
        remiseMaxAutorisee: 0.0,
        estActif: true,
        estService: false
      },
      {
        reference: 'TEST_FIX_002',
        nom: 'Service Test Fix',
        description: 'Service test après correction',
        prixUnitaire: 3000.0,
        prixAchat: 0.0,
        codeBarre: null,
        categorie: 'SERVICES',
        seuilStockMinimum: 0,
        remiseMaxAutorisee: 10.0,
        estActif: true,
        estService: true
      }
    ]
  };

  try {
    console.log('1️⃣ Test de l\'API d\'import...');
    
    const response = await makeRequest('POST', '/api/v1/products/import', testProducts);
    
    console.log(`📡 Status: ${response.statusCode}`);
    console.log(`📄 Response: ${response.body.substring(0, 500)}...`);

    if (response.statusCode === 201) {
      const data = JSON.parse(response.body);
      
      console.log('\n2️⃣ Analyse de la réponse...');
      
      if (data.success) {
        console.log('✅ Réponse marquée comme succès');
        
        if (data.data) {
          const responseData = data.data;
          
          if (responseData.summary) {
            const summary = responseData.summary;
            console.log(`📊 Résumé: ${summary.imported} importés, ${summary.errors} erreurs`);
            
            if (summary.imported > 0) {
              console.log('🎉 IMPORT RÉUSSI ! Le problème Prisma est corrigé !');
            } else if (summary.errors > 0) {
              console.log('❌ Erreurs détectées:');
              if (responseData.errors) {
                responseData.errors.forEach(error => {
                  console.log(`  - ${error.reference}: ${error.error}`);
                });
              }
            }
          }
          
          if (responseData.imported && responseData.imported.length > 0) {
            console.log(`✅ ${responseData.imported.length} produits importés avec succès`);
            responseData.imported.forEach(product => {
              console.log(`  - ${product.reference}: ${product.nom}`);
            });
          }
        }
      } else {
        console.log('❌ Réponse marquée comme échec');
      }
      
    } else if (response.statusCode === 401) {
      console.log('⚠️  Erreur d\'authentification (normal pour ce test)');
      console.log('Le backend fonctionne, mais il faut un token d\'authentification');
    } else {
      console.log(`❌ Erreur HTTP: ${response.statusCode}`);
    }

    console.log('\n3️⃣ Test de l\'API des produits...');
    
    const productsResponse = await makeRequest('GET', '/api/v1/products', null);
    console.log(`📡 Status produits: ${productsResponse.statusCode}`);
    
    if (productsResponse.statusCode === 200) {
      console.log('✅ API produits accessible');
    }

  } catch (error) {
    console.log('❌ Erreur lors du test:', error.message);
  }

  console.log('\n🎯 Conclusion:');
  console.log('==============');
  console.log('Si l\'import ne retourne plus l\'erreur "findFirst is not a function",');
  console.log('alors le problème Prisma est résolu !');
  console.log('\nVous pouvez maintenant tester l\'import Excel dans l\'application Flutter.');
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

testImportAfterFix().catch(console.error);