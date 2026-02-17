const axios = require('axios');

async function testLogin() {
  try {
    console.log('🔐 Test de connexion à l\'API...');
    console.log('URL: http://localhost:8080/api/v1/auth/login');
    console.log('Identifiants: admin / admin123\n');
    
    const response = await axios.post('http://localhost:8080/api/v1/auth/login', {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });
    
    console.log('✅ Connexion réussie !');
    console.log('Status:', response.status);
    console.log('Token:', response.data.data?.accessToken?.substring(0, 50) + '...');
    console.log('Utilisateur:', response.data.data?.utilisateur?.nomUtilisateur);
    
  } catch (error) {
    console.error('❌ Erreur de connexion:');
    console.error('Status:', error.response?.status);
    console.error('Message:', error.response?.data?.message);
    console.error('Détails:', error.response?.data);
  }
}

testLogin();
