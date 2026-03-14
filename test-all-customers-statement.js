/**
 * Test: Génère un relevé de compte pour TOUS les clients
 * Vérifie que le problème des transactions manquantes est résolu
 */

const http = require('http');

// Configuration
const API_HOST = 'localhost';
const API_PORT = 8080;
const TOKEN = 'your-token-here'; // À remplacer par un token valide

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
            body: parsed
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
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

// Fonction pour récupérer tous les clients
async function getAllClients(token) {
  console.log('📥 Récupération de la liste des clients...');
  
  const response = await makeRequest('/api/v1/customers?page=1&limit=100', token);
  
  if (response.statusCode === 200 && response.body.data) {
    const clients = response.body.data;
    console.log(`✅ ${clients.length} clients trouvés\n`);
    return clients;
  } else {
    console.log('❌ Erreur lors de la récupération des clients');
    return [];
  }
}

// Fonction pour tester un client
async function testClientStatement(clientId, clientName, token) {
  try {
    const response = await makeRequest(`/api/v1/customers/${clientId}/statement?format=a4`, token);
    
    if (response.statusCode === 200) {
      const data = response.body.data;
      const transactionCount = data?.transactions?.length || 0;
      
      return {
        success: true,
        clientId,
        clientName,
        transactionCount,
        hasLogo: !!data?.entreprise?.logoPath,
        solde: data?.compte?.soldeActuel || 0
      };
    } else {
      return {
        success: false,
        clientId,
        clientName,
        error: response.body.message || `Erreur ${response.statusCode}`
      };
    }
  } catch (error) {
    return {
      success: false,
      clientId,
      clientName,
      error: error.message
    };
  }
}

// Fonction principale
async function runTests() {
  console.log('\n' + '='.repeat(80));
  console.log('🧪 TEST: Relevé de Compte pour TOUS les Clients');
  console.log('='.repeat(80));
  console.log(`📍 Serveur: ${API_HOST}:${API_PORT}`);
  console.log(`🔐 Token: ${TOKEN.substring(0, 20)}...`);
  console.log('');

  try {
    // Récupérer tous les clients
    const clients = await getAllClients(TOKEN);
    
    if (clients.length === 0) {
      console.log('❌ Aucun client trouvé');
      return;
    }

    // Tester chaque client
    console.log('🧪 Test des relevés de compte...\n');
    
    const results = [];
    for (const client of clients) {
      const result = await testClientStatement(
        client.id,
        client.nomComplet || `${client.nom} ${client.prenom || ''}`,
        TOKEN
      );
      results.push(result);
      
      // Afficher le résultat
      if (result.success) {
        console.log(`✅ Client ${result.clientId}: ${result.clientName}`);
        console.log(`   - Transactions: ${result.transactionCount}`);
        console.log(`   - Logo: ${result.hasLogo ? 'Oui' : 'Non'}`);
        console.log(`   - Solde: ${result.solde} FCFA`);
      } else {
        console.log(`❌ Client ${result.clientId}: ${result.clientName}`);
        console.log(`   - Erreur: ${result.error}`);
      }
      console.log('');
    }

    // Résumé
    console.log('='.repeat(80));
    console.log('📊 RÉSUMÉ');
    console.log('='.repeat(80));
    
    const successCount = results.filter(r => r.success).length;
    const errorCount = results.filter(r => !r.success).length;
    const totalTransactions = results.reduce((sum, r) => sum + (r.transactionCount || 0), 0);
    const clientsWithTransactions = results.filter(r => r.transactionCount > 0).length;
    const clientsWithLogo = results.filter(r => r.hasLogo).length;
    
    console.log(`\n📈 Statistiques:`);
    console.log(`   - Clients testés: ${results.length}`);
    console.log(`   - Succès: ${successCount}`);
    console.log(`   - Erreurs: ${errorCount}`);
    console.log(`   - Clients avec transactions: ${clientsWithTransactions}`);
    console.log(`   - Total transactions: ${totalTransactions}`);
    console.log(`   - Clients avec logo: ${clientsWithLogo}`);
    
    // Détails des erreurs
    const errors = results.filter(r => !r.success);
    if (errors.length > 0) {
      console.log(`\n⚠️ Erreurs (${errors.length}):`);
      errors.forEach(e => {
        console.log(`   - Client ${e.clientId} (${e.clientName}): ${e.error}`);
      });
    }
    
    // Clients avec le plus de transactions
    const topClients = results
      .filter(r => r.success)
      .sort((a, b) => b.transactionCount - a.transactionCount)
      .slice(0, 5);
    
    if (topClients.length > 0) {
      console.log(`\n🏆 Top 5 clients (par nombre de transactions):`);
      topClients.forEach((c, i) => {
        console.log(`   ${i + 1}. ${c.clientName}: ${c.transactionCount} transactions`);
      });
    }
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ Tests terminés');
    console.log('='.repeat(80) + '\n');
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

// Lancer les tests
runTests();
