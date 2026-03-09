/**
 * Test de vérification du mouvement financier après paiement fournisseur
 * 
 * Ce test vérifie que:
 * 1. Le paiement d'une commande fournisseur crée bien un mouvement financier
 * 2. Le mouvement financier apparaît dans la liste des mouvements
 * 3. Les données du mouvement sont correctes
 */

const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

// Identifiants de test
const TEST_USER = {
  nomUtilisateur: 'admin',
  motDePasse: 'admin123'
};

let authToken = '';

/**
 * Authentification
 */
async function authenticate() {
  try {
    console.log('🔐 Authentification...');
    console.log('   URL:', `${API_URL}/auth/login`);
    console.log('   Identifiants:', TEST_USER);
    
    const response = await axios.post(`${API_URL}/auth/login`, TEST_USER);
    
    console.log('   Réponse:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success && response.data.data.accessToken) {
      authToken = response.data.data.accessToken;
      console.log('✅ Authentification réussie');
      return true;
    }
    
    console.error('❌ Échec de l\'authentification');
    return false;
  } catch (error) {
    console.error('❌ Erreur d\'authentification:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Ouvre une session de caisse ou récupère la session active
 */
async function openCashSession() {
  try {
    console.log('\n💰 Vérification de la session de caisse...');
    
    // Vérifier s'il y a déjà une session active
    try {
      const activeSessionRes = await axios.get(`${API_URL}/cash-sessions/active`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      if (activeSessionRes.data.success && activeSessionRes.data.data) {
        console.log('✅ Session de caisse active trouvée:', activeSessionRes.data.data.id);
        console.log(`   Solde actuel: ${activeSessionRes.data.data.soldeActuel} FCFA`);
        return activeSessionRes.data.data;
      }
    } catch (error) {
      console.log('ℹ️ Aucune session active, création d\'une nouvelle session...');
    }
    
    // Récupérer les caisses disponibles
    const caissesRes = await axios.get(`${API_URL}/cash-registers`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (!caissesRes.data.data || caissesRes.data.data.length === 0) {
      console.error('❌ Aucune caisse disponible');
      return null;
    }
    
    const caisse = caissesRes.data.data[0];
    console.log(`📦 Caisse trouvée: ${caisse.nom} (ID: ${caisse.id})`);
    
    // Ouvrir une session
    const sessionRes = await axios.post(
      `${API_URL}/cash-sessions`,
      {
        caisseId: caisse.id,
        soldeInitial: 100000 // 100,000 FCFA
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    if (sessionRes.data.success) {
      console.log('✅ Session de caisse ouverte:', sessionRes.data.data.id);
      return sessionRes.data.data;
    }
    
    return null;
  } catch (error) {
    console.error('❌ Erreur ouverture session:', error.response?.data || error.message);
    return null;
  }
}

/**
 * Récupère une commande fournisseur impayée
 */
async function getUnpaidProcurement() {
  try {
    console.log('\n📦 Recherche d\'une commande fournisseur impayée...');
    
    // D'abord, récupérer un fournisseur
    const suppliersRes = await axios.get(`${API_URL}/suppliers?limit=10`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (!suppliersRes.data.data || suppliersRes.data.data.length === 0) {
      console.log('⚠️ Aucun fournisseur trouvé');
      return null;
    }
    
    // Chercher un fournisseur avec des commandes impayées
    for (const supplier of suppliersRes.data.data) {
      try {
        const procurementsRes = await axios.get(
          `${API_URL}/accounts/suppliers/${supplier.id}/unpaid-procurements`,
          {
            headers: { Authorization: `Bearer ${authToken}` }
          }
        );
        
        if (procurementsRes.data.data && procurementsRes.data.data.length > 0) {
          const procurement = procurementsRes.data.data[0];
          console.log(`✅ Commande trouvée: ${procurement.reference}`);
          console.log(`   - Fournisseur: ${supplier.nom} (ID: ${supplier.id})`);
          console.log(`   - Montant total: ${procurement.montantTotal} FCFA`);
          console.log(`   - Montant payé: ${procurement.montantPaye || 0} FCFA`);
          console.log(`   - Reste à payer: ${procurement.montantTotal - (procurement.montantPaye || 0)} FCFA`);
          return { ...procurement, fournisseurId: supplier.id };
        }
      } catch (error) {
        // Continuer avec le prochain fournisseur
        continue;
      }
    }
    
    console.log('⚠️ Aucune commande impayée trouvée');
    return null;
  } catch (error) {
    console.error('❌ Erreur récupération commande:', error.response?.data || error.message);
    return null;
  }
}

/**
 * Compte les mouvements financiers actuels
 */
async function countFinancialMovements() {
  try {
    const response = await axios.get(`${API_URL}/financial-movements?limit=100`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const count = response.data.data?.length || 0;
    console.log(`📊 Nombre de mouvements financiers: ${count}`);
    return count;
  } catch (error) {
    console.error('❌ Erreur comptage mouvements:', error.response?.data || error.message);
    return 0;
  }
}

/**
 * Paie une commande fournisseur avec création de mouvement financier
 */
async function payProcurement(supplierId, procurementId, amount) {
  try {
    console.log(`\n💸 Paiement de la commande ${procurementId}...`);
    console.log(`   - Fournisseur: ${supplierId}`);
    console.log(`   - Montant: ${amount} FCFA`);
    console.log(`   - Créer mouvement financier: OUI`);
    
    const payload = {
      montant: amount,
      typeTransaction: 'paiement',
      referenceType: 'approvisionnement',
      referenceId: procurementId,
      description: `Paiement Commande #CMD${procurementId}`,
      createFinancialMovement: true
    };
    
    console.log('   - Payload:', JSON.stringify(payload, null, 2));
    
    const response = await axios.post(
      `${API_URL}/accounts/suppliers/${supplierId}/transactions`,
      payload,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('   - Réponse:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      console.log('✅ Paiement enregistré avec succès');
      
      const mouvementFinancier = response.data.data.mouvementFinancier;
      if (mouvementFinancier) {
        console.log('✅ Mouvement financier créé:');
        console.log(`   - ID: ${mouvementFinancier.id}`);
        console.log(`   - Montant: ${mouvementFinancier.montant} FCFA`);
        console.log(`   - Description: ${mouvementFinancier.description}`);
        return mouvementFinancier.id;
      } else {
        console.log('⚠️ Aucun mouvement financier retourné dans la réponse');
        return null;
      }
    }
    
    return null;
  } catch (error) {
    console.error('❌ Erreur paiement:', error.response?.data || error.message);
    if (error.response?.data?.error) {
      console.error('   Détails:', error.response.data.error);
    }
    return null;
  }
}

/**
 * Vérifie qu'un mouvement financier existe dans la liste
 */
async function verifyMovementInList(movementId) {
  try {
    console.log(`\n🔍 Vérification du mouvement ${movementId} dans la liste...`);
    
    // Attendre un peu pour laisser le temps au cache de se mettre à jour
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const response = await axios.get(`${API_URL}/financial-movements?limit=50`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const movements = response.data.data || [];
    const found = movements.find(m => m.id === movementId);
    
    if (found) {
      console.log('✅ Mouvement trouvé dans la liste:');
      console.log(`   - ID: ${found.id}`);
      console.log(`   - Montant: ${found.montant} FCFA`);
      console.log(`   - Description: ${found.description}`);
      console.log(`   - Catégorie: ${found.categorie?.displayName || 'N/A'}`);
      console.log(`   - Date: ${found.dateCreation}`);
      return true;
    } else {
      console.log('❌ Mouvement NON trouvé dans la liste');
      console.log(`   Mouvements disponibles (${movements.length}):`);
      movements.slice(0, 5).forEach(m => {
        console.log(`   - ID ${m.id}: ${m.description} (${m.montant} FCFA)`);
      });
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur vérification:', error.response?.data || error.message);
    return false;
  }
}

/**
 * Test principal
 */
async function runTest() {
  console.log('🧪 TEST: Vérification du mouvement financier après paiement fournisseur\n');
  console.log('='.repeat(80));
  
  try {
    // 1. Authentification
    const authenticated = await authenticate();
    if (!authenticated) {
      console.error('\n❌ TEST ÉCHOUÉ: Impossible de s\'authentifier');
      return;
    }
    
    // 2. Ouvrir une session de caisse
    const session = await openCashSession();
    if (!session) {
      console.error('\n❌ TEST ÉCHOUÉ: Impossible d\'ouvrir une session de caisse');
      return;
    }
    
    // 3. Compter les mouvements avant
    console.log('\n📊 AVANT le paiement:');
    const countBefore = await countFinancialMovements();
    
    // 4. Récupérer une commande impayée
    const procurement = await getUnpaidProcurement();
    if (!procurement) {
      console.error('\n❌ TEST ÉCHOUÉ: Aucune commande impayée disponible');
      return;
    }
    
    // 5. Effectuer le paiement
    const montantAPayer = 5000; // Montant fixe pour le test
    const movementId = await payProcurement(
      procurement.fournisseurId,
      procurement.id,
      montantAPayer
    );
    
    if (!movementId) {
      console.error('\n❌ TEST ÉCHOUÉ: Aucun mouvement financier créé');
      return;
    }
    
    // 6. Compter les mouvements après
    console.log('\n📊 APRÈS le paiement:');
    const countAfter = await countFinancialMovements();
    
    if (countAfter > countBefore) {
      console.log(`✅ Nombre de mouvements augmenté: ${countBefore} → ${countAfter}`);
    } else {
      console.log(`⚠️ Nombre de mouvements inchangé: ${countBefore} → ${countAfter}`);
    }
    
    // 7. Vérifier que le mouvement apparaît dans la liste
    const foundInList = await verifyMovementInList(movementId);
    
    // Résultat final
    console.log('\n' + '='.repeat(80));
    if (foundInList) {
      console.log('✅ TEST RÉUSSI: Le mouvement financier est bien visible dans l\'interface');
    } else {
      console.log('❌ TEST ÉCHOUÉ: Le mouvement financier n\'apparaît pas dans l\'interface');
      console.log('\n💡 DIAGNOSTIC:');
      console.log('   - Le mouvement a été créé dans la base de données (ID: ' + movementId + ')');
      console.log('   - Mais il n\'apparaît pas dans la liste récupérée par l\'API');
      console.log('   - Cela peut indiquer un problème de cache ou de filtrage');
    }
    console.log('='.repeat(80));
    
  } catch (error) {
    console.error('\n❌ ERREUR DURANT LE TEST:', error.message);
  }
}

// Exécuter le test
runTest().catch(console.error);
