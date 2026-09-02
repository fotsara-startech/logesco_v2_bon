/**
 * Test simple de paiement fournisseur SANS mouvement financier
 */

const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

const TEST_USER = {
  nomUtilisateur: 'admin',
  motDePasse: 'admin123'
};

let authToken = '';

async function authenticate() {
  const response = await axios.post(`${API_URL}/auth/login`, TEST_USER);
  authToken = response.data.data.accessToken;
  console.log('✅ Authentifié');
}

async function testPayment() {
  try {
    await authenticate();
    
    // Récupérer un fournisseur
    const suppliersRes = await axios.get(`${API_URL}/suppliers?limit=1`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const supplier = suppliersRes.data.data[0];
    console.log(`\n📦 Fournisseur: ${supplier.nom} (ID: ${supplier.id})`);
    
    // Récupérer les commandes impayées
    const procurementsRes = await axios.get(
      `${API_URL}/accounts/suppliers/${supplier.id}/unpaid-procurements`,
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );
    
    if (procurementsRes.data.data && procurementsRes.data.data.length > 0) {
      const procurement = procurementsRes.data.data[0];
      console.log(`\n📋 Commande: ${procurement.reference}`);
      console.log(`   Montant total: ${procurement.montantTotal} FCFA`);
      console.log(`   Reste à payer: ${procurement.montantTotal - (procurement.montantPaye || 0)} FCFA`);
      
      // Test 1: Paiement SANS mouvement financier
      console.log('\n🧪 TEST 1: Paiement SANS mouvement financier');
      try {
        const response1 = await axios.post(
          `${API_URL}/accounts/suppliers/${supplier.id}/transactions`,
          {
            montant: 1000,
            typeTransaction: 'paiement',
            referenceType: 'approvisionnement',
            referenceId: procurement.id,
            description: 'Test paiement sans mouvement',
            createFinancialMovement: false
          },
          {
            headers: { Authorization: `Bearer ${authToken}` }
          }
        );
        
        console.log('✅ Paiement réussi SANS mouvement financier');
        console.log('   Réponse:', JSON.stringify(response1.data, null, 2));
      } catch (error) {
        console.error('❌ Échec:', error.response?.data || error.message);
      }
      
      // Test 2: Paiement AVEC mouvement financier
      console.log('\n🧪 TEST 2: Paiement AVEC mouvement financier');
      try {
        const response2 = await axios.post(
          `${API_URL}/accounts/suppliers/${supplier.id}/transactions`,
          {
            montant: 1000,
            typeTransaction: 'paiement',
            referenceType: 'approvisionnement',
            referenceId: procurement.id,
            description: 'Test paiement avec mouvement',
            createFinancialMovement: true
          },
          {
            headers: { Authorization: `Bearer ${authToken}` }
          }
        );
        
        console.log('✅ Paiement réussi AVEC mouvement financier');
        console.log('   Réponse:', JSON.stringify(response2.data, null, 2));
      } catch (error) {
        console.error('❌ Échec:', error.response?.data || error.message);
      }
    } else {
      console.log('⚠️ Aucune commande impayée');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

testPayment();
