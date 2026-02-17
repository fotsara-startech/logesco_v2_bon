// Test avec authentification

const axios = require('axios');

const API_BASE = 'http://localhost:8080/api/v1';

async function testWithAuth() {
  console.log('🧪 Test avec authentification...');
  
  try {
    // D'abord, essayer de se connecter
    console.log('🔐 Tentative de connexion...');
    const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });
    
    const token = loginResponse.data.data.token;
    console.log('✅ Connexion réussie, token obtenu');
    
    // Maintenant tester l'inventaire avec le token
    console.log('📦 Test de l\'inventaire avec token...');
    const inventoryResponse = await axios.get(`${API_BASE}/inventory?page=1&limit=5`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log(`✅ Inventaire: ${inventoryResponse.data.data.length} produits`);
    
    // Test avec recherche
    console.log('🔍 Test de recherche avec "TEST"...');
    const searchResponse = await axios.get(`${API_BASE}/inventory?search=TEST&page=1&limit=5`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log(`✅ Recherche: ${searchResponse.data.data.length} produits trouvés`);
    
    if (searchResponse.data.data.length > 0) {
      console.log(`   Premier: ${searchResponse.data.data[0].produit?.nom}`);
    }
    
    console.log('🎉 Tout fonctionne correctement !');
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
  }
}

testWithAuth();