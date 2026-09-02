const http = require('http');

console.log('🧪 Test de l\'endpoint /products/all');
console.log('=' * 40);

// Fonction pour faire une requête HTTP
function makeRequest(options) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data
        });
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.end();
  });
}

async function testEndpoint() {
  try {
    console.log('\n📡 Test de GET /api/v1/products/all...');
    
    const response = await makeRequest({
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products/all',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`📊 Status Code: ${response.statusCode}`);
    
    if (response.statusCode === 401) {
      console.log('🔐 Authentification requise (normal)');
      console.log('✅ Endpoint accessible et sécurisé');
    } else if (response.statusCode === 200) {
      console.log('✅ Endpoint fonctionne parfaitement');
      const data = JSON.parse(response.body);
      console.log(`📦 Nombre de produits: ${data.data ? data.data.length : 'N/A'}`);
    } else {
      console.log(`❌ Erreur inattendue: ${response.statusCode}`);
      console.log(`📄 Réponse: ${response.body}`);
    }
    
  } catch (error) {
    console.error('❌ Erreur de connexion:', error.message);
  }
}

testEndpoint();