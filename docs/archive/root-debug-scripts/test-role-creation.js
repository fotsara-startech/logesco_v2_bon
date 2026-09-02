const axios = require('axios');

async function testRoleCreation() {
  try {
    console.log('🧪 Test de création de rôle avec privilèges...');

    const roleData = {
      nom: 'TEST_GESTIONNAIRE_2',
      displayName: 'Gestionnaire Test',
      isAdmin: false,
      privileges: {
        "dashboard": ["READ", "STATS"],
        "products": ["READ", "CREATE", "UPDATE", "DELETE"],
        "categories": ["READ", "CREATE", "UPDATE", "DELETE"],
        "inventory": ["READ", "CREATE", "UPDATE", "DELETE", "ADJUST"],
        "suppliers": ["READ", "CREATE", "UPDATE", "DELETE"],
        "customers": ["READ", "CREATE", "UPDATE", "DELETE"],
        "sales": ["READ", "CREATE", "UPDATE", "DELETE", "REFUND"],
        "procurement": ["READ", "CREATE", "UPDATE", "DELETE", "RECEIVE"],
        "accounts": ["READ", "CREATE", "UPDATE", "DELETE", "TRANSACTIONS"],
        "financial_movements": ["READ", "CREATE", "UPDATE", "DELETE", "REPORTS"],
        "cash_registers": ["READ", "CREATE", "UPDATE", "DELETE", "OPEN", "CLOSE"],
        "stock_inventory": ["READ", "CREATE", "UPDATE", "DELETE", "COUNT"],
        "users": ["READ", "CREATE", "UPDATE", "DELETE", "ROLES"],
        "company_settings": [],
        "printing": ["READ", "PRINT", "REPRINT"],
        "reports": ["READ", "EXPORT"]
      }
    };

    console.log('📤 Envoi des données:', JSON.stringify(roleData, null, 2));

    const response = await axios.post('http://localhost:3002/api/v1/roles', roleData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Rôle créé avec succès !');
    console.log('📋 Réponse:', JSON.stringify(response.data, null, 2));

    // Vérifier le rôle créé
    const getRoleResponse = await axios.get(`http://localhost:3002/api/v1/roles/${response.data.data.id}`);
    console.log('\n🔍 Vérification du rôle créé:');
    console.log('📋 Privilèges sauvegardés:', getRoleResponse.data.data.privileges);

    // Parser les privilèges pour vérifier qu'ils sont corrects
    const savedPrivileges = JSON.parse(getRoleResponse.data.data.privileges);
    console.log('\n✅ Privilèges parsés:', JSON.stringify(savedPrivileges, null, 2));

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testRoleCreation();