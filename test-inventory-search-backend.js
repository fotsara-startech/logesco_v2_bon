// Test de la recherche d'inventaire côté backend

const axios = require('axios');

const API_BASE = 'http://localhost:8080/api/v1';

async function testInventorySearch() {
  console.log('🧪 Test de la recherche d\'inventaire backend');
  console.log('');

  try {
    // Test 1: Recherche qui devrait retourner des résultats
    console.log('📋 Test 1: Recherche "TEST" (devrait retourner des résultats)');
    const response1 = await axios.get(`${API_BASE}/inventory?search=TEST&page=1&limit=20`);
    console.log(`✅ Résultats: ${response1.data.data.length} produits trouvés`);
    
    if (response1.data.data.length > 0) {
      console.log(`   Premier produit: ${response1.data.data[0].produit?.nom}`);
    }
    console.log('');

    // Test 2: Recherche qui ne devrait retourner aucun résultat
    console.log('📋 Test 2: Recherche "TESLKLKLKLKLK" (ne devrait retourner aucun résultat)');
    const response2 = await axios.get(`${API_BASE}/inventory?search=TESLKLKLKLKLK&page=1&limit=20`);
    console.log(`✅ Résultats: ${response2.data.data.length} produits trouvés`);
    
    if (response2.data.data.length === 0) {
      console.log('   ✅ Parfait ! Aucun résultat comme attendu');
    } else {
      console.log('   ❌ Problème ! Des résultats ont été trouvés alors qu\'il ne devrait pas y en avoir');
    }
    console.log('');

    // Test 3: Recherche par référence
    console.log('📋 Test 3: Recherche par référence "PRD"');
    const response3 = await axios.get(`${API_BASE}/inventory?search=PRD&page=1&limit=20`);
    console.log(`✅ Résultats: ${response3.data.data.length} produits trouvés`);
    console.log('');

    // Test 4: Sans recherche (tous les produits)
    console.log('📋 Test 4: Sans recherche (tous les produits)');
    const response4 = await axios.get(`${API_BASE}/inventory?page=1&limit=20`);
    console.log(`✅ Résultats: ${response4.data.data.length} produits trouvés`);
    console.log('');

    console.log('🎉 Tests terminés avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
  }
}

// Exécuter les tests
testInventorySearch();