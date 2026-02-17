/**
 * Tests d'intégration pour les endpoints d'inventaire
 * Teste les fonctionnalités de gestion du stock
 */

const axios = require('axios');
const environment = require('../config/environment');

const API_BASE_URL = `http://localhost:3001/api/v1`;

// Configuration des tests
const testConfig = {
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
};

let authToken = null;
let testProductId = null;

/**
 * Authentification pour les tests
 */
async function authenticate() {
  try {
    console.log('🔐 Authentification...');
    
    // Créer un utilisateur de test s'il n'existe pas
    try {
      await axios.post(`${API_BASE_URL}/auth/register`, {
        nomUtilisateur: 'testinventory',
        email: 'test.inventory@logesco.com',
        motDePasse: 'testpass123'
      }, testConfig);
      console.log('✅ Utilisateur de test créé');
    } catch (error) {
      // L'utilisateur existe déjà, c'est normal
      console.log('ℹ️ Utilisateur de test existe déjà');
    }

    // Se connecter
    const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
      nomUtilisateur: 'testinventory',
      motDePasse: 'testpass123'
    }, testConfig);

    authToken = loginResponse.data.data.token;
    testConfig.headers.Authorization = `Bearer ${authToken}`;
    console.log('✅ Authentification réussie');
    
    return true;
  } catch (error) {
    console.error('❌ Erreur d\'authentification:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      url: error.config?.url
    });
    return false;
  }
}

/**
 * Crée un produit de test avec stock
 */
async function createTestProduct() {
  try {
    console.log('📦 Création d\'un produit de test...');
    
    const productResponse = await axios.post(`${API_BASE_URL}/products`, {
      reference: `TEST-INV-${Date.now()}`,
      nom: 'Produit Test Inventaire',
      description: 'Produit pour tester la gestion du stock',
      prixUnitaire: 25.50,
      categorie: 'Test',
      seuilStockMinimum: 5
    }, testConfig);

    testProductId = productResponse.data.data.id;
    console.log(`✅ Produit de test créé avec ID: ${testProductId}`);
    
    return testProductId;
  } catch (error) {
    console.error('❌ Erreur création produit:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      url: error.config?.url
    });
    return null;
  }
}

/**
 * Test de récupération de la liste des stocks
 */
async function testGetInventoryList() {
  try {
    console.log('📋 Test: Récupération de la liste des stocks...');
    
    const response = await axios.get(`${API_BASE_URL}/inventory?page=1&limit=10`, testConfig);
    
    console.log('✅ Liste des stocks récupérée:', {
      success: response.data.success,
      totalItems: response.data.pagination?.total || 0,
      itemsCount: response.data.data?.length || 0
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur récupération liste stocks:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test de récupération d'un stock spécifique
 */
async function testGetSpecificStock() {
  if (!testProductId) {
    console.log('⚠️ Pas de produit de test, skip du test stock spécifique');
    return true;
  }

  try {
    console.log(`📦 Test: Récupération du stock du produit ${testProductId}...`);
    
    const response = await axios.get(`${API_BASE_URL}/inventory/${testProductId}`, testConfig);
    
    console.log('✅ Stock spécifique récupéré:', {
      success: response.data.success,
      produitId: response.data.data.produitId,
      quantiteDisponible: response.data.data.quantiteDisponible,
      stockFaible: response.data.data.stockFaible
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur récupération stock spécifique:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test d'ajustement de stock
 */
async function testStockAdjustment() {
  if (!testProductId) {
    console.log('⚠️ Pas de produit de test, skip du test ajustement');
    return true;
  }

  try {
    console.log(`🔧 Test: Ajustement de stock (+10 unités)...`);
    
    const response = await axios.post(`${API_BASE_URL}/inventory/adjust`, {
      produitId: testProductId,
      changementQuantite: 10,
      notes: 'Test d\'ajustement automatique'
    }, testConfig);
    
    console.log('✅ Ajustement de stock réussi:', {
      success: response.data.success,
      nouvelleQuantite: response.data.data.quantiteDisponible,
      message: response.data.message
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur ajustement stock:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test d'ajustement négatif (réduction de stock)
 */
async function testNegativeStockAdjustment() {
  if (!testProductId) {
    console.log('⚠️ Pas de produit de test, skip du test ajustement négatif');
    return true;
  }

  try {
    console.log(`🔧 Test: Ajustement de stock (-3 unités)...`);
    
    const response = await axios.post(`${API_BASE_URL}/inventory/adjust`, {
      produitId: testProductId,
      changementQuantite: -3,
      notes: 'Test de réduction de stock'
    }, testConfig);
    
    console.log('✅ Réduction de stock réussie:', {
      success: response.data.success,
      nouvelleQuantite: response.data.data.quantiteDisponible,
      message: response.data.message
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur réduction stock:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test des alertes de stock
 */
async function testStockAlerts() {
  try {
    console.log('🚨 Test: Récupération des alertes de stock...');
    
    const response = await axios.get(`${API_BASE_URL}/inventory/alerts?page=1&limit=5`, testConfig);
    
    console.log('✅ Alertes de stock récupérées:', {
      success: response.data.success,
      totalAlertes: response.data.pagination?.total || 0,
      alertesCount: response.data.data?.length || 0
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur récupération alertes:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test des mouvements de stock
 */
async function testStockMovements() {
  try {
    console.log('📊 Test: Récupération des mouvements de stock...');
    
    const response = await axios.get(`${API_BASE_URL}/inventory/movements?page=1&limit=10`, testConfig);
    
    console.log('✅ Mouvements de stock récupérés:', {
      success: response.data.success,
      totalMouvements: response.data.pagination?.total || 0,
      mouvementsCount: response.data.data?.length || 0
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur récupération mouvements:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test du résumé de stock
 */
async function testStockSummary() {
  try {
    console.log('📈 Test: Récupération du résumé de stock...');
    
    const response = await axios.get(`${API_BASE_URL}/inventory/summary`, testConfig);
    
    console.log('✅ Résumé de stock récupéré:', {
      success: response.data.success,
      totalProduits: response.data.data.totalProduits,
      produitsEnStock: response.data.data.produitsEnStock,
      produitsEnAlerte: response.data.data.produitsEnAlerte,
      valeurTotaleStock: response.data.data.valeurTotaleStock
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur récupération résumé:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test d'ajustement en lot
 */
async function testBulkAdjustment() {
  if (!testProductId) {
    console.log('⚠️ Pas de produit de test, skip du test ajustement en lot');
    return true;
  }

  try {
    console.log('🔧 Test: Ajustement en lot...');
    
    const response = await axios.post(`${API_BASE_URL}/inventory/bulk-adjust`, {
      ajustements: [
        {
          produitId: testProductId,
          changementQuantite: 5,
          notes: 'Ajustement en lot test'
        }
      ],
      notes: 'Test d\'ajustement en lot automatique'
    }, testConfig);
    
    console.log('✅ Ajustement en lot réussi:', {
      success: response.data.success,
      ajustementsReussis: response.data.data.ajustementsReussis,
      ajustementsEchoues: response.data.data.ajustementsEchoues
    });
    
    return true;
  } catch (error) {
    console.error('❌ Erreur ajustement en lot:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test de validation des erreurs
 */
async function testValidationErrors() {
  try {
    console.log('🧪 Test: Validation des erreurs...');
    
    // Test ajustement avec produit inexistant
    try {
      await axios.post(`${API_BASE_URL}/inventory/adjust`, {
        produitId: 99999,
        changementQuantite: 10,
        notes: 'Test erreur'
      }, testConfig);
      console.log('⚠️ L\'erreur attendue n\'a pas été déclenchée');
      return false;
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Erreur 404 correctement détectée pour produit inexistant');
      } else {
        console.log('⚠️ Erreur inattendue:', error.response?.status);
      }
    }

    // Test ajustement avec données invalides
    try {
      await axios.post(`${API_BASE_URL}/inventory/adjust`, {
        produitId: 'invalid',
        changementQuantite: 'not_a_number'
      }, testConfig);
      console.log('⚠️ L\'erreur de validation attendue n\'a pas été déclenchée');
      return false;
    } catch (error) {
      if (error.response?.status === 400) {
        console.log('✅ Erreur de validation correctement détectée');
      } else {
        console.log('⚠️ Erreur inattendue:', error.response?.status);
      }
    }
    
    return true;
  } catch (error) {
    console.error('❌ Erreur test validation:', error.message);
    return false;
  }
}

/**
 * Fonction principale de test
 */
async function runInventoryTests() {
  console.log('🚀 Démarrage des tests d\'inventaire LOGESCO\n');

  const tests = [
    { name: 'Authentification', fn: authenticate },
    { name: 'Création produit de test', fn: createTestProduct },
    { name: 'Liste des stocks', fn: testGetInventoryList },
    { name: 'Stock spécifique', fn: testGetSpecificStock },
    { name: 'Ajustement de stock', fn: testStockAdjustment },
    { name: 'Réduction de stock', fn: testNegativeStockAdjustment },
    { name: 'Alertes de stock', fn: testStockAlerts },
    { name: 'Mouvements de stock', fn: testStockMovements },
    { name: 'Résumé de stock', fn: testStockSummary },
    { name: 'Ajustement en lot', fn: testBulkAdjustment },
    { name: 'Validation des erreurs', fn: testValidationErrors }
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      const result = await test.fn();
      if (result) {
        passed++;
        console.log(`✅ ${test.name} - RÉUSSI\n`);
      } else {
        failed++;
        console.log(`❌ ${test.name} - ÉCHOUÉ\n`);
      }
    } catch (error) {
      failed++;
      console.log(`❌ ${test.name} - ERREUR: ${error.message}\n`);
    }
  }

  console.log('📊 Résultats des tests d\'inventaire:');
  console.log(`✅ Tests réussis: ${passed}`);
  console.log(`❌ Tests échoués: ${failed}`);
  console.log(`📈 Taux de réussite: ${Math.round((passed / (passed + failed)) * 100)}%`);

  if (failed === 0) {
    console.log('\n🎉 Tous les tests d\'inventaire sont passés avec succès!');
    console.log('✅ Les endpoints d\'inventaire sont prêts à être utilisés');
  } else {
    console.log('\n⚠️ Certains tests ont échoué. Vérifiez les erreurs ci-dessus.');
  }

  return failed === 0;
}

// Exécuter les tests si ce fichier est appelé directement
if (require.main === module) {
  runInventoryTests()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Erreur fatale:', error);
      process.exit(1);
    });
}

module.exports = { runInventoryTests };