const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testTransactionsAPI() {
  try {
    console.log('🔐 Connexion...');
    
    // Se connecter
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });
    
    const token = loginResponse.data.data.token;
    console.log('✅ Connexion réussie');
    
    const headers = { Authorization: `Bearer ${token}` };
    
    // Tester la route des transactions pour le client 1
    console.log('📋 Test de la route des transactions pour le client 1...');
    
    try {
      const transactionsResponse = await axios.get(`${BASE_URL}/accounts/customers/1/transactions`, { headers });
      
      console.log('✅ Route des transactions fonctionne !');
      console.log(`📊 ${transactionsResponse.data.data.length} transactions récupérées`);
      
      transactionsResponse.data.data.forEach((transaction, index) => {
        console.log(`${index + 1}. ${transaction.typeTransaction} - ${transaction.montant} FCFA`);
        console.log(`   Description: ${transaction.description}`);
        console.log(`   Date: ${transaction.dateTransaction}`);
        console.log(`   Solde après: ${transaction.soldeApres} FCFA`);
        if (transaction.referenceType) {
          console.log(`   Référence: ${transaction.referenceType} #${transaction.referenceId}`);
        }
        console.log('');
      });
      
    } catch (error) {
      console.error('❌ Erreur route transactions:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Erreur générale:', error.response?.data || error.message);
  }
}

testTransactionsAPI();