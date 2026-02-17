const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testAPI() {
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
    
    // Créer un inventaire
    console.log('📦 Création d\'un inventaire...');
    const inventoryResponse = await axios.post(`${BASE_URL}/stock-inventory`, {
      nom: 'Test Valorisation ' + Date.now(),
      description: 'Test de valorisation d\'inventaire',
      type: 'TOTAL',
      utilisateurId: 1
    }, { headers });
    
    const inventoryId = inventoryResponse.data.data.id;
    console.log(`✅ Inventaire créé avec ID: ${inventoryId}`);
    
    // Démarrer l'inventaire pour générer les items
    console.log('🚀 Démarrage de l\'inventaire...');
    await axios.patch(`${BASE_URL}/stock-inventory/${inventoryId}/status`, { status: 'EN_COURS' }, { headers });
    console.log('✅ Inventaire démarré');
    
    // Récupérer les items de l'inventaire
    console.log('📋 Récupération des items...');
    const itemsResponse = await axios.get(`${BASE_URL}/stock-inventory/${inventoryId}/items`, { headers });
    
    console.log('📊 Items récupérés:');
    itemsResponse.data.data.forEach((item, index) => {
      console.log(`${index + 1}. ${item.nomProduit}`);
      console.log(`   - Prix unitaire: ${item.prixUnitaire || 'NON DÉFINI'} FCFA`);
      console.log(`   - Prix achat: ${item.prixAchat || 'NON DÉFINI'} FCFA`);
      console.log(`   - Quantité système: ${item.quantiteSysteme}`);
      console.log(`   - Valeur système: ${(item.quantiteSysteme * (item.prixUnitaire || 0)).toFixed(0)} FCFA`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testAPI();