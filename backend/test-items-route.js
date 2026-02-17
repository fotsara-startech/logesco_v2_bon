const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testItemsRoute() {
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
    
    // Tester la route des items avec l'inventaire 5
    console.log('📋 Test de la route des items pour l\'inventaire 5...');
    
    try {
      const itemsResponse = await axios.get(`${BASE_URL}/stock-inventory/5/items`, { headers });
      
      console.log('✅ Route des items fonctionne !');
      console.log(`📊 ${itemsResponse.data.data.length} items récupérés`);
      
      itemsResponse.data.data.forEach((item, index) => {
        console.log(`${index + 1}. ${item.nomProduit}`);
        console.log(`   - Prix unitaire: ${item.prixUnitaire || 'NON DÉFINI'} FCFA`);
        console.log(`   - Prix achat: ${item.prixAchat || 'NON DÉFINI'} FCFA`);
        console.log(`   - Quantité système: ${item.quantiteSysteme}`);
        console.log(`   - Valeur système: ${(item.quantiteSysteme * (item.prixUnitaire || 0)).toFixed(0)} FCFA`);
        console.log('');
      });
      
    } catch (error) {
      console.error('❌ Erreur route items:', error.response?.data || error.message);
      
      // Essayons de voir l'erreur complète
      if (error.response) {
        console.log('Status:', error.response.status);
        console.log('Headers:', error.response.headers);
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur générale:', error.response?.data || error.message);
  }
}

testItemsRoute();