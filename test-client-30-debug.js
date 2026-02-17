const http = require('http');

async function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body: data });
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function debugClient30() {
  console.log('🔍 DIAGNOSTIC: Problème récupération transactions client ID #30');
  console.log('================================================================');
  
  try {
    // Étape 1: Connexion pour obtenir un token
    console.log('\n📋 Étape 1: Connexion pour obtenir un token...');
    
    const loginData = {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    };
    
    const loginOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const loginResponse = await makeRequest(loginOptions, JSON.stringify(loginData));
    
    if (loginResponse.statusCode !== 200) {
      console.log('❌ Échec de la connexion:', loginResponse.body);
      return;
    }
    
    const loginResult = JSON.parse(loginResponse.body);
    const token = loginResult.data?.accessToken;
    console.log('✅ Connexion réussie, token obtenu');
    
    // Étape 2: Vérifier si le client #30 existe
    console.log('\n📋 Étape 2: Vérification existence du client ID #30...');
    
    const clientOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/customers/30',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    const clientResponse = await makeRequest(clientOptions);
    
    if (clientResponse.statusCode === 200) {
      const clientData = JSON.parse(clientResponse.body);
      console.log('✅ Client trouvé:', clientData.data.nom, clientData.data.prenom || '');
    } else {
      console.log('❌ Client non trouvé:', clientResponse.body);
      return;
    }
    
    // Étape 3: Vérifier le compte client
    console.log('\n📋 Étape 3: Vérification du compte client ID #30...');
    
    const accountOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/accounts/customers/30/balance',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    const accountResponse = await makeRequest(accountOptions);
    
    if (accountResponse.statusCode === 200) {
      const accountData = JSON.parse(accountResponse.body);
      console.log('✅ Compte client trouvé:');
      console.log(`  - Compte ID: ${accountData.data.id}`);
      console.log(`  - Client ID: ${accountData.data.clientId}`);
      console.log(`  - Solde actuel: ${accountData.data.soldeActuel} FCFA`);
      console.log(`  - Limite crédit: ${accountData.data.limiteCredit} FCFA`);
      
      const compteId = accountData.data.id;
      
      // Étape 4: Vérifier les transactions via l'API
      console.log('\n📋 Étape 4: Vérification des transactions via API...');
      
      const transactionsOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/30/transactions',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      };
      
      const transactionsResponse = await makeRequest(transactionsOptions);
      
      if (transactionsResponse.statusCode === 200) {
        const transactionsData = JSON.parse(transactionsResponse.body);
        console.log(`✅ Réponse API transactions: ${transactionsData.data.length} transactions`);
        
        if (transactionsData.data.length === 0) {
          console.log('❌ PROBLÈME: API retourne 0 transaction mais vous dites qu\'elles existent en BD');
          
          // Étape 5: Diagnostic approfondi - Vérifier directement en base
          console.log('\n📋 Étape 5: Diagnostic approfondi...');
          console.log('HYPOTHÈSES À VÉRIFIER:');
          console.log('1. Les transactions sont-elles créées avec le bon compteId ?');
          console.log(`   - Compte ID attendu: ${compteId}`);
          console.log(`   - Client ID: 30`);
          console.log('2. Le filtrage dans la requête SQL est-il correct ?');
          console.log('3. Y a-t-il une différence entre typeCompte "client" et autre chose ?');
          
          // Étape 6: Vérifier les ventes du client
          console.log('\n📋 Étape 6: Vérification des ventes du client ID #30...');
          
          const salesOptions = {
            hostname: 'localhost',
            port: 3002,
            path: '/api/v1/sales?clientId=30',
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            }
          };
          
          const salesResponse = await makeRequest(salesOptions);
          
          if (salesResponse.statusCode === 200) {
            const salesData = JSON.parse(salesResponse.body);
            console.log(`✅ Ventes trouvées: ${salesData.data.length}`);
            
            salesData.data.forEach((vente, index) => {
              console.log(`  ${index + 1}. Vente ID: ${vente.id}`);
              console.log(`     - Montant total: ${vente.montantTotal} FCFA`);
              console.log(`     - Mode paiement: ${vente.modePaiement}`);
              console.log(`     - Montant restant: ${vente.montantRestant} FCFA`);
              console.log(`     - Date: ${vente.dateVente || vente.dateCreation}`);
            });
            
            if (salesData.data.length > 0) {
              console.log('\n🔍 ANALYSE:');
              console.log('- Des ventes existent pour ce client');
              console.log('- Mais aucune transaction de compte n\'est récupérée');
              console.log('- Le problème est probablement dans la logique de création des transactions');
              console.log('- Ou dans le filtrage des transactions par compteId');
            }
          } else {
            console.log('❌ Erreur récupération ventes:', salesResponse.body);
          }
          
        } else {
          console.log('✅ Transactions trouvées:');
          transactionsData.data.forEach((transaction, index) => {
            console.log(`  ${index + 1}. Transaction ID: ${transaction.id}`);
            console.log(`     - Type: ${transaction.typeTransaction}`);
            console.log(`     - Montant: ${transaction.montant} FCFA`);
            console.log(`     - Description: ${transaction.description}`);
            console.log(`     - Date: ${transaction.dateTransaction}`);
          });
        }
      } else {
        console.log('❌ Erreur récupération transactions:', transactionsResponse.body);
      }
      
    } else {
      console.log('❌ Erreur récupération compte:', accountResponse.body);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du diagnostic:', error);
  }
}

debugClient30();