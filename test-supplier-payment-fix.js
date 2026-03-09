/**
 * Test de la correction du paiement fournisseur avec mouvement financier
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/api/v1';

// Identifiants admin
const ADMIN_CREDENTIALS = {
  nomUtilisateur: 'admin',
  motDePasse: 'Admin@2024'
};

let authToken = '';

async function login() {
  try {
    console.log('🔐 Connexion en tant qu\'admin...');
    const response = await axios.post(`${API_URL}/auth/login`, ADMIN_CREDENTIALS);
    authToken = response.data.data.token;
    console.log('✅ Connexion réussie\n');
    return true;
  } catch (error) {
    console.error('❌ Erreur de connexion:', error.response?.data || error.message);
    return false;
  }
}

async function getSuppliers() {
  try {
    console.log('📋 Récupération des fournisseurs...');
    const response = await axios.get(`${API_URL}/suppliers`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const suppliers = response.data.data;
    console.log(`✅ ${suppliers.length} fournisseurs trouvés`);
    
    if (suppliers.length > 0) {
      console.log(`   Premier fournisseur: ${suppliers[0].nom} (ID: ${suppliers[0].id})\n`);
      return suppliers[0];
    }
    return null;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return null;
  }
}

async function getUnpaidProcurements(supplierId) {
  try {
    console.log(`📦 Récupération des commandes impayées du fournisseur ${supplierId}...`);
    const response = await axios.get(`${API_URL}/procurement/unpaid/${supplierId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const procurements = response.data.data;
    console.log(`✅ ${procurements.length} commandes impayées trouvées`);
    
    if (procurements.length > 0) {
      const proc = procurements[0];
      console.log(`   Commande: ${proc.reference}`);
      console.log(`   Montant restant: ${proc.montantRestant} FCFA\n`);
      return proc;
    }
    return null;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return null;
  }
}

async function paySupplier(supplierId, procurementId, amount) {
  try {
    console.log(`💰 Paiement de ${amount} FCFA pour la commande ${procurementId}...`);
    console.log(`   Avec création de mouvement financier: OUI\n`);
    
    const response = await axios.post(
      `${API_URL}/accounts/suppliers/${supplierId}/transactions`,
      {
        montant: amount,
        typeTransaction: 'paiement',
        description: `Test paiement commande #${procurementId}`,
        referenceType: 'approvisionnement',
        referenceId: procurementId,
        createFinancialMovement: true
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    console.log('✅ Paiement effectué avec succès');
    console.log('📊 Réponse:', JSON.stringify(response.data.data, null, 2));
    
    if (response.data.data.mouvementFinancier) {
      console.log('\n✅ Mouvement financier créé:');
      console.log(`   ID: ${response.data.data.mouvementFinancier.id}`);
      console.log(`   Montant: ${response.data.data.mouvementFinancier.montant} FCFA`);
      console.log(`   Description: ${response.data.data.mouvementFinancier.description}\n`);
      return response.data.data.mouvementFinancier.id;
    } else {
      console.log('\n⚠️ Aucun mouvement financier dans la réponse\n');
      return null;
    }
  } catch (error) {
    console.error('❌ Erreur lors du paiement:', error.response?.data || error.message);
    return null;
  }
}

async function getFinancialMovements() {
  try {
    console.log('📊 Récupération des mouvements financiers...');
    const response = await axios.get(`${API_URL}/financial-movements?limit=10`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const movements = response.data.data;
    console.log(`✅ ${movements.length} mouvements trouvés`);
    
    if (movements.length > 0) {
      console.log('\n📋 Derniers mouvements:');
      movements.slice(0, 5).forEach(m => {
        console.log(`   - ${m.reference}: ${m.montant} FCFA - ${m.description}`);
        console.log(`     Catégorie: ${m.categorie?.displayName || 'N/A'}`);
      });
    }
    
    return movements;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return [];
  }
}

async function verifyMovementExists(movementId) {
  try {
    console.log(`\n🔍 Vérification du mouvement ${movementId}...`);
    const response = await axios.get(`${API_URL}/financial-movements/${movementId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const movement = response.data.data;
    console.log('✅ Mouvement trouvé:');
    console.log(`   Référence: ${movement.reference}`);
    console.log(`   Montant: ${movement.montant} FCFA`);
    console.log(`   Description: ${movement.description}`);
    console.log(`   Catégorie: ${movement.categorie?.displayName || 'N/A'}`);
    console.log(`   Date: ${movement.date}`);
    
    return true;
  } catch (error) {
    console.error('❌ Mouvement non trouvé:', error.response?.data || error.message);
    return false;
  }
}

async function main() {
  console.log('='.repeat(60));
  console.log('TEST DE CORRECTION: Paiement Fournisseur + Mouvement Financier');
  console.log('='.repeat(60) + '\n');

  // 1. Connexion
  if (!await login()) {
    console.log('❌ Impossible de continuer sans connexion');
    return;
  }

  // 2. Récupérer un fournisseur
  const supplier = await getSuppliers();
  if (!supplier) {
    console.log('❌ Aucun fournisseur disponible');
    return;
  }

  // 3. Récupérer une commande impayée
  const procurement = await getUnpaidProcurements(supplier.id);
  if (!procurement) {
    console.log('⚠️ Aucune commande impayée pour ce fournisseur');
    console.log('   Le test ne peut pas continuer sans commande impayée\n');
    return;
  }

  // 4. Effectuer un paiement partiel avec mouvement financier
  const paymentAmount = Math.min(1000, procurement.montantRestant);
  const movementId = await paySupplier(supplier.id, procurement.id, paymentAmount);

  if (!movementId) {
    console.log('❌ Le paiement n\'a pas créé de mouvement financier');
    return;
  }

  // 5. Vérifier que le mouvement existe
  await verifyMovementExists(movementId);

  // 6. Lister tous les mouvements pour confirmation
  await getFinancialMovements();

  console.log('\n' + '='.repeat(60));
  console.log('✅ TEST TERMINÉ AVEC SUCCÈS');
  console.log('='.repeat(60));
}

main().catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
