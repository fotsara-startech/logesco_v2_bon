const http = require('http');

/**
 * Test du nouvel endpoint public /company-settings/public
 */
async function testPublicEndpoint() {
  console.log('🧪 TEST: Endpoint public /company-settings/public');
  console.log('=' * 50);
  
  const hostname = 'localhost';
  const port = 8080;
  const path = '/api/v1/company-settings/public';
  
  console.log(`\n📡 Test de l'endpoint: http://${hostname}:${port}${path}`);
  
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
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`   Status: ${res.statusCode}`);
        
        try {
          const jsonData = JSON.parse(data);
          console.log(`   Response: ${JSON.stringify(jsonData, null, 2)}`);
          
          if (res.statusCode === 200 && jsonData.data) {
            console.log('\n✅ SUCCÈS: Données récupérées depuis l\'endpoint public');
            console.log(`   Nom entreprise: ${jsonData.data.nomEntreprise}`);
            console.log(`   Adresse: ${jsonData.data.adresse}`);
            console.log(`   Localisation: ${jsonData.data.localisation}`);
            console.log(`   Téléphone: ${jsonData.data.telephone}`);
            console.log(`   Email: ${jsonData.data.email}`);
            console.log(`   NUI RCCM: ${jsonData.data.nuiRccm}`);
          } else {
            console.log('\n❌ ÉCHEC: Impossible de récupérer les données');
          }
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
testPublicEndpoint().catch(console.error);