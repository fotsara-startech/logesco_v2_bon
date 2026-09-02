const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:8080/api/v1';
const CUSTOMER_ID = 22; // ID du client pour les tests

async function createTestTransactions() {
  console.log('🧪 Création de transactions de test');
  console.log('=' * 50);

  try {
    // Transaction 1: Paiement
    console.log('\n📋 Création transaction 1: Paiement');
    const transaction1 = await axios.post(`${BASE_URL}/accounts/customers/${CUSTOMER_ID}/transactions`, {
      typeTransaction: 'paiement',
      montant: 5000,
      description: 'Paiement dette client - Test 1'
    }, {
      headers: { 'Content-Type': 'application/json' }
    });
    console.log(`✅ Transaction 1 créée: ID ${transaction1.data.data?.id}`);

    // Transaction 2: Achat
    console.log('\n📋 Création transaction 2: Achat');
    const transaction2 = await axios.post(`${BASE_URL}/accounts/customers/${CUSTOMER_ID}/transactions`, {
      typeTransaction: 'achat',
      montant: 3000,
      description: 'Achat à crédit - Test 2',
      referenceType: 'vente',
      referenceId: 123
    }, {
      headers: { 'Content-Type': 'application/json' }
    });
    console.log(`✅ Transaction 2 créée: ID ${transaction2.data.data?.id}`);

    // Transaction 3: Crédit
    console.log('\n📋 Création transaction 3: Crédit');
    const transaction3 = await axios.post(`${BASE_URL}/accounts/customers/${CUSTOMER_ID}/transactions`, {
      typeTransaction: 'credit',
      montant: 2000,
      description: 'Crédit manuel - Test 3'
    }, {
      headers: { 'Content-Type': 'application/json' }
    });
    console.log(`✅ Transaction 3 créée: ID ${transaction3.data.data?.id}`);

    // Vérification: récupérer les transactions
    console.log('\n🔍 Vérification: récupération des transactions');
    const getResponse = await axios.get(`${BASE_URL}/accounts/customers/${CUSTOMER_ID}/transactions`);
    
    console.log(`✅ ${getResponse.data.data.length} transaction(s) récupérée(s)`);
    getResponse.data.data.forEach((transaction, index) => {
      console.log(`  ${index + 1}. ${transaction.typeTransaction}: ${transaction.montant} FCFA - ${transaction.description}`);
    });

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.response) {
      console.error(`📊 Status: ${error.response.status}`);
      console.error(`📊 Data: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

// Test avec plusieurs clients
async function createTransactionsForMultipleCustomers() {
  const customerIds = [22, 26];
  
  for (const customerId of customerIds) {
    console.log(`\n🔍 Création de transactions pour le client ${customerId}`);
    
    try {
      // Une transaction simple pour chaque client
      const transaction = await axios.post(`${BASE_URL}/accounts/customers/${customerId}/transactions`, {
        typeTransaction: 'paiement',
        montant: 1000 + (customerId * 100), // Montant différent pour chaque client
        description: `Transaction test pour client ${customerId}`
      }, {
        headers: { 'Content-Type': 'application/json' }
      });
      
      console.log(`  ✅ Transaction créée pour client ${customerId}: ID ${transaction.data.data?.id}`);
      
    } catch (error) {
      console.log(`  ❌ Erreur pour client ${customerId}: ${error.message}`);
    }
  }
}

// Exécution
async function runTests() {
  await createTestTransactions();
  console.log('\n' + '='.repeat(50));
  await createTransactionsForMultipleCustomers();
}

runTests().catch(console.error);