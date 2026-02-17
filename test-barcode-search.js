const http = require('http');

// Test de la recherche par code-barres
async function testBarcodeSearch() {
  console.log('🧪 Test de la recherche par code-barres');
  
  try {
    // 1. Se connecter en tant qu'admin
    const loginData = JSON.stringify({
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    console.log('1. Connexion admin...');
    const loginResponse = await makeRequest(loginOptions, loginData);
    const loginResult = JSON.parse(loginResponse);
    
    if (!loginResult.success) {
      console.error('❌ Échec connexion:', loginResult.message);
      return;
    }

    const token = loginResult.data.token;
    console.log('✅ Connexion réussie');

    // 2. Tester la recherche générale (doit inclure les codes-barres maintenant)
    console.log('\n2. Test recherche générale avec code-barre...');
    
    const searchOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products?q=5449000000996', // Code-barre Coca-Cola du seed
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    const searchResponse = await makeRequest(searchOptions);
    const searchResult = JSON.parse(searchResponse);
    
    console.log(`📊 Recherche générale - Statut: ${searchResult.success ? 'SUCCÈS' : 'ÉCHEC'}`);
    if (searchResult.success && searchResult.data) {
      console.log(`📊 Produits trouvés: ${searchResult.data.length}`);
      if (searchResult.data.length > 0) {
        const product = searchResult.data[0];
        console.log(`📊 Premier produit: ${product.nom} (Code: ${product.codeBarre})`);
      }
    }

    // 3. Tester la route spécifique de recherche par code-barre
    console.log('\n3. Test route spécifique code-barre...');
    
    const barcodeOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products/barcode/5449000000996', // Code-barre Coca-Cola
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    const barcodeResponse = await makeRequest(barcodeOptions);
    const barcodeResult = JSON.parse(barcodeResponse);
    
    console.log(`📊 Recherche spécifique - Statut: ${barcodeResult.success ? 'SUCCÈS' : 'ÉCHEC'}`);
    if (barcodeResult.success && barcodeResult.data) {
      const product = barcodeResult.data;
      console.log(`📊 Produit trouvé: ${product.nom}`);
      console.log(`📊 Référence: ${product.reference}`);
      console.log(`📊 Code-barre: ${product.codeBarre}`);
      console.log(`📊 Prix: ${product.prixUnitaire} FCFA`);
    } else {
      console.log(`📊 Erreur: ${barcodeResult.message}`);
    }

    // 4. Tester avec un code-barre inexistant
    console.log('\n4. Test code-barre inexistant...');
    
    const invalidBarcodeOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products/barcode/9999999999999',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    const invalidResponse = await makeRequest(invalidBarcodeOptions);
    const invalidResult = JSON.parse(invalidResponse);
    
    console.log(`📊 Code inexistant - Statut: ${invalidResult.success ? 'SUCCÈS' : 'ÉCHEC (attendu)'}`);
    console.log(`📊 Message: ${invalidResult.message}`);

    // 5. Lister quelques produits avec codes-barres pour référence
    console.log('\n5. Produits avec codes-barres disponibles...');
    
    const allProductsOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products?limit=10',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    const allProductsResponse = await makeRequest(allProductsOptions);
    const allProductsResult = JSON.parse(allProductsResponse);
    
    if (allProductsResult.success && allProductsResult.data) {
      console.log('📋 Produits avec codes-barres:');
      allProductsResult.data
        .filter(p => p.codeBarre)
        .slice(0, 5)
        .forEach(product => {
          console.log(`   - ${product.nom}: ${product.codeBarre}`);
        });
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve(body));
    });

    req.on('error', reject);
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

// Exécuter le test
testBarcodeSearch();