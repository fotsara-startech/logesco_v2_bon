const axios = require('axios');

async function testAccountsAPI() {
  console.log('🔍 Test simple de l\'API des comptes');
  
  // Test sans authentification d'abord
  try {
    console.log('1. Test sans auth...');
    const response = await axios.get('http://localhost:8080/api/v1/accounts/customers?limit=5');
    console.log('✅ Réponse reçue:', response.status);
    console.log('Data:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.log('❌ Erreur sans auth:', error.response?.status, error.response?.data?.message || error.message);
    
    if (error.response?.status === 401) {
      console.log('\n2. Test avec token factice...');
      try {
        const headers = { 'Authorization': 'Bearer fake-token' };
        const response2 = await axios.get('http://localhost:8080/api/v1/accounts/customers?limit=5', { headers });
        console.log('✅ Réponse avec token:', response2.status);
        console.log('Data:', JSON.stringify(response2.data, null, 2));
      } catch (error2) {
        console.log('❌ Erreur avec token:', error2.response?.status, error2.response?.data?.message || error2.message);
      }
    }
  }
}

testAccountsAPI().catch(console.error);