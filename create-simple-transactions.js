const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:8080/api/v1';

async function createSimpleTransactions() {
  console.log('🧪 Création de transactions simples');
  console.log('=' * 50);

  const customers = [22, 26];
  const transactionTypes = ['paiement', 'credit', 'debit'];

  for (const customerId of customers) {
    console.log(`\n👤 Client ${customerId}:`);
    
    for (let i = 0; i < 3; i++) {
      try {
        const typeTransaction = transactionTypes[i % transactionTypes.length];
        const montant = 1000 + (i * 500) + (customerId * 10);
        
        const transaction = await axios.post(`${BASE_URL}/accounts/customers/${customerId}/transactions`, {
          typeTransaction: typeTransaction,
          montant: montant,
          description: `Transaction ${typeTransaction} #${i + 1} pour client ${customerId}`
        }, {
          headers: { 'Content-Type': 'application/json' }
        });
        
        console.log(`  ✅ ${typeTransaction}: ${montant} FCFA (ID: ${transaction.data.data?.id})`);
        
      } catch (error) {
        console.log(`  ❌ Erreur: ${error.response?.data?.message || error.message}`);
      }
    }
  }

  // Vérification finale
  console.log('\n🔍 Vérification des transactions créées:');
  for (const customerId of customers) {
    try {
      const response = await axios.get(`${BASE_URL}/accounts/customers/${customerId}/transactions`);
      console.log(`  👤 Client ${customerId}: ${response.data.data.length} transaction(s)`);
      
      response.data.data.forEach((transaction, index) => {
        console.log(`    ${index + 1}. ${transaction.typeTransaction}: ${transaction.montant} FCFA - ${transaction.description}`);
      });
    } catch (error) {
      console.log(`  ❌ Client ${customerId}: ${error.message}`);
    }
  }
}

createSimpleTransactions().catch(console.error);