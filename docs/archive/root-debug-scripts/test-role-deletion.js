const axios = require('axios');

async function testRoleDeletion() {
  try {
    console.log('🧪 Test de suppression de rôle...');

    // D'abord, créer un rôle de test
    const roleData = {
      nom: 'TEST_DELETE',
      displayName: 'Rôle à supprimer',
      isAdmin: false,
      privileges: {
        "dashboard": ["READ"]
      }
    };

    console.log('➕ Création d\'un rôle de test...');
    const createResponse = await axios.post('http://localhost:3002/api/v1/roles', roleData);
    const roleId = createResponse.data.data.id;
    console.log(`✅ Rôle créé avec ID: ${roleId}`);

    // Maintenant, supprimer le rôle
    console.log(`🗑️ Suppression du rôle ID: ${roleId}...`);
    const deleteResponse = await axios.delete(`http://localhost:3002/api/v1/roles/${roleId}`);
    
    console.log('✅ Suppression réussie !');
    console.log('📋 Réponse:', JSON.stringify(deleteResponse.data, null, 2));
    console.log('🔍 Status Code:', deleteResponse.status);

    // Vérifier que le rôle n'existe plus
    try {
      await axios.get(`http://localhost:3002/api/v1/roles/${roleId}`);
      console.log('❌ Erreur: Le rôle existe encore !');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Parfait ! Le rôle a bien été supprimé (404 Not Found)');
      } else {
        console.log('❌ Erreur inattendue:', error.message);
      }
    }

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testRoleDeletion();