const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api/v1';

// Test de récupération des comptes clients pour debug des dettes
async function testCustomerDebts() {
  console.log('🔍 Test de récupération des comptes clients pour debug des dettes');
  console.log('='.repeat(60));

  try {
    // 1. Test de connexion au backend (sans auth d'abord)
    console.log('1. Test de connexion au backend...');
    try {
      const testResponse = await axios.get(`${BASE_URL}/products/all`);
      console.log('❌ Backend accessible mais sans auth:', testResponse.status);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Backend accessible (erreur 401 = auth requise)');
      } else {
        console.log('❌ Backend non accessible:', error.message);
        return;
      }
    }

    // 2. Récupération des comptes clients (avec token factice pour test)
    console.log('\n2. Récupération des comptes clients...');
    
    // Token factice pour test - en production il faut un vrai token
    const headers = {
      'Authorization': 'Bearer test-token',
      'Content-Type': 'application/json'
    };
    
    try {
      const response = await axios.get(`${BASE_URL}/accounts/customers?limit=100`, { headers });
      
      console.log('✅ Réponse API reçue');
      console.log('Status:', response.status);
      console.log('Nombre de comptes:', response.data.data?.length || 0);
      
      if (response.data.data && response.data.data.length > 0) {
        console.log('\n📊 Analyse des comptes clients:');
        
        let totalDettes = 0;
        let clientsDebiteurs = 0;
        
        response.data.data.forEach((compte, index) => {
          const solde = parseFloat(compte.soldeActuel || 0);
          const nom = compte.client?.nomComplet || compte.client?.nom || 'Client inconnu';
          
          console.log(`\n  Compte ${index + 1}:`);
          console.log(`    - Client: ${nom}`);
          console.log(`    - Solde actuel: ${solde} FCFA`);
          console.log(`    - Limite crédit: ${compte.limiteCredit} FCFA`);
          console.log(`    - Dernière MAJ: ${compte.dateDerniereMaj}`);
          
          // Un solde positif = dette du client
          if (solde > 0) {
            totalDettes += solde;
            clientsDebiteurs++;
            console.log(`    ⚠️  DETTE: ${solde} FCFA`);
          } else if (solde < 0) {
            console.log(`    ✅ CRÉDIT: ${Math.abs(solde)} FCFA`);
          } else {
            console.log(`    ➖ SOLDE NUL`);
          }
        });
        
        console.log('\n📈 RÉSUMÉ DES DETTES:');
        console.log(`  - Total des dettes: ${totalDettes.toFixed(0)} FCFA`);
        console.log(`  - Clients débiteurs: ${clientsDebiteurs}`);
        console.log(`  - Dette moyenne: ${clientsDebiteurs > 0 ? (totalDettes / clientsDebiteurs).toFixed(0) : 0} FCFA`);
        
        if (totalDettes === 0) {
          console.log('\n⚠️  PROBLÈME IDENTIFIÉ: Aucune dette trouvée !');
          console.log('   Causes possibles:');
          console.log('   1. Aucun compte client avec solde positif');
          console.log('   2. Données de test manquantes');
          console.log('   3. Problème de logique métier');
        }
        
      } else {
        console.log('⚠️  Aucun compte client trouvé');
        console.log('   Il faut créer des données de test avec des dettes clients');
      }
      
    } catch (error) {
      console.log('❌ Erreur lors de la récupération des comptes:', error.message);
      if (error.response) {
        console.log('   Status:', error.response.status);
        console.log('   Data:', error.response.data);
      }
    }

    // 3. Test de création d'un compte client avec dette (si nécessaire)
    console.log('\n3. Vérification des clients existants...');
    try {
      const clientsResponse = await axios.get(`${BASE_URL}/clients?limit=10`, { headers });
      console.log('✅ Clients disponibles:', clientsResponse.data.data?.length || 0);
      
      if (clientsResponse.data.data && clientsResponse.data.data.length > 0) {
        console.log('\n📋 Premiers clients:');
        clientsResponse.data.data.slice(0, 3).forEach((client, index) => {
          console.log(`  ${index + 1}. ${client.nom} ${client.prenom || ''} (ID: ${client.id})`);
        });
      }
    } catch (error) {
      console.log('❌ Erreur lors de la récupération des clients:', error.message);
    }

  } catch (error) {
    console.error('❌ Erreur générale:', error.message);
  }
}

// Fonction pour créer des données de test avec dettes
async function createTestDataWithDebts() {
  console.log('\n🔧 Création de données de test avec dettes...');
  
  try {
    // Récupérer un client existant
    const headers = {
      'Authorization': 'Bearer test-token',
      'Content-Type': 'application/json'
    };
    const clientsResponse = await axios.get(`${BASE_URL}/clients?limit=1`, { headers });
    
    if (!clientsResponse.data.data || clientsResponse.data.data.length === 0) {
      console.log('❌ Aucun client trouvé. Créez d\'abord des clients.');
      return;
    }
    
    const client = clientsResponse.data.data[0];
    console.log(`✅ Client trouvé: ${client.nom} (ID: ${client.id})`);
    
    // Créer une transaction qui génère une dette
    const transactionData = {
      montant: 50000, // 50,000 FCFA de dette
      typeTransaction: 'debit', // Débit = augmente le solde (dette)
      description: 'Achat à crédit - Test dette'
    };
    
    console.log('📝 Création d\'une transaction de dette...');
    const transactionResponse = await axios.post(
      `${BASE_URL}/accounts/customers/${client.id}/transactions`,
      transactionData,
      { headers }
    );
    
    console.log('✅ Transaction créée avec succès');
    console.log('   Nouveau solde:', transactionResponse.data.data?.soldeActuel || 'N/A');
    
  } catch (error) {
    console.log('❌ Erreur lors de la création des données de test:', error.message);
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', error.response.data);
    }
  }
}

// Exécution
async function main() {
  await testCustomerDebts();
  
  // Demander si on veut créer des données de test
  console.log('\n' + '='.repeat(60));
  console.log('💡 Pour créer des données de test avec dettes, décommentez la ligne suivante:');
  console.log('// await createTestDataWithDebts();');
  
  // Décommentez cette ligne pour créer des données de test
  // await createTestDataWithDebts();
}

main().catch(console.error);