/**
 * Script de test pour le système de comptes clients amélioré
 * Test les nouvelles fonctionnalités de liaison vente-transaction
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';
let authToken = '';

// Configuration
const TEST_CLIENT_ID = 1; // À ajuster selon votre base de données

/**
 * Authentification
 */
async function login() {
  try {
    console.log('🔐 Authentification...');
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'admin@logesco.com',
      motDePasse: 'Admin@2024'
    });
    
    authToken = response.data.data.token;
    console.log('✅ Authentification réussie\n');
    return true;
  } catch (error) {
    console.error('❌ Erreur authentification:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test 1: Récupérer les ventes impayées d'un client
 */
async function testGetUnpaidSales() {
  try {
    console.log('📋 Test 1: Récupération des ventes impayées');
    console.log(`   Client ID: ${TEST_CLIENT_ID}`);
    
    const response = await axios.get(
      `${BASE_URL}/accounts/customers/${TEST_CLIENT_ID}/unpaid-sales`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const ventes = response.data.data;
    console.log(`✅ ${ventes.length} vente(s) impayée(s) trouvée(s)`);
    
    if (ventes.length > 0) {
      console.log('\n   Détails des ventes impayées:');
      ventes.forEach((vente, index) => {
        console.log(`   ${index + 1}. Vente #${vente.reference}`);
        console.log(`      - Date: ${new Date(vente.dateVente).toLocaleDateString()}`);
        console.log(`      - Total: ${vente.montantTotal} FCFA`);
        console.log(`      - Payé: ${vente.montantPaye} FCFA`);
        console.log(`      - Reste: ${vente.montantRestant} FCFA`);
        console.log(`      - Articles: ${vente.nombreArticles}`);
      });
    }
    
    console.log('');
    return ventes;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return [];
  }
}

/**
 * Test 2: Créer une transaction liée à une vente
 */
async function testCreateTransactionWithSale(venteId, venteReference, montant) {
  try {
    console.log('💳 Test 2: Création d\'une transaction liée à une vente');
    console.log(`   Vente ID: ${venteId}`);
    console.log(`   Référence: ${venteReference}`);
    console.log(`   Montant: ${montant} FCFA`);
    
    const response = await axios.post(
      `${BASE_URL}/accounts/customers/${TEST_CLIENT_ID}/transactions`,
      {
        montant: montant,
        typeTransaction: 'paiement',
        typeTransactionDetail: 'paiement_dette',
        venteId: venteId,
        description: `Paiement Dette (Vente #${venteReference})`
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const compte = response.data.data;
    console.log('✅ Transaction créée avec succès');
    console.log(`   Nouveau solde: ${compte.soldeActuel} FCFA`);
    console.log(`   Crédit disponible: ${compte.creditDisponible} FCFA`);
    
    if (compte.derniereTransaction) {
      console.log('\n   Détails de la transaction:');
      console.log(`   - ID: ${compte.derniereTransaction.id}`);
      console.log(`   - Type: ${compte.derniereTransaction.typeTransaction}`);
      console.log(`   - Montant: ${compte.derniereTransaction.montant} FCFA`);
      console.log(`   - Description: ${compte.derniereTransaction.description}`);
    }
    
    console.log('');
    return true;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test 3: Récupérer l'historique des transactions
 */
async function testGetTransactionHistory() {
  try {
    console.log('📜 Test 3: Récupération de l\'historique des transactions');
    
    const response = await axios.get(
      `${BASE_URL}/accounts/customers/${TEST_CLIENT_ID}/transactions`,
      {
        headers: { Authorization: `Bearer ${authToken}` },
        params: { page: 1, limit: 10 }
      }
    );
    
    const transactions = response.data.data;
    console.log(`✅ ${transactions.length} transaction(s) trouvée(s)`);
    
    if (transactions.length > 0) {
      console.log('\n   Dernières transactions:');
      transactions.slice(0, 5).forEach((trans, index) => {
        console.log(`   ${index + 1}. ${trans.typeTransaction.toUpperCase()}`);
        console.log(`      - Montant: ${trans.montant} FCFA`);
        console.log(`      - Date: ${new Date(trans.dateTransaction).toLocaleString()}`);
        console.log(`      - Solde après: ${trans.soldeApres} FCFA`);
        if (trans.venteReference) {
          console.log(`      - Vente: #${trans.venteReference}`);
        }
        if (trans.description) {
          console.log(`      - Description: ${trans.description}`);
        }
      });
    }
    
    console.log('');
    return transactions;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return [];
  }
}

/**
 * Test 4: Vérifier qu'une vente n'appartenant pas au client est rejetée
 */
async function testInvalidSaleRejection() {
  try {
    console.log('🚫 Test 4: Validation - Vente d\'un autre client');
    
    // Essayer de payer une vente qui n'appartient pas au client
    const response = await axios.post(
      `${BASE_URL}/accounts/customers/${TEST_CLIENT_ID}/transactions`,
      {
        montant: 1000,
        typeTransaction: 'paiement',
        typeTransactionDetail: 'paiement_dette',
        venteId: 99999, // ID invalide
        description: 'Test validation'
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('❌ La validation a échoué - la transaction a été acceptée');
    console.log('');
    return false;
  } catch (error) {
    if (error.response?.status === 404 || error.response?.status === 400) {
      console.log('✅ Validation réussie - vente invalide rejetée');
      console.log(`   Message: ${error.response.data.message}`);
      console.log('');
      return true;
    } else {
      console.error('❌ Erreur inattendue:', error.response?.data || error.message);
      console.log('');
      return false;
    }
  }
}

/**
 * Test 5: Vérifier le solde du compte client
 */
async function testGetAccountBalance() {
  try {
    console.log('💰 Test 5: Récupération du solde du compte');
    
    const response = await axios.get(
      `${BASE_URL}/accounts/customers/${TEST_CLIENT_ID}/balance`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const compte = response.data.data;
    console.log('✅ Solde récupéré avec succès');
    console.log(`   Client: ${compte.client.nomComplet}`);
    console.log(`   Solde actuel: ${compte.soldeActuel} FCFA`);
    console.log(`   Limite crédit: ${compte.limiteCredit} FCFA`);
    console.log(`   Crédit disponible: ${compte.creditDisponible} FCFA`);
    console.log(`   En dépassement: ${compte.estEnDepassement ? 'Oui' : 'Non'}`);
    console.log('');
    return compte;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    console.log('');
    return null;
  }
}

/**
 * Exécution des tests
 */
async function runTests() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('   TEST SYSTÈME COMPTES CLIENTS AMÉLIORÉ');
  console.log('═══════════════════════════════════════════════════════\n');
  
  // Authentification
  const authenticated = await login();
  if (!authenticated) {
    console.log('❌ Impossible de continuer sans authentification');
    return;
  }
  
  // Test 5: Solde initial
  await testGetAccountBalance();
  
  // Test 1: Ventes impayées
  const ventesImpayees = await testGetUnpaidSales();
  
  // Test 2: Créer une transaction si des ventes impayées existent
  if (ventesImpayees.length > 0) {
    const premiereVente = ventesImpayees[0];
    const montantAPayer = Math.min(1000, premiereVente.montantRestant); // Payer 1000 FCFA ou le reste
    
    await testCreateTransactionWithSale(
      premiereVente.id,
      premiereVente.reference,
      montantAPayer
    );
  } else {
    console.log('ℹ️  Aucune vente impayée - Test 2 ignoré\n');
  }
  
  // Test 3: Historique
  await testGetTransactionHistory();
  
  // Test 4: Validation
  await testInvalidSaleRejection();
  
  // Test 5: Solde final
  await testGetAccountBalance();
  
  console.log('═══════════════════════════════════════════════════════');
  console.log('   TESTS TERMINÉS');
  console.log('═══════════════════════════════════════════════════════\n');
}

// Exécuter les tests
runTests().catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
