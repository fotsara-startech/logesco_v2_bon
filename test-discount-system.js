/**
 * Test du système de remises sécurisées - LOGESCO v2
 * Validation complète des fonctionnalités de remise
 */

const axios = require('axios');

const API_BASE_URL = 'http://localhost:8080/api/v1';
let authToken = '';

// Configuration de test
const testConfig = {
  adminCredentials: {
    nomUtilisateur: 'admin',
    motDePasse: 'admin123'
  },
  testProduct: {
    reference: 'TESTREMISE001',
    nom: 'Produit Test Remise',
    description: 'Produit pour tester le système de remises',
    prixUnitaire: 10000,
    prixAchat: 7000,
    remiseMaxAutorisee: 2000, // Remise max de 2000 FCFA
    seuilStockMinimum: 5,
    estActif: true,
    estService: false
  }
};

/**
 * Utilitaires de test
 */
function log(message, data = null) {
  console.log(`[${new Date().toISOString()}] ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

function logError(message, error) {
  console.error(`[${new Date().toISOString()}] ❌ ${message}`);
  if (error.response) {
    console.error('Status:', error.response.status);
    console.error('Data:', error.response.data);
  } else {
    console.error('Error:', error.message);
  }
}

function logSuccess(message, data = null) {
  console.log(`[${new Date().toISOString()}] ✅ ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

/**
 * Authentification
 */
async function authenticate() {
  try {
    log('🔐 Authentification...');
    
    const response = await axios.post(`${API_BASE_URL}/auth/login`, testConfig.adminCredentials);
    
    if (response.data.success && response.data.data.accessToken) {
      authToken = response.data.data.accessToken;
      logSuccess('Authentification réussie');
      return true;
    } else {
      logError('Échec de l\'authentification', new Error('Token non reçu'));
      return false;
    }
  } catch (error) {
    logError('Erreur d\'authentification', error);
    return false;
  }
}

/**
 * Configuration des headers avec authentification
 */
function getAuthHeaders() {
  return {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  };
}

/**
 * Test 1: Créer un produit avec remise maximale autorisée
 */
async function testCreateProductWithDiscount() {
  try {
    log('📦 Test 1: Création d\'un produit avec remise maximale...');
    
    const response = await axios.post(
      `${API_BASE_URL}/products`,
      testConfig.testProduct,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success) {
      const product = response.data.data;
      logSuccess('Produit créé avec succès', {
        id: product.id,
        reference: product.reference,
        nom: product.nom,
        prixUnitaire: product.prixUnitaire,
        remiseMaxAutorisee: product.remiseMaxAutorisee
      });
      return product;
    } else {
      throw new Error('Échec de création du produit');
    }
  } catch (error) {
    logError('Test 1 échoué', error);
    return null;
  }
}

/**
 * Test 2: Valider une remise autorisée
 */
async function testValidateAuthorizedDiscount(productId) {
  try {
    log('✅ Test 2: Validation d\'une remise autorisée...');
    
    const discountData = {
      produitId: productId,
      remiseAppliquee: 1500, // Dans la limite de 2000 FCFA
      justificationRemise: 'Client fidèle - remise de fidélité'
    };
    
    const response = await axios.post(
      `${API_BASE_URL}/sales/validate-discount`,
      discountData,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success && response.data.data.isValid) {
      logSuccess('Remise autorisée validée', {
        remiseAppliquee: response.data.data.remise.appliquee,
        maxAutorisee: response.data.data.remise.maxAutorisee,
        prixFinal: response.data.data.prixFinal,
        message: response.data.data.message
      });
      return true;
    } else {
      throw new Error('La remise devrait être autorisée');
    }
  } catch (error) {
    logError('Test 2 échoué', error);
    return false;
  }
}

/**
 * Test 3: Valider une remise non autorisée
 */
async function testValidateUnauthorizedDiscount(productId) {
  try {
    log('❌ Test 3: Validation d\'une remise non autorisée...');
    
    const discountData = {
      produitId: productId,
      remiseAppliquee: 3000, // Dépasse la limite de 2000 FCFA
      justificationRemise: 'Remise excessive'
    };
    
    const response = await axios.post(
      `${API_BASE_URL}/sales/validate-discount`,
      discountData,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success && !response.data.data.isValid) {
      logSuccess('Remise non autorisée correctement rejetée', {
        remiseAppliquee: response.data.data.remise.appliquee,
        maxAutorisee: response.data.data.remise.maxAutorisee,
        message: response.data.data.message
      });
      return true;
    } else {
      throw new Error('La remise devrait être rejetée');
    }
  } catch (error) {
    logError('Test 3 échoué', error);
    return false;
  }
}

/**
 * Test 4: Créer une vente avec remise autorisée
 */
async function testCreateSaleWithAuthorizedDiscount(productId) {
  try {
    log('💰 Test 4: Création d\'une vente avec remise autorisée...');
    
    const saleData = {
      clientId: null, // Vente sans client
      modePaiement: 'comptant',
      montantPaye: 8500, // Prix final après remise
      details: [
        {
          produitId: productId,
          quantite: 1,
          prixAffiche: 10000, // Prix original
          prixUnitaire: 8500, // Prix après remise de 1500 FCFA
          remiseAppliquee: 1500,
          justificationRemise: 'Promotion spéciale'
        }
      ]
    };
    
    const response = await axios.post(
      `${API_BASE_URL}/sales`,
      saleData,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success) {
      const sale = response.data.data;
      logSuccess('Vente avec remise créée avec succès', {
        id: sale.id,
        numeroVente: sale.numeroVente,
        sousTotal: sale.sousTotal,
        montantTotal: sale.montantTotal,
        details: sale.details.map(d => ({
          produit: d.produit.nom,
          prixAffiche: d.prixAffiche,
          remiseAppliquee: d.remiseAppliquee,
          prixFinal: d.prixUnitaire,
          justification: d.justificationRemise
        }))
      });
      return sale;
    } else {
      throw new Error('Échec de création de la vente');
    }
  } catch (error) {
    logError('Test 4 échoué', error);
    return null;
  }
}

/**
 * Test 5: Tenter de créer une vente avec remise non autorisée
 */
async function testCreateSaleWithUnauthorizedDiscount(productId) {
  try {
    log('🚫 Test 5: Tentative de vente avec remise non autorisée...');
    
    const saleData = {
      clientId: null,
      modePaiement: 'comptant',
      montantPaye: 7000, // Prix après remise excessive
      details: [
        {
          produitId: productId,
          quantite: 1,
          prixAffiche: 10000,
          prixUnitaire: 7000, // Prix après remise de 3000 FCFA (non autorisée)
          remiseAppliquee: 3000,
          justificationRemise: 'Remise excessive non autorisée'
        }
      ]
    };
    
    const response = await axios.post(
      `${API_BASE_URL}/sales`,
      saleData,
      { headers: getAuthHeaders() }
    );
    
    // Cette requête devrait échouer
    logError('Test 5 échoué - La vente n\'aurait pas dû être autorisée', new Error('Vente créée malgré remise non autorisée'));
    return false;
  } catch (error) {
    if (error.response && error.response.status === 400) {
      logSuccess('Vente avec remise non autorisée correctement rejetée', {
        status: error.response.status,
        message: error.response.data.message
      });
      return true;
    } else {
      logError('Test 5 échoué avec erreur inattendue', error);
      return false;
    }
  }
}

/**
 * Test 6: Générer un rapport de remises
 */
async function testDiscountReport() {
  try {
    log('📊 Test 6: Génération du rapport de remises...');
    
    const response = await axios.get(
      `${API_BASE_URL}/discount-reports/summary?groupBy=vendeur`,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success) {
      logSuccess('Rapport de remises généré avec succès', {
        groupBy: response.data.data.groupBy,
        nombreGroupes: response.data.data.groupes.length,
        totaux: response.data.data.totaux
      });
      return true;
    } else {
      throw new Error('Échec de génération du rapport');
    }
  } catch (error) {
    logError('Test 6 échoué', error);
    return false;
  }
}

/**
 * Test 7: Top des remises
 */
async function testTopDiscounts() {
  try {
    log('🏆 Test 7: Récupération du top des remises...');
    
    const response = await axios.get(
      `${API_BASE_URL}/discount-reports/top-discounts?limit=5`,
      { headers: getAuthHeaders() }
    );
    
    if (response.data.success) {
      logSuccess('Top des remises récupéré avec succès', {
        nombreRemises: response.data.data.length,
        topRemises: response.data.data.slice(0, 3).map(d => ({
          produit: d.produit.nom,
          remise: d.remiseAppliquee,
          pourcentageUtilise: d.pourcentageUtilise.toFixed(1) + '%',
          economieClient: d.economieClient
        }))
      });
      return true;
    } else {
      throw new Error('Échec de récupération du top des remises');
    }
  } catch (error) {
    logError('Test 7 échoué', error);
    return false;
  }
}

/**
 * Nettoyage: Supprimer le produit de test
 */
async function cleanup(productId) {
  try {
    log('🧹 Nettoyage: Suppression du produit de test...');
    
    await axios.delete(
      `${API_BASE_URL}/products/${productId}`,
      { headers: getAuthHeaders() }
    );
    
    logSuccess('Produit de test supprimé');
  } catch (error) {
    logError('Erreur lors du nettoyage', error);
  }
}

/**
 * Fonction principale de test
 */
async function runDiscountSystemTests() {
  console.log('🚀 Démarrage des tests du système de remises sécurisées');
  console.log('=' .repeat(60));
  
  let testResults = {
    total: 7,
    passed: 0,
    failed: 0
  };
  
  // Authentification
  if (!(await authenticate())) {
    console.log('❌ Impossible de continuer sans authentification');
    return;
  }
  
  let productId = null;
  
  try {
    // Test 1: Créer un produit avec remise
    const product = await testCreateProductWithDiscount();
    if (product) {
      productId = product.id;
      testResults.passed++;
    } else {
      testResults.failed++;
    }
    
    if (productId) {
      // Test 2: Valider remise autorisée
      if (await testValidateAuthorizedDiscount(productId)) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Test 3: Valider remise non autorisée
      if (await testValidateUnauthorizedDiscount(productId)) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Test 4: Vente avec remise autorisée
      if (await testCreateSaleWithAuthorizedDiscount(productId)) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Test 5: Vente avec remise non autorisée
      if (await testCreateSaleWithUnauthorizedDiscount(productId)) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Test 6: Rapport de remises
      if (await testDiscountReport()) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Test 7: Top des remises
      if (await testTopDiscounts()) {
        testResults.passed++;
      } else {
        testResults.failed++;
      }
      
      // Nettoyage
      await cleanup(productId);
    } else {
      // Si pas de produit créé, marquer les autres tests comme échoués
      testResults.failed += 6;
    }
    
  } catch (error) {
    logError('Erreur générale lors des tests', error);
  }
  
  // Résultats finaux
  console.log('=' .repeat(60));
  console.log('📋 RÉSULTATS DES TESTS');
  console.log('=' .repeat(60));
  console.log(`✅ Tests réussis: ${testResults.passed}/${testResults.total}`);
  console.log(`❌ Tests échoués: ${testResults.failed}/${testResults.total}`);
  console.log(`📊 Taux de réussite: ${((testResults.passed / testResults.total) * 100).toFixed(1)}%`);
  
  if (testResults.passed === testResults.total) {
    console.log('🎉 Tous les tests sont passés ! Le système de remises fonctionne correctement.');
  } else {
    console.log('⚠️  Certains tests ont échoué. Vérifiez les logs ci-dessus.');
  }
}

// Exécuter les tests si le script est appelé directement
if (require.main === module) {
  runDiscountSystemTests().catch(error => {
    console.error('Erreur fatale lors des tests:', error);
    process.exit(1);
  });
}

module.exports = {
  runDiscountSystemTests,
  testConfig
};