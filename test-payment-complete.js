const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

async function test() {
  try {
    // 1. Login
    console.log('🔐 Connexion...');
    const loginRes = await axios.post(`${API_URL}/auth/login`, {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });
    
    const token = loginRes.data.data.token;
    console.log('✅ Connecté\n');

    // 2. Récupérer les fournisseurs
    console.log('📋 Récupération des fournisseurs...');
    const suppliersRes = await axios.get(`${API_URL}/suppliers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const supplier = suppliersRes.data.data[0];
    console.log(`✅ Fournisseur: ${supplier.nom} (ID: ${supplier.id})\n`);

    // 3. Récupérer les commandes impayées
    console.log('📦 Récupération des commandes impayées...');
    const procurementsRes = await axios.get(`${API_URL}/accounts/suppliers/${supplier.id}/unpaid-procurements`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (procurementsRes.data.data.length === 0) {
      console.log('⚠️ Aucune commande impayée pour ce fournisseur\n');
      return;
    }
    
    const procurement = procurementsRes.data.data[0];
    console.log(`✅ Commande: ${procurement.reference}`);
    console.log(`   Montant restant: ${procurement.montantRestant} FCFA\n`);

    // 4. Effectuer le paiement avec mouvement financier
    console.log('💰 Paiement avec création de mouvement financier...');
    const paymentAmount = Math.min(1000, procurement.montantRestant);
    
    const paymentRes = await axios.post(
      `${API_URL}/accounts/suppliers/${supplier.id}/transactions`,
      {
        montant: paymentAmount,
        typeTransaction: 'paiement',
        description: `Test paiement commande ${procurement.reference}`,
        referenceType: 'approvisionnement',
        referenceId: procurement.id,
        createFinancialMovement: true
      },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );
    
    console.log('✅ Paiement effectué');
    console.log('📊 Réponse:', JSON.stringify(paymentRes.data.data, null, 2));
    
    if (paymentRes.data.data.mouvementFinancier) {
      const mvt = paymentRes.data.data.mouvementFinancier;
      console.log('\n✅ Mouvement financier créé:');
      console.log(`   ID: ${mvt.id}`);
      console.log(`   Montant: ${mvt.montant} FCFA`);
      console.log(`   Description: ${mvt.description}\n`);
      
      // 5. Vérifier que le mouvement existe dans la liste
      console.log('🔍 Vérification dans la liste des mouvements...');
      const movementsRes = await axios.get(`${API_URL}/financial-movements?limit=10`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      const movements = movementsRes.data.data;
      const found = movements.find(m => m.id === mvt.id);
      
      if (found) {
        console.log('✅ Mouvement trouvé dans la liste!');
        console.log(`   Référence: ${found.reference}`);
        console.log(`   Catégorie: ${found.categorie?.displayName || 'N/A'}`);
        console.log(`   Date: ${found.date}\n`);
      } else {
        console.log('❌ Mouvement NON trouvé dans la liste!\n');
      }
      
      // 6. Récupérer le mouvement par ID
      console.log('🔍 Récupération du mouvement par ID...');
      const mvtRes = await axios.get(`${API_URL}/financial-movements/${mvt.id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      console.log('✅ Mouvement récupéré par ID:');
      console.log(JSON.stringify(mvtRes.data.data, null, 2));
      
    } else {
      console.log('\n❌ Aucun mouvement financier dans la réponse!\n');
    }

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    if (error.response?.data) {
      console.error('Détails:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

test();
