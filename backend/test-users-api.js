const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testUsersAPI() {
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
    
    // Tester la route des utilisateurs
    console.log('👥 Test de la route des utilisateurs...');
    
    try {
      const usersResponse = await axios.get(`${BASE_URL}/users`, { headers });
      
      console.log('✅ Route des utilisateurs fonctionne !');
      console.log('Structure de réponse:', JSON.stringify(usersResponse.data, null, 2));
      
      if (usersResponse.data.data) {
        console.log(`📊 ${usersResponse.data.data.length} utilisateurs récupérés`);
        
        usersResponse.data.data.forEach((user, index) => {
          console.log(`${index + 1}. ${user.nomUtilisateur} (${user.email})`);
          console.log(`   Rôle: ${user.role?.displayName || 'N/A'}`);
          console.log(`   Actif: ${user.isActive ? 'Oui' : 'Non'}`);
          console.log('');
        });
      }
      
    } catch (error) {
      console.error('❌ Erreur route utilisateurs:', error.response?.data || error.message);
    }
    
    // Tester la création d'un utilisateur
    console.log('➕ Test de création d\'utilisateur...');
    
    try {
      const newUserData = {
        nomUtilisateur: 'testuser',
        email: 'test@example.com',
        motDePasse: 'password123',
        role: {
          id: 1,
          nom: 'admin'
        },
        isActive: true
      };
      
      const createResponse = await axios.post(`${BASE_URL}/users`, newUserData, { headers });
      
      console.log('✅ Création d\'utilisateur réussie !');
      console.log('Utilisateur créé:', JSON.stringify(createResponse.data, null, 2));
      
    } catch (error) {
      console.error('❌ Erreur création utilisateur:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Erreur générale:', error.response?.data || error.message);
  }
}

testUsersAPI();