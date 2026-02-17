const axios = require('axios');

async function testBackend() {
  const baseUrl = 'http://localhost:3002';
  
  console.log('🧪 Test du backend LOGESCO...');
  
  try {
    // Test 1: Vérifier si le serveur répond
    console.log('1️⃣ Test de base du serveur...');
    const healthResponse = await axios.get(`${baseUrl}/`);
    console.log('✅ Serveur accessible:', healthResponse.data.message);
    
    // Test 2: Vérifier les routes utilisateurs
    console.log('2️⃣ Test des routes utilisateurs...');
    try {
      const usersResponse = await axios.get(`${baseUrl}/api/v1/users`);
      console.log('✅ Route users accessible:', usersResponse.data);
    } catch (error) {
      console.log('❌ Route users:', error.response?.status, error.response?.data || error.message);
    }
    
    // Test 3: Vérifier les routes rôles
    console.log('3️⃣ Test des routes rôles...');
    try {
      const rolesResponse = await axios.get(`${baseUrl}/api/v1/roles`);
      console.log('✅ Route roles accessible:', rolesResponse.data);
    } catch (error) {
      console.log('❌ Route roles:', error.response?.status, error.response?.data || error.message);
    }
    
    // Test 4: Vérifier les routes caisses
    console.log('4️⃣ Test des routes caisses...');
    try {
      const cashResponse = await axios.get(`${baseUrl}/api/v1/cash-registers`);
      console.log('✅ Route cash-registers accessible:', cashResponse.data);
    } catch (error) {
      console.log('❌ Route cash-registers:', error.response?.status, error.response?.data || error.message);
    }
    
  } catch (error) {
    console.log('❌ Serveur non accessible:', error.message);
    console.log('💡 Assurez-vous que le backend est démarré sur le port 3002');
  }
}

testBackend();