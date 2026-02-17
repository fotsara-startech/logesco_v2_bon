/**
 * Test de clôture de caisse avec logs détaillés
 * Ce script simule une session complète pour identifier le problème d'écart
 */

const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

async function testCashSessionClose() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('🧪 TEST CLÔTURE DE CAISSE AVEC LOGS DÉTAILLÉS');
  console.log('═══════════════════════════════════════════════════════════\n');

  try {
    // 1. Vérifier s'il y a une session active
    console.log('📌 ÉTAPE 1: Vérification session active...');
    let activeSession;
    try {
      const activeResponse = await axios.get(`${API_URL}/cash-sessions/active`);
      activeSession = activeResponse.data.data;
      console.log(`✅ Session active trouvée: ID ${activeSession.id}`);
      console.log(`   Caisse: ${activeSession.nomCaisse}`);
      console.log(`   Solde ouverture: ${activeSession.soldeOuverture} FCFA`);
      console.log(`   Solde attendu: ${activeSession.soldeAttendu} FCFA`);
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('⚠️ Aucune session active - Création d\'une nouvelle session...\n');
        
        // Récupérer les caisses disponibles
        const cashRegistersResponse = await axios.get(`${API_URL}/cash-sessions/available-cash-registers`);
        const availableCashRegisters = cashRegistersResponse.data.data;
        
        if (availableCashRegisters.length === 0) {
          console.log('❌ Aucune caisse disponible');
          return;
        }
        
        const cashRegister = availableCashRegisters[0];
        console.log(`📌 Caisse sélectionnée: ${cashRegister.nom}`);
        
        // Ouvrir une session avec 50000 FCFA
        const soldeInitial = 50000;
        console.log(`📌 Ouverture session avec ${soldeInitial} FCFA...\n`);
        
        const connectResponse = await axios.post(`${API_URL}/cash-sessions/connect`, {
          cashRegisterId: cashRegister.id,
          soldeInitial: soldeInitial
        });
        
        activeSession = connectResponse.data.data;
        console.log(`✅ Session créée: ID ${activeSession.id}`);
        console.log(`   Solde ouverture: ${activeSession.soldeOuverture} FCFA`);
        console.log(`   Solde attendu: ${activeSession.soldeAttendu} FCFA\n`);
      } else {
        throw error;
      }
    }

    // 2. Simuler quelques ventes pour modifier le soldeAttendu
    console.log('📌 ÉTAPE 2: Simulation de ventes...');
    const ventes = [
      { montant: 15000, description: 'Vente 1' },
      { montant: 8000, description: 'Vente 2' },
      { montant: 12000, description: 'Vente 3' }
    ];

    let soldeAttenduCalcule = activeSession.soldeAttendu;
    
    for (const vente of ventes) {
      console.log(`   💰 ${vente.description}: +${vente.montant} FCFA`);
      soldeAttenduCalcule += vente.montant;
    }
    
    console.log(`   ✅ Solde attendu après ventes: ${soldeAttenduCalcule} FCFA`);
    console.log(`   (Note: Les ventes réelles mettront à jour le soldeAttendu dans la base)\n`);

    // 3. Récupérer la session mise à jour
    console.log('📌 ÉTAPE 3: Vérification du solde attendu actuel...');
    const updatedSessionResponse = await axios.get(`${API_URL}/cash-sessions/active`);
    const updatedSession = updatedSessionResponse.data.data;
    
    console.log(`   Solde ouverture: ${updatedSession.soldeOuverture} FCFA`);
    console.log(`   Solde attendu (DB): ${updatedSession.soldeAttendu} FCFA`);
    console.log(`   Solde attendu (calculé): ${soldeAttenduCalcule} FCFA\n`);

    // 4. Tester différents scénarios de clôture
    console.log('📌 ÉTAPE 4: Test de clôture avec ÉCART...\n');
    
    const scenarios = [
      {
        nom: 'Scénario 1: Solde exact (écart = 0)',
        soldeFermeture: updatedSession.soldeAttendu,
        ecartAttendu: 0
      },
      {
        nom: 'Scénario 2: Manque 5000 FCFA (écart = -5000)',
        soldeFermeture: updatedSession.soldeAttendu - 5000,
        ecartAttendu: -5000
      },
      {
        nom: 'Scénario 3: Surplus 3000 FCFA (écart = +3000)',
        soldeFermeture: updatedSession.soldeAttendu + 3000,
        ecartAttendu: 3000
      }
    ];

    // Choisir un scénario (par défaut le scénario 2 pour tester un écart négatif)
    const scenarioChoisi = scenarios[1];
    
    console.log(`🎯 ${scenarioChoisi.nom}`);
    console.log(`   Solde attendu: ${updatedSession.soldeAttendu} FCFA`);
    console.log(`   Solde déclaré: ${scenarioChoisi.soldeFermeture} FCFA`);
    console.log(`   Écart attendu: ${scenarioChoisi.ecartAttendu} FCFA\n`);

    // 5. Effectuer la clôture
    console.log('📌 ÉTAPE 5: Clôture de la session...\n');
    console.log('⏳ Envoi de la requête de clôture...');
    console.log('⏳ Les logs détaillés du backend vont s\'afficher ci-dessous:\n');
    console.log('─────────────────────────────────────────────────────────');
    
    const closeResponse = await axios.post(`${API_URL}/cash-sessions/disconnect`, {
      soldeFermeture: scenarioChoisi.soldeFermeture
    });
    
    console.log('─────────────────────────────────────────────────────────\n');
    
    const closedSession = closeResponse.data.data;
    
    console.log('📊 RÉSULTAT DE LA CLÔTURE:');
    console.log(`   Session ID: ${closedSession.id}`);
    console.log(`   Solde ouverture: ${closedSession.soldeOuverture} FCFA`);
    console.log(`   Solde attendu: ${closedSession.soldeAttendu} FCFA`);
    console.log(`   Solde déclaré: ${closedSession.soldeFermeture} FCFA`);
    console.log(`   Écart enregistré: ${closedSession.ecart} FCFA`);
    console.log(`   Écart attendu: ${scenarioChoisi.ecartAttendu} FCFA\n`);

    // 6. Vérification
    console.log('📌 ÉTAPE 6: Vérification...');
    if (closedSession.ecart === scenarioChoisi.ecartAttendu) {
      console.log('✅ SUCCÈS: L\'écart est correct!');
    } else {
      console.log('❌ PROBLÈME DÉTECTÉ:');
      console.log(`   Écart attendu: ${scenarioChoisi.ecartAttendu} FCFA`);
      console.log(`   Écart enregistré: ${closedSession.ecart} FCFA`);
      console.log(`   Différence: ${closedSession.ecart - scenarioChoisi.ecartAttendu} FCFA`);
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('✅ TEST TERMINÉ');
    console.log('═══════════════════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌ ERREUR DURANT LE TEST:');
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Message: ${error.response.data?.error?.message || error.response.data?.message}`);
      console.error(`   Data:`, JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(`   ${error.message}`);
    }
  }
}

// Exécuter le test
testCashSessionClose();
