const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:8080/api/v1';
const CUSTOMER_ID = 22; // Changez cet ID selon vos besoins

async function testCustomerTransactionsAPI() {
  console.log('🧪 Test de l\'API des transactions clients');
  console.log('=' * 50);

  try {
    // Test de l'endpoint des transactions
    console.log(`\n📋 Test: GET /accounts/customers/${CUSTOMER_ID}/transactions`);
    
    const response = await axios.get(`${BASE_URL}/accounts/customers/${CUSTOMER_ID}/transactions`, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    console.log('✅ Réponse reçue avec succès');
    console.log(`📊 Status: ${response.status}`);
    console.log(`📊 Headers: ${JSON.stringify(response.headers, null, 2)}`);
    console.log(`📊 Data type: ${typeof response.data}`);
    console.log(`📊 Data structure:`);
    console.log(JSON.stringify(response.data, null, 2));

    // Analyse de la structure
    if (response.data) {
      console.log('\n🔍 Analyse de la structure:');
      console.log(`- success: ${response.data.success}`);
      console.log(`- timestamp: ${response.data.timestamp}`);
      console.log(`- message: ${response.data.message}`);
      
      if (response.data.data) {
        console.log(`- data type: ${typeof response.data.data}`);
        console.log(`- data is array: ${Array.isArray(response.data.data)}`);
        if (Array.isArray(response.data.data)) {
          console.log(`- transactions count: ${response.data.data.length}`);
          if (response.data.data.length > 0) {
            console.log(`- first transaction: ${JSON.stringify(response.data.data[0], null, 2)}`);
          }
        }
      }
      
      if (response.data.pagination) {
        console.log(`- pagination: ${JSON.stringify(response.data.pagination, null, 2)}`);
      }
    }

  } catch (error) {
    console.error('❌ Erreur lors du test:', error.message);
    if (error.response) {
      console.error(`📊 Status: ${error.response.status}`);
      console.error(`📊 Data: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

// Test avec plusieurs clients
async function testMultipleCustomers() {
  const customerIds = [22, 26, 1, 2]; // Testez avec différents IDs
  
  for (const customerId of customerIds) {
    console.log(`\n🔍 Test client ID: ${customerId}`);
    try {
      const response = await axios.get(`${BASE_URL}/accounts/customers/${customerId}/transactions`);
      const transactionCount = Array.isArray(response.data.data) ? response.data.data.length : 0;
      console.log(`  ✅ Client ${customerId}: ${transactionCount} transaction(s)`);
      
      if (transactionCount > 0) {
        console.log(`  📊 Première transaction: ${JSON.stringify(response.data.data[0], null, 2)}`);
      }
    } catch (error) {
      console.log(`  ❌ Client ${customerId}: Erreur - ${error.message}`);
    }
  }
}

// Exécution des tests
async function runTests() {
  await testCustomerTransactionsAPI();
  console.log('\n' + '='.repeat(50));
  await testMultipleCustomers();
}

runTests().catch(console.error);