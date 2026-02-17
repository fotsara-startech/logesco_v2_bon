const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testRolesAPI() {
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
    
    // Tester la route des rôles
    console.log('🔐 Test de la route des rôles...');
    
    try {
      const rolesResponse = await axios.get(`${BASE_URL}/roles`, { headers });
      
      console.log('✅ Route des rôles fonctionne !');
      console.log('Structure de réponse:', JSON.stringify(rolesResponse.data, null, 2));
      
      if (rolesResponse.data.data) {
        console.log(`📊 ${rolesResponse.data.data.length} rôles récupérés`);
        
        rolesResponse.data.data.forEach((role, index) => {
          console.log(`${index + 1}. ${role.displayName} (${role.nom})`);
          console.log(`   Admin: ${role.isAdmin ? 'Oui' : 'Non'}`);
          console.log(`   Privilèges: ${role.privileges}`);
          console.log('');
        });
      }
      
    } catch (error) {
      console.error('❌ Erreur route rôles:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Erreur générale:', error.response?.data || error.message);
  }
}

testRolesAPI();