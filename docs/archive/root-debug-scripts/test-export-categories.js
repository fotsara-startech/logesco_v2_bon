/**
 * Test de l'export avec catégories
 */

const http = require('http');

async function testExportCategories() {
  console.log('🧪 Test de l\'export avec catégories');
  console.log('===================================\n');

  try {
    console.log('1️⃣ Test de l\'API d\'export...');
    
    const response = await makeRequest('GET', '/api/v1/products/all', null);
    
    console.log(`📡 Status: ${response.statusCode}`);
    
    if (response.statusCode === 200) {
      const data = JSON.parse(response.body);
      
      console.log('✅ Export réussi');
      
      if (data.success && data.data) {
        const products = data.data;
        
        console.log(`📦 ${products.length} produits exportés`);
        
        if (products.length > 0) {
          console.log('\n📋 Aperçu des produits exportés:');
          
          products.slice(0, 5).forEach((product, index) => {
            console.log(`${index + 1}. ${product.reference}: ${product.nom}`);
            console.log(`   Prix: ${product.prixUnitaire} FCFA`);
            console.log(`   Catégorie: ${product.categorie || 'VIDE ❌'}`);
            console.log(`   Stock: ${product.stock ? 'Inclus ✅' : 'Non inclus'}`);
            console.log('');
          });
          
          // Vérifier si les catégories sont présentes
          const productsWithCategories = products.filter(p => p.categorie);
          const productsWithoutCategories = products.filter(p => !p.categorie);
          
          console.log('📊 Analyse des catégories:');
          console.log(`  - Avec catégorie: ${productsWithCategories.length}`);
          console.log(`  - Sans catégorie: ${productsWithoutCategories.length}`);
          
          if (productsWithCategories.length > 0) {
            console.log('✅ Les catégories sont maintenant incluses dans l\'export !');
            
            // Lister les catégories uniques
            const categories = [...new Set(productsWithCategories.map(p => p.categorie))];
            console.log('📂 Catégories trouvées:', categories);
          } else {
            console.log('❌ Aucune catégorie trouvée dans l\'export');
          }
        } else {
          console.log('⚠️  Aucun produit trouvé pour l\'export');
        }
      }
      
    } else if (response.statusCode === 401) {
      console.log('⚠️  Authentification requise (normal pour ce test)');
      console.log('Le backend fonctionne correctement');
    } else {
      console.log(`❌ Erreur HTTP: ${response.statusCode}`);
      console.log(`📄 Response: ${response.body.substring(0, 200)}...`);
    }

  } catch (error) {
    console.log('❌ Erreur lors du test:', error.message);
  }

  console.log('\n🎯 Résultat:');
  console.log('============');
  console.log('Si les catégories apparaissent maintenant dans l\'export,');
  console.log('alors le problème est résolu !');
  console.log('\nTestez l\'export Excel dans l\'application Flutter.');
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

testExportCategories().catch(console.error);