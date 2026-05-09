/**
 * Script de test pour vérifier le paiement comptant des approvisionnements
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/api';

// Configuration
const TEST_CONFIG = {
  username: 'admin',
  password: 'admin123'
};

let authToken = null;

async function login() {
  try {
    console.log('🔐 Connexion...');
    const response = await axios.post(`${API_URL}/auth/login`, {
      username: TEST_CONFIG.username,
      password: TEST_CONFIG.password
    });
    
    authToken = response.data.token;
    console.log('✅ Connecté avec succès\n');
    return authToken;
  } catch (error) {
    console.error('❌ Erreur de connexion:', error.response?.data || error.message);
    throw error;
  }
}

async function createSupplier() {
  try {
    console.log('📝 Création d\'un nouveau fournisseur...');
    const response = await axios.post(
      `${API_URL}/suppliers`,
      {
        nom: `Fournisseur Test ${Date.now()}`,
        telephone: '0123456789',
        email: 'test@fournisseur.com'
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('✅ Fournisseur créé:', response.data.data.nom);
    console.log('   ID:', response.data.data.id);
    return response.data.data;
  } catch (error) {
    console.error('❌ Erreur création fournisseur:', error.response?.data || error.message);
    throw error;
  }
}

async function getProducts() {
  try {
    console.log('\n📦 Récupération des produits...');
    const response = await axios.get(
      `${API_URL}/products?limit=5`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const products = response.data.data.produits || response.data.data;
    console.log(`✅ ${products.length} produits trouvés`);
    return products;
  } catch (error) {
    console.error('❌ Erreur récupération produits:', error.response?.data || error.message);
    throw error;
  }
}

async function createProcurementOrder(supplierId, products) {
  try {
    console.log('\n📋 Création d\'une commande d\'approvisionnement...');
    
    const details = products.slice(0, 2).map(product => ({
      produitId: product.id,
      quantiteCommandee: 10,
      coutUnitaire: product.prixAchat || product.prixUnitaire * 0.8
    }));
    
    const response = await axios.post(
      `${API_URL}/procurement`,
      {
        fournisseurId: supplierId,
        dateLivraisonPrevue: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        modePaiement: 'credit', // Par défaut crédit
        notes: 'Test paiement comptant',
        details
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('✅ Commande créée:', response.data.data.numeroCommande);
    console.log('   ID:', response.data.data.id);
    console.log('   Montant:', response.data.data.montantTotal, 'FCFA');
    console.log('   Mode paiement initial:', response.data.data.modePaiement);
    return response.data.data;
  } catch (error) {
    console.error('❌ Erreur création commande:', error.response?.data || error.message);
    throw error;
  }
}

async function receiveOrder(orderId, orderDetails, modePaiement) {
  try {
    console.log(`\n📥 Réception de la commande avec mode: ${modePaiement}...`);
    
    const details = orderDetails.map(detail => ({
      detailId: detail.id,
      quantiteRecue: detail.quantiteCommandee
    }));
    
    console.log('📤 Envoi de la requête de réception avec:');
    console.log('   - details:', JSON.stringify(details, null, 2));
    console.log('   - modePaiement:', modePaiement);
    
    const response = await axios.put(
      `${API_URL}/procurement/${orderId}/receive`,
      {
        details,
        modePaiement // IMPORTANT: Envoyer le mode de paiement
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('✅ Réception enregistrée');
    console.log('   Statut:', response.data.data.statut);
    console.log('   Mode paiement final:', response.data.data.modePaiement);
    return response.data.data;
  } catch (error) {
    console.error('❌ Erreur réception:', error.response?.data || error.message);
    throw error;
  }
}

async function getSupplierAccount(supplierId) {
  try {
    console.log(`\n💰 Vérification du compte fournisseur ${supplierId}...`);
    const response = await axios.get(
      `${API_URL}/accounts/suppliers/${supplierId}`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const account = response.data.data;
    console.log('✅ Compte fournisseur:');
    console.log('   Solde actuel:', account.soldeActuel, 'FCFA');
    return account;
  } catch (error) {
    console.error('❌ Erreur récupération compte:', error.response?.data || error.message);
    throw error;
  }
}

async function getSupplierTransactions(supplierId) {
  try {
    console.log(`\n📊 Récupération des transactions du fournisseur ${supplierId}...`);
    const response = await axios.get(
      `${API_URL}/accounts/suppliers/${supplierId}/transactions`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    const transactions = response.data.data.transactions || response.data.data;
    console.log(`✅ ${transactions.length} transaction(s) trouvée(s):\n`);
    
    transactions.forEach((tx, index) => {
      console.log(`   ${index + 1}. ${tx.typeTransaction.toUpperCase()}`);
      console.log(`      Montant: ${tx.montant} FCFA`);
      console.log(`      Description: ${tx.description}`);
      console.log(`      Solde après: ${tx.soldeApres} FCFA`);
      console.log(`      Date: ${new Date(tx.dateTransaction).toLocaleString()}`);
      console.log('');
    });
    
    return transactions;
  } catch (error) {
    console.error('❌ Erreur récupération transactions:', error.response?.data || error.message);
    throw error;
  }
}

async function runTest() {
  try {
    console.log('═══════════════════════════════════════════════════════');
    console.log('   TEST: PAIEMENT COMPTANT APPROVISIONNEMENT');
    console.log('═══════════════════════════════════════════════════════\n');
    
    // 1. Connexion
    await login();
    
    // 2. Créer un fournisseur
    const supplier = await createSupplier();
    
    // 3. Récupérer des produits
    const products = await getProducts();
    
    if (products.length === 0) {
      console.error('❌ Aucun produit disponible pour le test');
      return;
    }
    
    // 4. Créer une commande
    const order = await createProcurementOrder(supplier.id, products);
    
    // 5. Réceptionner avec mode COMPTANT
    await receiveOrder(order.id, order.details, 'comptant');
    
    // 6. Vérifier le compte fournisseur
    const account = await getSupplierAccount(supplier.id);
    
    // 7. Vérifier les transactions
    const transactions = await getSupplierTransactions(supplier.id);
    
    // 8. Analyse des résultats
    console.log('\n═══════════════════════════════════════════════════════');
    console.log('   ANALYSE DES RÉSULTATS');
    console.log('═══════════════════════════════════════════════════════\n');
    
    console.log('📊 Résumé:');
    console.log(`   - Montant commande: ${order.montantTotal} FCFA`);
    console.log(`   - Mode paiement: COMPTANT`);
    console.log(`   - Nombre de transactions: ${transactions.length}`);
    console.log(`   - Solde final: ${account.soldeActuel} FCFA\n`);
    
    // Vérifications
    let success = true;
    
    if (transactions.length !== 2) {
      console.log('❌ ÉCHEC: Devrait avoir 2 transactions (achat + paiement)');
      console.log(`   Trouvé: ${transactions.length} transaction(s)`);
      success = false;
    } else {
      console.log('✅ OK: 2 transactions trouvées');
    }
    
    const hasAchat = transactions.some(tx => tx.typeTransaction === 'achat');
    const hasPaiement = transactions.some(tx => tx.typeTransaction === 'paiement');
    
    if (!hasAchat) {
      console.log('❌ ÉCHEC: Transaction d\'achat manquante');
      success = false;
    } else {
      console.log('✅ OK: Transaction d\'achat présente');
    }
    
    if (!hasPaiement) {
      console.log('❌ ÉCHEC: Transaction de paiement manquante');
      success = false;
    } else {
      console.log('✅ OK: Transaction de paiement présente');
    }
    
    if (account.soldeActuel !== 0) {
      console.log(`❌ ÉCHEC: Solde devrait être 0 FCFA (trouvé: ${account.soldeActuel} FCFA)`);
      success = false;
    } else {
      console.log('✅ OK: Solde = 0 FCFA');
    }
    
    console.log('\n═══════════════════════════════════════════════════════');
    if (success) {
      console.log('   ✅ TEST RÉUSSI');
    } else {
      console.log('   ❌ TEST ÉCHOUÉ');
    }
    console.log('═══════════════════════════════════════════════════════\n');
    
  } catch (error) {
    console.error('\n❌ Erreur durant le test:', error.message);
    process.exit(1);
  }
}

// Exécuter le test
runTest();
