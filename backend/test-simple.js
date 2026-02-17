// Test simple de connexion au backend

const http = require('http');

function testConnection() {
  console.log('🧪 Test de connexion au backend...');
  
  const options = {
    hostname: 'localhost',
    port: 8080,
    path: '/api/v1/inventory?page=1&limit=5',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    console.log(`✅ Backend répond avec status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      try {
        const response = JSON.parse(data);
        console.log(`📊 Données reçues: ${response.data?.length || 0} éléments`);
        console.log('🎉 Backend fonctionne correctement !');
      } catch (e) {
        console.log('📄 Réponse brute:', data.substring(0, 200));
      }
    });
  });

  req.on('error', (e) => {
    console.error('❌ Erreur de connexion:', e.message);
    console.log('💡 Vérifiez que le backend est démarré sur le port 8080');
  });

  req.setTimeout(5000, () => {
    console.error('⏰ Timeout - le backend ne répond pas');
    req.destroy();
  });

  req.end();
}

testConnection();