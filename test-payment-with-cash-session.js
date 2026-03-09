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

    // 2. Vérifier/Ouvrir une session de caisse
    console.log('💼 Vérification de la session de caisse...');
    
    // Récupérer les caisses disponibles
    const caissesRes = await axios.get(`${API_URL}/cash-registers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (caissesRes.data.data.length === 0) {
      console.log('❌ Aucune caisse disponible\n');
      return;
    }
    
    const caisse = caissesRes.data.data[0];
    console.log(`✅ Caisse trouvée: ${caisse.nom} (ID: ${caisse.id})\n`);
    
    // Vérifier s'il y a une session active
    let sessionActive = null;
    try {
      const sessionRes = await axios.get(`${API_URL}/cash-sessions/active`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      sessionActive = sessionRes.data.data;
      console.log(`✅ Session active trouvée (ID: ${sessionActive.id}, Solde: ${sessionActive.soldeActuel} FCFA)\n`);
    } catch (error) {
      console.log('⚠️ Aucune session active, ouverture d\'une nouvelle session...');
      
      // Ouvrir une nouvelle session
      const openRes = await axios.post(
        `${API_URL}/cash-sessions/open`,
        {
          caisseId: caisse.id,
          soldeInitial: 100000 // 100,000 FCFA
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );
      
      sessionActive = openRes.data.data;
      console.log(`✅ Session ouverte (ID: ${sessionActive.id}, Solde: ${sessionActive.soldeActuel} FCFA)\n`);
    }

    // 3. Récupérer les fournisseurs
    console.log('📋 Récupération des fournisseurs...');
    const suppliersRes = await axios.get(`${API_URL}/suppliers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const supplier = suppliersRes.data.data[0];
    console.log(`✅ Fournisseur: ${supplier.nom} (ID: ${supplier.id})\n`);

    // 4. Récupérer les commandes impayées
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

    // 5. Effectuer le paiement avec mouvement financier
    console.log('💰 Paiement avec création de mouvement financier...');
    const paymentAmount = Math.min(5000, procurement.montantRestant);
    
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
    
    if (paymentRes.data.data.mouvementFinancier) {
      const mvt = paymentRes.data.data.mouvementFinancier;
      console.log('\n✅✅✅ MOUVEMENT FINANCIER CRÉÉ! ✅✅✅');
      console.log(`   ID: ${mvt.id}`);
      console.log(`   Montant: ${mvt.montant} FCFA`);
      console.log(`   Description: ${mvt.description}\n`);
      
      // 6. Vérifier dans la liste
      console.log('🔍 Vérification dans la liste des mouvements...');
      const movementsRes = await axios.get(`${API_URL}/financial-movements?limit=10`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      const movements = movementsRes.data.data;
      const found = movements.find(m => m.id === mvt.id);
      
      if (found) {
        console.log('✅✅✅ MOUVEMENT TROUVÉ DANS LA LISTE! ✅✅✅');
        console.log(`   Référence: ${found.reference}`);
        console.log(`   Catégorie: ${found.categorie?.displayName || 'N/A'}`);
        console.log(`   Montant: ${found.montant} FCFA`);
        console.log(`   Date: ${found.date}\n`);
        
        console.log('🎉🎉🎉 TEST RÉUSSI! 🎉🎉🎉');
      } else {
        console.log('❌ Mouvement NON trouvé dans la liste!\n');
      }
      
    } else {
      console.log('\n❌ Aucun mouvement financier dans la réponse!');
      console.log('Réponse complète:', JSON.stringify(paymentRes.data.data, null, 2));
    }

  } catch (error) {
    console.error('\n❌ ERREUR:', error.response?.data?.message || error.message);
    if (error.response?.data) {
      console.error('Détails:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

test();
