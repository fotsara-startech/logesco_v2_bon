/**
 * Test script pour vérifier l'endpoint /customers/:id/statement
 * Vérifie que les transactions et le logo sont correctement retournés
 */

const http = require('http');

// Configuration
const API_HOST = 'localhost';
const API_PORT = 8080;
const CUSTOMER_ID = 34; // Remplacer par un ID de client valide
const TOKEN = 'your-token-here'; // Remplacer par un token valide

// Fonction pour faire une requête HTTP
function makeRequest(path, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_HOST,
      port: API_PORT,
      path: path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: parsed
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.end();
  });
}

// Fonction principale
async function testStatementEndpoint() {
  console.log('🧪 Test de l\'endpoint /customers/:id/statement');
  console.log(`📍 Serveur: ${API_HOST}:${API_PORT}`);
  console.log(`👤 Client ID: ${CUSTOMER_ID}`);
  console.log('');

  try {
    console.log('📤 Envoi de la requête...');
    const response = await makeRequest(`/api/v1/customers/${CUSTOMER_ID}/statement?format=a4`, TOKEN);

    console.log('📥 Réponse reçue:');
    console.log(`   Status: ${response.statusCode}`);
    console.log('');

    if (response.statusCode === 200) {
      const body = response.body;
      
      console.log('✅ Réponse 200 OK');
      console.log('');
      
      console.log('📊 Structure de la réponse:');
      console.log(`   - success: ${body.success}`);
      console.log(`   - message: ${body.message}`);
      console.log(`   - data: ${body.data ? 'Présent' : 'Absent'}`);
      console.log('');

      if (body.data) {
        const data = body.data;
        
        console.log('📋 Contenu de data:');
        console.log(`   - entreprise: ${data.entreprise ? 'Présent' : 'Absent'}`);
        console.log(`   - client: ${data.client ? 'Présent' : 'Absent'}`);
        console.log(`   - compte: ${data.compte ? 'Présent' : 'Absent'}`);
        console.log(`   - transactions: ${data.transactions ? `${data.transactions.length} transactions` : 'Absent'}`);
        console.log('');

        if (data.entreprise) {
          console.log('🏢 Informations entreprise:');
          console.log(`   - nom: ${data.entreprise.nom}`);
          console.log(`   - logoPath: ${data.entreprise.logoPath || 'Non défini'}`);
          console.log('');
        }

        if (data.transactions && data.transactions.length > 0) {
          console.log(`📝 Transactions (${data.transactions.length} total):`);
          data.transactions.slice(0, 3).forEach((t, i) => {
            console.log(`   Transaction ${i + 1}:`);
            console.log(`     - description: ${t.description}`);
            console.log(`     - montant: ${t.montant}`);
            console.log(`     - dateTransaction: ${t.dateTransaction}`);
            console.log(`     - typeTransaction: ${t.typeTransaction}`);
          });
          if (data.transactions.length > 3) {
            console.log(`   ... et ${data.transactions.length - 3} autres transactions`);
          }
        } else {
          console.log('⚠️ Aucune transaction trouvée');
        }
      }
    } else {
      console.log(`❌ Erreur ${response.statusCode}`);
      console.log('');
      console.log('Réponse:');
      console.log(JSON.stringify(response.body, null, 2));
    }
  } catch (error) {
    console.error('❌ Erreur lors de la requête:', error.message);
  }
}

// Lancer le test
testStatementEndpoint();
