const http = require('http');

/**
 * Test de l'API company-settings pour vérifier la récupération des données
 */
async function testCompanySettingsAPI() {
  console.log('🧪 TEST: API /company-settings');
  console.log('=' * 50);
  
  // Configuration de base
  const hostname = 'localhost';
  const port = 8080;
  const path = '/api/v1/company-settings';
  
  console.log(`\n📡 Test de l'endpoint: http://${hostname}:${port}${path}`);
  
  // Test sans authentification
  console.log('\n1️⃣ Test sans token d\'authentification:');
  await testEndpoint(hostname, port, path, null);
  
  // Test avec un token factice (pour voir la différence)
  console.log('\n2️⃣ Test avec token factice:');
  await testEndpoint(hostname, port, path, 'fake-token');
  
  console.log('\n📋 DONNÉES ATTENDUES DE LA BASE:');
  console.log('   - nomEntreprise: MBOA KATHY B');
  console.log('   - adresse: kribi');
  console.log('   - localisation: Mbeka\'a');
  console.log('   - telephone: 698745120');
  console.log('   - email: mboa@gmail.com');
  console.log('   - nuiRccm: P012479935');
  
  console.log('\n🔍 DIAGNOSTIC:');
  console.log('   Si l\'API retourne 404: Aucune donnée dans parametres_entreprise');
  console.log('   Si l\'API retourne 401: Problème d\'authentification');
  console.log('   Si l\'API retourne 200: Vérifier les données retournées');
}

function testEndpoint(hostname, port, path, token) {
  return new Promise((resolve) => {
    const options = {
      hostname: hostname,
      port: port,
      path: path,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      }
    };
    
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`   Status: ${res.statusCode}`);
        console.log(`   Headers: ${JSON.stringify(res.headers, null, 2)}`);
        
        try {
          const jsonData = JSON.parse(data);
          console.log(`   Response: ${JSON.stringify(jsonData, null, 2)}`);
        } catch (e) {
          console.log(`   Response (raw): ${data}`);
        }
        
        resolve();
      });
    });
    
    req.on('error', (err) => {
      console.log(`   Erreur: ${err.message}`);
      resolve();
    });
    
    req.setTimeout(5000, () => {
      console.log('   Timeout: Pas de réponse après 5 secondes');
      req.destroy();
      resolve();
    });
    
    req.end();
  });
}

// Exécuter le test
testCompanySettingsAPI().catch(console.error);