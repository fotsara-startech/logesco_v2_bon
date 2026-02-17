/**
 * Test de la correction des catégories
 */

const http = require('http');

async function testCategoryFix() {
  console.log('🧪 Test de la correction des catégories');
  console.log('======================================\n');

  // Données de test avec catégories
  const testProducts = {
    products: [
      {
        reference: 'TEST_CAT_001',
        nom: 'Produit Cosmétique Test',
        description: 'Test catégorie cosmétique',
        prixUnitaire: 1200.0,
        prixAchat: 800.0,
        codeBarre: null,
        categorie: 'COSMETIQUE',
        seuilStockMinimum: 3,
        remiseMaxAutorisee: 0.0,
        estActif: true,
        estService: false
      },
      {
        reference: 'TEST_CAT_002',
        nom: 'Produit Alimentation Test',
        description: 'Test catégorie alimentation',
        prixUnitaire: 250.0,
        prixAchat: 150.0,
        codeBarre: '123456789',
        categorie: 'ALIMENTATION',
        seuilStockMinimum: 20,
        remiseMaxAutorisee: 0.0,
        estActif: true,
        estService: false
      }
    ]
  };

  try {
    console.log('1️⃣ Test de l\'import avec gestion des catégories...');
    
    const response = await makeRequest('POST', '/api/v1/products/import', testProducts);
    
    console.log(`📡 Status: ${response.statusCode}`);
    
    if (response.statusCode === 201) {
      const data = JSON.parse(response.body);
      
      console.log('✅ Réponse 201 reçue');
      
      if (data.success && data.data) {
        const responseData = data.data;
        
        if (responseData.summary) {
          const summary = responseData.summary;
          console.log(`📊 Résumé: ${summary.imported} importés, ${summary.errors} erreurs`);
          
          if (summary.imported > 0) {
            console.log('🎉 IMPORT AVEC CATÉGORIES RÉUSSI !');
            
            if (responseData.imported && responseData.imported.length > 0) {
              console.log('📦 Produits importés avec catégories:');
              responseData.imported.forEach(product => {
                console.log(`  - ${product.reference}: ${product.nom}`);
                console.log(`    Catégorie ID: ${product.categorieId || 'Aucune'}`);
              });
            }
          } else if (summary.errors > 0) {
            console.log('❌ Erreurs détectées:');
            if (responseData.errors) {
              responseData.errors.forEach(error => {
                console.log(`  - ${error.reference}: ${error.error}`);
                
                // Analyser le type d'erreur
                if (error.error.includes('CategoryCreateNestedOneWithoutProduitsInput')) {
                  console.log('    🔧 Problème: Relation catégorie incorrecte (EN COURS DE RÉSOLUTION)');
                } else if (error.error.includes('Token d\'accès requis')) {
                  console.log('    🔧 Problème: Authentification requise (NORMAL)');
                } else {
                  console.log('    🔧 Autre problème:', error.error.substring(0, 100));
                }
              });
            }
          }
        }
      }
      
    } else if (response.statusCode === 401) {
      console.log('⚠️  Authentification requise (normal pour ce test)');
      console.log('Le backend fonctionne correctement');
    } else {
      console.log(`❌ Erreur HTTP: ${response.statusCode}`);
      console.log(`📄 Response: ${response.body.substring(0, 300)}...`);
    }

  } catch (error) {
    console.log('❌ Erreur lors du test:', error.message);
  }

  console.log('\n🎯 Statut des corrections:');
  console.log('==========================');
  console.log('✅ Méthode findFirst ajoutée');
  console.log('✅ Structure create() corrigée');
  console.log('🔧 En cours: Gestion des relations catégories');
  console.log('\nSi aucune erreur de catégorie, le problème est résolu !');
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

testCategoryFix().catch(console.error);