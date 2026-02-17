const http = require('http');

async function testCreateSaleWithClient29() {
  console.log('🧪 TEST: Création d\'une vente avec le client LETO GAZO (ID #29)');
  console.log('================================================================');
  
  try {
    // Test 1: Créer une vente avec le client #29
    console.log('\n📋 Test 1: Création d\'une vente avec client ID #29...');
    
    const saleData = {
      clientId: 29,
      modePaiement: 'credit', // Vente à crédit pour créer une dette
      montantVerse: 5000, // Paiement partiel
      details: [
        {
          produitId: 1,
          quantite: 2,
          prixUnitaire: 5000
        }
      ]
    };
    
    const postData = JSON.stringify(saleData);
    
    const options = {
      hostname: 'localhost',
      port: 3002,
      path: '/api/v1/sales',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    const saleResponse = await new Promise((resolve, reject) => {
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
      
      req.write(postData);
      req.end();
    });
    
    console.log(`Status création vente: ${saleResponse.statusCode}`);
    
    if (saleResponse.statusCode === 201) {
      const saleResult = JSON.parse(saleResponse.body);
      console.log('✅ Vente créée avec succès:');
      console.log(`  - ID Vente: ${saleResult.data.id}`);
      console.log(`  - Montant total: ${saleResult.data.montantTotal} FCFA`);
      console.log(`  - Montant versé: ${saleResult.data.montantVerse} FCFA`);
      console.log(`  - Montant restant: ${saleResult.data.montantRestant} FCFA`);
      console.log(`  - Mode paiement: ${saleResult.data.modePaiement}`);
      
      // Test 2: Vérifier le compte client après la vente
      console.log('\n📋 Test 2: Vérification du compte client après la vente...');
      
      const accountOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/29/balance',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      };
      
      const accountResponse = await new Promise((resolve, reject) => {
        const req = http.request(accountOptions, (res) => {
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
        
        req.end();
      });
      
      if (accountResponse.statusCode === 200) {
        const accountData = JSON.parse(accountResponse.body);
        console.log('✅ Compte client après vente:');
        console.log(`  - Solde actuel: ${accountData.data.soldeActuel} FCFA`);
        console.log(`  - Limite crédit: ${accountData.data.limiteCredit} FCFA`);
        console.log(`  - En dépassement: ${accountData.data.estEnDepassement}`);
      } else {
        console.log('❌ Erreur récupération compte:', accountResponse.body);
      }
      
      // Test 3: Vérifier les transactions du compte
      console.log('\n📋 Test 3: Vérification des transactions après la vente...');
      
      const transactionsOptions = {
        hostname: 'localhost',
        port: 3002,
        path: '/api/v1/accounts/customers/29/transactions',
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      };
      
      const transactionsResponse = await new Promise((resolve, reject) => {
        const req = http.request(transactionsOptions, (res) => {
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
        
        req.end();
      });
      
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
        } else {
          console.log('✅ SUCCÈS: Les transactions ont été créées correctement !');
        }
      } else {
        console.log('❌ Erreur récupération transactions:', transactionsResponse.body);
      }
      
    } else {
      console.log('❌ Erreur création vente:', saleResponse.body);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

testCreateSaleWithClient29();