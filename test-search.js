// Test simple de la recherche d'inventaire

const axios = require('axios');

const API_BASE = 'http://localhost:8080/api/v1';

async function testSearch() {
  console.log('🧪 Test de la recherche d\'inventaire');
  
  try {
    // Test avec recherche vide (tous les produits)
    console.log('\n📋 Test 1: Sans recherche');
    const response1 = await axios.get(`${API_BASE}/inventory?page=1&limit=5`);
    console.log(`✅ ${response1.data.data.length} produits trouvés`);
    
    // Test avec recherche spécifique
    console.log('\n📋 Test 2: Recherche "TEST"');
    const response2 = await axios.get(`${API_BASE}/inventory?search=TEST&page=1&limit=5`);
    console.log(`✅ ${response2.data.data.length} produits trouvés`);
    
    // Test avec recherche inexistante
    console.log('\n📋 Test 3: Recherche "INEXISTANT123"');
    const response3 = await axios.get(`${API_BASE}/inventory?search=INEXISTANT123&page=1&limit=5`);
    console.log(`✅ ${response3.data.data.length} produits trouvés`);
    
    if (response3.data.data.length === 0) {
      console.log('🎉 Parfait ! La recherche fonctionne correctement');
    } else {
      console.log('❌ Problème : des résultats trouvés pour une recherche inexistante');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Le backend n\'est pas démarré. Lancez-le avec: npm start');
    }
  }
}

testSearch();