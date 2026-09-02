/**
 * Test complet pour vérifier l'endpoint /customers/:id/statement
 * Teste deux clients: un avec transactions et un sans
 */

const http = require('http');

// Configuration
const API_HOST = 'localhost';
const API_PORT = 8080;
const TOKEN = 'your-token-here'; // À remplacer par un token valide

// Clients à tester
const CLIENTS_TO_TEST = [
  { id: 34, name: 'RAOUL FOTSARA' },  // Client avec transactions
  { id: 35, name: 'FRANGLISH JUNIOR' } // Client sans transactions (ou avec peu)
];

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

// Fonction pour tester un client
async function testClient(clientId, clientName) {
  console.log('\n' + '='.repeat(80));
  console.log(`🧪 Test Client: ${clientName} (ID: ${clientId})`);
  console.log('='.repeat(80));

  try {
    console.log('📤 Envoi de la requête...');
    const response = await makeRequest(`/api/v1/customers/${clientId}/statement?format=a4`, TOKEN);

    console.log(`\n📥 Réponse reçue (Status: ${response.statusCode})`);

    if (response.statusCode === 200) {
      const body = response.body;
      
      console.log('\n✅ Réponse 200 OK');
      console.log(`   - success: ${body.success}`);
      console.log(`   - message: ${body.message}`);
      
      if (body.data) {
        const data = body.data;
        
        console.log('\n📋 Structure de data:');
        console.log(`   - entreprise: ${data.entreprise ? '✅ Présent' : '❌ Absent'}`);
        console.log(`   - client: ${data.client ? '✅ Présent' : '❌ Absent'}`);
        console.log(`   - compte: ${data.compte ? '✅ Présent' : '❌ Absent'}`);
        console.log(`   - transactions: ${data.transactions ? `✅ ${data.transactions.length} transactions` : '❌ Absent'}`);
        
        if (data.entreprise) {
          console.log('\n🏢 Informations entreprise:');
          console.log(`   - nom: ${data.entreprise.nom}`);
          console.log(`   - logoPath: ${data.entreprise.logoPath ? '✅ ' + data.entreprise.logoPath : '❌ Non défini'}`);
          console.log(`   - telephone: ${data.entreprise.telephone}`);
          console.log(`   - nuiRccm: ${data.entreprise.nuiRccm}`);
        }
        
        if (data.client) {
          console.log('\n👤 Informations client:');
          console.log(`   - nomComplet: ${data.client.nomComplet}`);
          console.log(`   - telephone: ${data.client.telephone || 'N/A'}`);
          console.log(`   - email: ${data.client.email || 'N/A'}`);
        }
        
        if (data.compte) {
          console.log('\n💰 Informations compte:');
          console.log(`   - soldeActuel: ${data.compte.soldeActuel} FCFA`);
          console.log(`   - limiteCredit: ${data.compte.limiteCredit} FCFA`);
          console.log(`   - aDette: ${data.compte.aDette ? 'Oui' : 'Non'}`);
          console.log(`   - montantDette: ${data.compte.montantDette} FCFA`);
        }
        
        if (data.transactions && data.transactions.length > 0) {
          console.log(`\n📝 Transactions (${data.transactions.length} total):`);
          
          // Afficher les 3 premières
          data.transactions.slice(0, 3).forEach((t, i) => {
            console.log(`\n   Transaction ${i + 1}:`);
            console.log(`     - id: ${t.id}`);
            console.log(`     - description: ${t.description}`);
            console.log(`     - montant: ${t.montant} FCFA`);
            console.log(`     - typeTransaction: ${t.typeTransaction}`);
            console.log(`     - typeTransactionDetail: ${t.typeTransactionDetail}`);
            console.log(`     - dateTransaction: ${t.dateTransaction}`);
            console.log(`     - soldeApres: ${t.soldeApres} FCFA`);
            console.log(`     - venteReference: ${t.venteReference || 'N/A'}`);
            console.log(`     - isCredit: ${t.isCredit}`);
          });
          
          if (data.transactions.length > 3) {
            console.log(`\n   ... et ${data.transactions.length - 3} autres transactions`);
          }
          
          // Statistiques
          console.log('\n📊 Statistiques:');
          const totalMontant = data.transactions.reduce((sum, t) => sum + t.montant, 0);
          const creditCount = data.transactions.filter(t => t.isCredit).length;
          const debitCount = data.transactions.filter(t => !t.isCredit).length;
          
          console.log(`   - Montant total: ${totalMontant} FCFA`);
          console.log(`   - Crédits: ${creditCount}`);
          console.log(`   - Débits: ${debitCount}`);
        } else {
          console.log('\n⚠️ Aucune transaction trouvée');
        }
      } else {
        console.log('\n❌ Pas de données dans la réponse');
      }
    } else {
      console.log(`\n❌ Erreur ${response.statusCode}`);
      console.log('\nRéponse:');
      console.log(JSON.stringify(response.body, null, 2));
    }
  } catch (error) {
    console.error('\n❌ Erreur lors de la requête:', error.message);
  }
}

// Fonction principale
async function runTests() {
  console.log('\n' + '='.repeat(80));
  console.log('🧪 TEST COMPLET: Endpoint /customers/:id/statement');
  console.log('='.repeat(80));
  console.log(`📍 Serveur: ${API_HOST}:${API_PORT}`);
  console.log(`🔐 Token: ${TOKEN.substring(0, 20)}...`);
  console.log(`📋 Clients à tester: ${CLIENTS_TO_TEST.length}`);

  for (const client of CLIENTS_TO_TEST) {
    await testClient(client.id, client.name);
  }

  console.log('\n' + '='.repeat(80));
  console.log('✅ Tests terminés');
  console.log('='.repeat(80) + '\n');
}

// Lancer les tests
runTests();
