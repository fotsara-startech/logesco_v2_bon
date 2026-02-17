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

async function testCreateSaleWithAuth() {
  console.log('🧪 TEST: Création d\'une vente avec authentification');
  console.log('==================================================');
  
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
    console.log('Réponse de connexion:', JSON.stringify(loginResult, null, 2));
    const token = loginResult.data?.accessToken || loginResult.data?.token || loginResult.token;
    console.log('✅ Connexion réussie, token obtenu:', token ? 'Oui' : 'Non');
    
    // Étape 2: Créer une vente avec le client #29
    console.log('\n📋 Étape 2: Création d\'une vente avec client ID #29...');
    
    const saleData = {
      clientId: 29,
      modePaiement: 'credit', // Vente à crédit pour créer une dette
      montantVerse: 15000, // Paiement partiel
      details: [
        {
          produitId: 33, // Utiliser un produit existant
          quantite: 2,
          prixUnitaire: 15000, // Prix système correct
          prixAffiche: 15000   // Prix affiché correct
        }
      ]
    };
    
    const saleOptions = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/sales',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    const saleResponse = await makeRequest(saleOptions, JSON.stringify(saleData));
    
    console.log(`Status création vente: ${saleResponse.statusCode}`);
    
    if (saleResponse.statusCode === 201) {
      const saleResult = JSON.parse(saleResponse.body);
      console.log('✅ Vente créée avec succès:');
      console.log(`  - ID Vente: ${saleResult.data.id}`);
      console.log(`  - Montant total: ${saleResult.data.montantTotal} FCFA`);
      console.log(`  - Montant versé: ${saleResult.data.montantVerse} FCFA`);
      console.log(`  - Montant restant: ${saleResult.data.montantRestant} FCFA`);
      console.log(`  - Mode paiement: ${saleResult.data.modePaiement}`);
      
      // Attendre un peu pour que les transactions soient créées
      console.log('\n⏳ Attente de 2 secondes pour la synchronisation...');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Étape 3: Vérifier le compte client après la vente
      console.log('\n📋 Étape 3: Vérification du compte client après la vente...');
      
      const accountOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/29/balance',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      };
      
      const accountResponse = await makeRequest(accountOptions);
      
      if (accountResponse.statusCode === 200) {
        const accountData = JSON.parse(accountResponse.body);
        console.log('✅ Compte client après vente:');
        console.log(`  - Solde actuel: ${accountData.data.soldeActuel} FCFA`);
        console.log(`  - Limite crédit: ${accountData.data.limiteCredit} FCFA`);
        console.log(`  - En dépassement: ${accountData.data.estEnDepassement}`);
      } else {
        console.log('❌ Erreur récupération compte:', accountResponse.body);
      }
      
      // Étape 4: Vérifier les transactions du compte
      console.log('\n📋 Étape 4: Vérification des transactions après la vente...');
      
      const transactionsOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/29/transactions',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      };
      
      const transactionsResponse = await makeRequest(transactionsOptions);
      
      if (transactionsResponse.statusCode === 200) {
        const transactionsData = JSON.parse(transactionsResponse.body);
        console.log(`✅ Transactions trouvées: ${transactionsData.data.length}`);
        
        transactionsData.data.forEach((transaction, index) => {
          console.log(`  ${index + 1}. Transaction ID: ${transaction.id}`);
          console.log(`     - Type: ${transaction.typeTransaction}`);
          console.log(`     - Montant: ${transaction.montant} FCFA`);
          console.log(`     - Description: ${transaction.description}`);
          console.log(`     - Date: ${transaction.dateTransaction}`);
          console.log(`     - Solde après: ${transaction.soldeApres} FCFA`);
        });
        
        if (transactionsData.data.length === 0) {
          console.log('❌ PROBLÈME: Aucune transaction créée malgré la vente !');
          console.log('   Les corrections du backend n\'ont pas fonctionné.');
        } else {
          console.log('✅ SUCCÈS: Les transactions ont été créées correctement !');
          console.log('   Les corrections du backend fonctionnent.');
        }
      } else {
        console.log('❌ Erreur récupération transactions:', transactionsResponse.body);
      }
      
      // Étape 5: Vérifier la liste des comptes clients
      console.log('\n📋 Étape 5: Vérification de la liste des comptes clients...');
      
      const accountsListOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      };
      
      const accountsListResponse = await makeRequest(accountsListOptions);
      
      if (accountsListResponse.statusCode === 200) {
        const accountsListData = JSON.parse(accountsListResponse.body);
        console.log(`✅ Comptes clients trouvés: ${accountsListData.data.length}`);
        
        // Chercher le compte du client ID #29
        const compteClient29 = accountsListData.data.find(compte => compte.clientId === 29);
        if (compteClient29) {
          console.log('✅ Compte client #29 trouvé dans la liste:');
          console.log(`  - Compte ID: ${compteClient29.id}`);
          console.log(`  - Client: ${compteClient29.client.nomComplet}`);
          console.log(`  - Solde: ${compteClient29.soldeActuel} FCFA`);
          console.log(`  - En dépassement: ${compteClient29.estEnDepassement}`);
          
          if (compteClient29.soldeActuel !== 0) {
            console.log('✅ SUCCÈS: Le solde du compte a été mis à jour !');
          } else {
            console.log('❌ PROBLÈME: Le solde du compte n\'a pas été mis à jour.');
          }
        } else {
          console.log('❌ Compte client #29 NON trouvé dans la liste des comptes');
        }
      } else {
        console.log('❌ Erreur liste comptes:', accountsListResponse.body);
      }
      
    } else {
      console.log('❌ Erreur création vente:', saleResponse.body);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

testCreateSaleWithAuth();