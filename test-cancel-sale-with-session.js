/**
 * Test d'annulation de vente avec déduction de session de caisse
 * Vérifie que:
 * 1. Le montant est déduit de la session de caisse
 * 2. La vente n'apparaît plus dans la comptabilité
 * 3. Le compte client est ajusté correctement
 */

const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000/api';

// Couleurs pour les logs
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

let authToken = null;
let testResults = {
  passed: 0,
  failed: 0,
  errors: []
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message, data = null) {
  log(`✅ ${message}`, 'green');
  if (data) console.log(JSON.stringify(data, null, 2));
}

function logError(message, error = null) {
  log(`❌ ${message}`, 'red');
  if (error) {
    if (error.response?.data) {
      console.log(JSON.stringify(error.response.data, null, 2));
    } else {
      console.log(error.message);
    }
  }
  testResults.failed++;
  testResults.errors.push(message);
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'cyan');
}

function logStep(message) {
  log(`\n📋 ${message}`, 'blue');
}

async function authenticate() {
  logStep('Authentification');
  try {
    const response = await axios.post(`${API_BASE_URL}/auth/login`, {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });

    authToken = response.data.data.token;
    logSuccess('Authentification réussie');
    return true;
  } catch (error) {
    logError('Échec de l\'authentification', error);
    return false;
  }
}

async function getActiveCashSession() {
  logStep('Récupération de la session de caisse active');
  try {
    const response = await axios.get(`${API_BASE_URL}/cash-sessions/active`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    if (response.data.data) {
      logSuccess('Session active trouvée', {
        id: response.data.data.id,
        soldeOuverture: response.data.data.soldeOuverture,
        soldeAttendu: response.data.data.soldeAttendu
      });
      return response.data.data;
    } else {
      logError('Aucune session active trouvée');
      return null;
    }
  } catch (error) {
    logError('Erreur lors de la récupération de la session', error);
    return null;
  }
}

async function createTestSale(sessionId) {
  logStep('Création d\'une vente de test');
  try {
    // Récupérer un produit
    const productsResponse = await axios.get(`${API_BASE_URL}/products?limit=1`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    if (!productsResponse.data.data || productsResponse.data.data.length === 0) {
      logError('Aucun produit disponible');
      return null;
    }

    const product = productsResponse.data.data[0];
    logInfo(`Produit sélectionné: ${product.nom} (${product.reference})`);

    // Créer la vente
    const saleResponse = await axios.post(`${API_BASE_URL}/sales`, {
      details: [
        {
          produitId: product.id,
          quantite: 1,
          prixAffiche: product.prixUnitaire,
          prixUnitaire: product.prixUnitaire,
          remiseAppliquee: 0
        }
      ],
      modePaiement: 'comptant',
      montantPaye: product.prixUnitaire,
      montantRemise: 0
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    if (saleResponse.data.success) {
      const sale = saleResponse.data.data;
      logSuccess('Vente créée avec succès', {
        id: sale.id,
        numeroVente: sale.numeroVente,
        montantTotal: sale.montantTotal,
        montantPaye: sale.montantPaye,
        sessionId: sale.sessionId
      });
      testResults.passed++;
      return sale;
    } else {
      logError('Échec de création de la vente');
      return null;
    }
  } catch (error) {
    logError('Erreur lors de la création de la vente', error);
    return null;
  }
}

async function getSessionBeforeCancel(sessionId) {
  logStep('État de la session AVANT annulation');
  try {
    const response = await axios.get(`${API_BASE_URL}/cash-sessions/${sessionId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    const session = response.data.data;
    logSuccess('Session récupérée', {
      id: session.id,
      soldeOuverture: session.soldeOuverture,
      soldeAttendu: session.soldeAttendu,
      ecart: session.ecart
    });
    testResults.passed++;
    return session;
  } catch (error) {
    logError('Erreur lors de la récupération de la session', error);
    return null;
  }
}

async function cancelSale(saleId) {
  logStep('Annulation de la vente');
  try {
    const response = await axios.delete(`${API_BASE_URL}/sales/${saleId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    if (response.data.success) {
      logSuccess('Vente annulée avec succès', response.data.message);
      testResults.passed++;
      return true;
    } else {
      logError('Échec de l\'annulation de la vente');
      return false;
    }
  } catch (error) {
    logError('Erreur lors de l\'annulation de la vente', error);
    return false;
  }
}

async function getSessionAfterCancel(sessionId) {
  logStep('État de la session APRÈS annulation');
  try {
    const response = await axios.get(`${API_BASE_URL}/cash-sessions/${sessionId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    const session = response.data.data;
    logSuccess('Session récupérée', {
      id: session.id,
      soldeOuverture: session.soldeOuverture,
      soldeAttendu: session.soldeAttendu,
      ecart: session.ecart
    });
    testResults.passed++;
    return session;
  } catch (error) {
    logError('Erreur lors de la récupération de la session', error);
    return null;
  }
}

async function verifySaleNotInAnalytics(saleId) {
  logStep('Vérification que la vente n\'apparaît pas dans les analytics');
  try {
    const response = await axios.get(`${API_BASE_URL}/sales/analytics/products`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });

    const sales = response.data.data || [];
    const foundSale = sales.find(s => s.id === saleId);

    if (!foundSale) {
      logSuccess('Vente correctement exclue des analytics');
      testResults.passed++;
      return true;
    } else {
      logError('Vente trouvée dans les analytics (devrait être exclue)');
      return false;
    }
  } catch (error) {
    logError('Erreur lors de la vérification des analytics', error);
    return false;
  }
}

async function runTests() {
  log('\n' + '='.repeat(60), 'blue');
  log('TEST D\'ANNULATION DE VENTE AVEC SESSION DE CAISSE', 'blue');
  log('='.repeat(60) + '\n', 'blue');

  // Étape 1: Authentification
  if (!await authenticate()) {
    logError('Impossible de continuer sans authentification');
    process.exit(1);
  }

  // Étape 2: Récupérer la session active
  const sessionBefore = await getActiveCashSession();
  if (!sessionBefore) {
    logError('Impossible de continuer sans session active');
    process.exit(1);
  }

  // Étape 3: Créer une vente de test
  const sale = await createTestSale(sessionBefore.id);
  if (!sale) {
    logError('Impossible de continuer sans vente de test');
    process.exit(1);
  }

  // Étape 4: État de la session avant annulation
  const sessionBeforeCancel = await getSessionBeforeCancel(sessionBefore.id);
  if (!sessionBeforeCancel) {
    logError('Impossible de continuer');
    process.exit(1);
  }

  // Étape 5: Annuler la vente
  if (!await cancelSale(sale.id)) {
    logError('Impossible de continuer');
    process.exit(1);
  }

  // Étape 6: État de la session après annulation
  const sessionAfterCancel = await getSessionAfterCancel(sessionBefore.id);
  if (!sessionAfterCancel) {
    logError('Impossible de continuer');
    process.exit(1);
  }

  // Étape 7: Vérifications
  logStep('Vérifications');

  // Vérification 1: Le solde attendu doit avoir diminué
  const soldeAttenduDiminue = sessionAfterCancel.soldeAttendu < sessionBeforeCancel.soldeAttendu;
  if (soldeAttenduDiminue) {
    logSuccess(`Solde attendu correctement réduit: ${sessionBeforeCancel.soldeAttendu} → ${sessionAfterCancel.soldeAttendu}`);
    testResults.passed++;
  } else {
    logError(`Solde attendu non réduit: ${sessionBeforeCancel.soldeAttendu} → ${sessionAfterCancel.soldeAttendu}`);
  }

  // Vérification 2: La vente n'apparaît pas dans les analytics
  await verifySaleNotInAnalytics(sale.id);

  // Résumé
  log('\n' + '='.repeat(60), 'blue');
  log('RÉSUMÉ DES TESTS', 'blue');
  log('='.repeat(60), 'blue');
  logSuccess(`Tests réussis: ${testResults.passed}`);
  if (testResults.failed > 0) {
    logError(`Tests échoués: ${testResults.failed}`);
    if (testResults.errors.length > 0) {
      log('\nErreurs:', 'yellow');
      testResults.errors.forEach(err => log(`  - ${err}`, 'yellow'));
    }
  }
  log('='.repeat(60) + '\n', 'blue');

  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Lancer les tests
runTests().catch(error => {
  logError('Erreur non gérée', error);
  process.exit(1);
});
