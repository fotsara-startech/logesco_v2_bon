const http = require('http');

async function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body: data });
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function testGetProducts() {
  console.log('🧪 TEST: Récupération des produits disponibles');
  console.log('==============================================');
  
  try {
    // Étape 1: Connexion pour obtenir un token
    console.log('\n📋 Étape 1: Connexion pour obtenir un token...');
    
    const loginData = {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    };
    
    const loginOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const loginResponse = await makeRequest(loginOptions, JSON.stringify(loginData));
    
    if (loginResponse.statusCode !== 200) {
      console.log('❌ Échec de la connexion:', loginResponse.body);
      return;
    }
    
    const loginResult = JSON.parse(loginResponse.body);
    const token = loginResult.data?.accessToken;
    console.log('✅ Connexion réussie, token obtenu');
    
    // Étape 2: Récupérer la liste des produits
    console.log('\n📋 Étape 2: Récupération des produits...');
    
    const productsOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/products',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    const productsResponse = await makeRequest(productsOptions);
    
    if (productsResponse.statusCode === 200) {
      const productsData = JSON.parse(productsResponse.body);
      console.log(`✅ Produits trouvés: ${productsData.data.length}`);
      
      productsData.data.slice(0, 5).forEach((product, index) => {
        console.log(`  ${index + 1}. ID: ${product.id}, Nom: ${product.nom}, Prix: ${product.prixVente} FCFA`);
      });
      
      if (productsData.data.length > 5) {
        console.log(`  ... et ${productsData.data.length - 5} autres produits`);
      }
      
      // Retourner le premier produit pour les tests
      if (productsData.data.length > 0) {
        const firstProduct = productsData.data[0];
        console.log(`\n✅ Premier produit disponible pour les tests:`);
        console.log(`   ID: ${firstProduct.id}`);
        console.log(`   Nom: ${firstProduct.nom}`);
        console.log(`   Prix de vente: ${firstProduct.prixVente} FCFA`);
        console.log(`   Prix d'achat: ${firstProduct.prixAchat || 'Non défini'} FCFA`);
      }
    } else {
      console.log('❌ Erreur récupération produits:', productsResponse.body);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

testGetProducts();