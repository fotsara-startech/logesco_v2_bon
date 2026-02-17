/**
 * Test complet du flux de caisse avec ventes
 * Ce script teste l'ensemble du processus: ouverture, ventes, clôture
 */

const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

async function testCompleteCashFlow() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('🧪 TEST COMPLET DU FLUX DE CAISSE');
  console.log('═══════════════════════════════════════════════════════════\n');

  try {
    // 1. Ouvrir une session
    console.log('📌 ÉTAPE 1: Ouverture de session...');
    const cashRegistersResponse = await axios.get(`${API_URL}/cash-sessions/available-cash-registers`);
    const availableCashRegisters = cashRegistersResponse.data.data;
    
    if (availableCashRegisters.length === 0) {
      console.log('❌ Aucune caisse disponible');
      return;
    }
    
    const cashRegister = availableCashRegisters[0];
    const soldeInitial = 100000;
    
    const connectResponse = await axios.post(`${API_URL}/cash-sessions/connect`, {
      cashRegisterId: cashRegister.id,
      soldeInitial: soldeInitial
    });
    
    const session = connectResponse.data.data;
    console.log(`✅ Session ouverte: ID ${session.id}`);
    console.log(`   Caisse: ${session.nomCaisse}`);
    console.log(`   Solde initial: ${session.soldeOuverture} FCFA`);
    console.log(`   Solde attendu: ${session.soldeAttendu} FCFA\n`);

    // 2. Récupérer un produit pour faire une vente
    console.log('📌 ÉTAPE 2: Récupération d\'un produit...');
    const productsResponse = await axios.get(`${API_URL}/products?limit=1`);
    const products = productsResponse.data.data;
    
    if (products.length === 0) {
      console.log('❌ Aucun produit disponible');
      return;
    }
    
    const product = products[0];
    console.log(`✅ Produit sélectionné: ${product.nom}`);
    console.log(`   Prix: ${product.prixUnitaire} FCFA\n`);

    // 3. Créer des ventes
    console.log('📌 ÉTAPE 3: Création de ventes...');
    const ventes = [
      { quantite: 2, montantPaye: 20000 },
      { quantite: 1, montantPaye: 15000 },
      { quantite: 3, montantPaye: 35000 }
    ];

    let totalVentes = 0;
    for (let i = 0; i < ventes.length; i++) {
      const vente = ventes[i];
      const montantVente = vente.quantite * product.prixUnitaire;
      
      const saleData = {
        modePaiement: 'comptant',
        montantRemise: 0,
        montantPaye: vente.montantPaye,
        details: [
          {
            produitId: product.id,
            quantite: vente.quantite,
            prixUnitaire: product.prixUnitaire,
            prixAffiche: product.prixUnitaire,
            remiseAppliquee: 0
          }
        ]
      };

      try {
        const saleResponse = await axios.post(`${API_URL}/sales`, saleData);
        console.log(`   ✅ Vente ${i + 1}: ${vente.montantPaye} FCFA payés`);
        totalVentes += vente.montantPaye;
      } catch (error) {
        console.log(`   ⚠️ Vente ${i + 1} échouée: ${error.response?.data?.message || error.message}`);
      }
    }
    
    console.log(`   💰 Total encaissé: ${totalVentes} FCFA\n`);

    // 4. Vérifier le solde attendu après les ventes
    console.log('📌 ÉTAPE 4: Vérification du solde attendu...');
    const updatedSessionResponse = await axios.get(`${API_URL}/cash-sessions/active`);
    const updatedSession = updatedSessionResponse.data.data;
    
    const soldeAttenduCalcule = soldeInitial + totalVentes;
    
    console.log(`   Solde initial: ${soldeInitial} FCFA`);
    console.log(`   Total ventes: +${totalVentes} FCFA`);
    console.log(`   Solde attendu (calculé): ${soldeAttenduCalcule} FCFA`);
    console.log(`   Solde attendu (DB): ${updatedSession.soldeAttendu} FCFA`);
    
    if (updatedSession.soldeAttendu === soldeAttenduCalcule) {
      console.log(`   ✅ Le solde attendu est correct!\n`);
    } else {
      console.log(`   ❌ PROBLÈME: Le solde attendu ne correspond pas!`);
      console.log(`      Différence: ${updatedSession.soldeAttendu - soldeAttenduCalcule} FCFA\n`);
    }

    // 5. Clôturer avec un écart
    console.log('📌 ÉTAPE 5: Clôture avec écart...');
    const manque = 10000;
    const soldeFermeture = updatedSession.soldeAttendu - manque;
    
    console.log(`   Solde attendu: ${updatedSession.soldeAttendu} FCFA`);
    console.log(`   Solde déclaré: ${soldeFermeture} FCFA`);
    console.log(`   Écart attendu: -${manque} FCFA\n`);
    
    console.log('⏳ Clôture en cours...\n');
    console.log('─────────────────────────────────────────────────────────');
    
    const closeResponse = await axios.post(`${API_URL}/cash-sessions/disconnect`, {
      soldeFermeture: soldeFermeture
    });
    
    console.log('─────────────────────────────────────────────────────────\n');
    
    const closedSession = closeResponse.data.data;
    
    console.log('📊 RÉSULTAT FINAL:');
    console.log(`   Session ID: ${closedSession.id}`);
    console.log(`   Solde ouverture: ${closedSession.soldeOuverture} FCFA`);
    console.log(`   Solde attendu: ${closedSession.soldeAttendu} FCFA`);
    console.log(`   Solde déclaré: ${closedSession.soldeFermeture} FCFA`);
    console.log(`   Écart: ${closedSession.ecart} FCFA`);
    
    if (closedSession.ecart === -manque) {
      console.log(`   ✅ L'écart est correct!\n`);
    } else {
      console.log(`   ❌ PROBLÈME: L'écart ne correspond pas!`);
      console.log(`      Attendu: -${manque} FCFA`);
      console.log(`      Obtenu: ${closedSession.ecart} FCFA\n`);
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('✅ TEST TERMINÉ');
    console.log('═══════════════════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌ ERREUR DURANT LE TEST:');
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Message: ${error.response.data?.error?.message || error.response.data?.message}`);
      if (error.response.data) {
        console.error(`   Data:`, JSON.stringify(error.response.data, null, 2));
      }
    } else {
      console.error(`   ${error.message}`);
    }
  }
}

// Exécuter le test
testCompleteCashFlow();
