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

async function testClient31() {
  console.log('🔍 TEST: Nouveau client #31 - Vérification du problème');
  console.log('====================================================');
  
  try {
    // Étape 1: Connexion
    const loginData = {
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    };
    
    const loginResponse = await makeRequest({
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, JSON.stringify(loginData));
    
    const loginResult = JSON.parse(loginResponse.body);
    const token = loginResult.data?.accessToken;
    console.log('✅ Connexion réussie');
    
    // Étape 2: Créer une vente pour le client #31
    console.log('\n📋 Création d\'une vente pour le client #31...');
    
    const saleData = {
      clientId: 31,
      modePaiement: 'credit',
      montantVerse: 10000,
      details: [{
        produitId: 33,
        quantite: 1,
        prixUnitaire: 15000,
        prixAffiche: 15000
      }]
    };
    
    const saleResponse = await makeRequest({
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/sales',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    }, JSON.stringify(saleData));
    
    console.log(`Status création vente: ${saleResponse.statusCode}`);
    
    if (saleResponse.statusCode === 201) {
      const saleResult = JSON.parse(saleResponse.body);
      console.log('✅ Vente créée avec succès:');
      console.log(`  - ID Vente: ${saleResult.data.id}`);
      console.log(`  - Montant total: ${saleResult.data.montantTotal} FCFA`);
      console.log(`  - Mode paiement: ${saleResult.data.modePaiement}`);
      
      // Attendre un peu
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Étape 3: Vérifier le compte client
      console.log('\n📋 Vérification du compte client #31...');
      
      const accountResponse = await makeRequest({
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/31/balance',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (accountResponse.statusCode === 200) {
        const accountData = JSON.parse(accountResponse.body);
        console.log('✅ Compte client:');
        console.log(`  - Compte ID: ${accountData.data.id}`);
        console.log(`  - Client ID: ${accountData.data.clientId}`);
        console.log(`  - Solde: ${accountData.data.soldeActuel} FCFA`);
        
        // Étape 4: Vérifier les transactions
        console.log('\n📋 Vérification des transactions...');
        
        const transactionsResponse = await makeRequest({
          hostname: 'localhost',
          port: 3002,
          path: '/api/v1/accounts/customers/31/transactions',
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          }
        });
        
        if (transactionsResponse.statusCode === 200) {
          const transactionsData = JSON.parse(transactionsResponse.body);
          console.log(`✅ Transactions trouvées: ${transactionsData.data.length}`);
          
          if (transactionsData.data.length === 0) {
            console.log('❌ PROBLÈME CONFIRMÉ: Aucune transaction malgré la vente !');
            console.log('\n🔧 DIAGNOSTIC:');
            console.log('   1. Le backend n\'utilise pas le code corrigé');
            console.log('   2. Ou il y a encore du code qui utilise l\'ancien système');
            console.log('   3. Ou le backend n\'a pas été redémarré avec les corrections');
            
            // Vérifier les logs du backend
            console.log('\n💡 VÉRIFICATIONS À FAIRE:');
            console.log('   - Le backend a-t-il été redémarré après les corrections ?');
            console.log('   - Les logs du backend montrent-ils la création des transactions ?');
            console.log('   - Y a-t-il d\'autres endroits dans le code qui créent des transactions ?');
            
          } else {
            console.log('✅ SUCCÈS: Les transactions sont créées correctement !');
            transactionsData.data.forEach((transaction, index) => {
              console.log(`  ${index + 1}. Transaction ID: ${transaction.id}`);
              console.log(`     - Type: ${transaction.typeTransaction}`);
              console.log(`     - Montant: ${transaction.montant} FCFA`);
            });
          }
        }
      }
      
    } else {
      console.log('❌ Erreur création vente:', saleResponse.body);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  }
}

testClient31();