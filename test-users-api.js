const axios = require('axios');

async function testUsersAPI() {
  try {
    console.log('🧪 Test de l\'API des utilisateurs...');

    // 1. Récupérer tous les utilisateurs
    console.log('\n📋 1. Récupération de tous les utilisateurs:');
    const usersResponse = await axios.get('http://localhost:3002/api/v1/users');
    console.log(`✅ ${usersResponse.data.data.length} utilisateur(s) trouvé(s)`);
    
    usersResponse.data.data.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.nomUtilisateur} (${user.email})`);
      console.log(`      - Rôle: ${user.role.displayName} (${user.role.nom})`);
      console.log(`      - Admin: ${user.role.isAdmin}`);
      console.log(`      - Actif: ${user.isActive}`);
    });

    // 2. Récupérer tous les rôles pour créer un utilisateur de test
    console.log('\n🔍 2. Récupération des rôles disponibles:');
    const rolesResponse = await axios.get('http://localhost:3002/api/v1/roles');
    console.log(`✅ ${rolesResponse.data.data.length} rôle(s) disponible(s)`);
    
    if (rolesResponse.data.data.length === 0) {
      console.log('❌ Aucun rôle disponible pour créer un utilisateur de test');
      return;
    }

    const testRole = rolesResponse.data.data[0]; // Utiliser le premier rôle disponible
    console.log(`   Utilisation du rôle: ${testRole.displayName} (ID: ${testRole.id})`);

    // 3. Créer un utilisateur de test
    console.log('\n➕ 3. Création d\'un utilisateur de test:');
    const newUserData = {
      nomUtilisateur: 'test_user',
      email: 'test@logesco.com',
      motDePasse: 'test123',
      role: {
        id: testRole.id,
        nom: testRole.nom
      },
      isActive: true
    };

    const createResponse = await axios.post('http://localhost:3002/api/v1/users', newUserData);
    const createdUser = createResponse.data.data;
    console.log(`✅ Utilisateur créé: ${createdUser.nomUtilisateur} (ID: ${createdUser.id})`);

    // 4. Récupérer l'utilisateur par ID
    console.log('\n🔍 4. Récupération de l\'utilisateur par ID:');
    const getUserResponse = await axios.get(`http://localhost:3002/api/v1/users/${createdUser.id}`);
    const retrievedUser = getUserResponse.data.data;
    console.log(`✅ Utilisateur récupéré: ${retrievedUser.nomUtilisateur}`);
    console.log(`   - Email: ${retrievedUser.email}`);
    console.log(`   - Rôle: ${retrievedUser.role.displayName}`);

    // 5. Modifier le statut de l'utilisateur
    console.log('\n🔄 5. Modification du statut de l\'utilisateur:');
    const statusResponse = await axios.put(`http://localhost:3002/api/v1/users/${createdUser.id}/status`, {
      isActive: false
    });
    console.log(`✅ Statut modifié: ${statusResponse.data.data.isActive ? 'Actif' : 'Inactif'}`);

    // 6. Changer le mot de passe
    console.log('\n🔐 6. Changement du mot de passe:');
    const passwordResponse = await axios.put(`http://localhost:3002/api/v1/users/${createdUser.id}/password`, {
      motDePasse: 'nouveauMotDePasse123'
    });
    console.log(`✅ ${passwordResponse.data.message}`);

    // 7. Supprimer l'utilisateur de test
    console.log('\n🗑️ 7. Suppression de l\'utilisateur de test:');
    const deleteResponse = await axios.delete(`http://localhost:3002/api/v1/users/${createdUser.id}`);
    console.log(`✅ ${deleteResponse.data.message}`);

    // 8. Vérifier que l'utilisateur n'existe plus
    console.log('\n🔍 8. Vérification de la suppression:');
    try {
      await axios.get(`http://localhost:3002/api/v1/users/${createdUser.id}`);
      console.log('❌ Erreur: L\'utilisateur existe encore !');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Parfait ! L\'utilisateur a bien été supprimé (404 Not Found)');
      } else {
        console.log('❌ Erreur inattendue:', error.message);
      }
    }

    console.log('\n🎉 Tous les tests sont passés avec succès !');

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testUsersAPI();