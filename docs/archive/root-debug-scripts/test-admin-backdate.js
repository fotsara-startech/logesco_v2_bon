const http = require('http');

// Test rapide pour vérifier les privilèges admin
async function testAdminBackdate() {
  console.log('🧪 Test des privilèges admin pour l\'antidatage');
  
  try {
    // 1. Se connecter en tant qu'admin
    const loginData = JSON.stringify({
      nomUtilisateur: 'admin',
      motDePasse: 'admin123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    console.log('1. Connexion admin...');
    const loginResponse = await makeRequest(loginOptions, loginData);
    const loginResult = JSON.parse(loginResponse);
    
    if (!loginResult.success) {
      console.error('❌ Échec connexion:', loginResult.message);
      return;
    }

    const token = loginResult.data.token;
    console.log('✅ Connexion réussie');

    // 2. Vérifier les informations utilisateur
    const userOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/auth/me',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    console.log('2. Vérification profil utilisateur...');
    const userResponse = await makeRequest(userOptions);
    const userResult = JSON.parse(userResponse);
    
    if (userResult.success) {
      const user = userResult.data;
      console.log(`✅ Utilisateur: ${user.nomUtilisateur}`);
      console.log(`✅ Admin: ${user.role?.isAdmin}`);
      console.log(`✅ Privilèges:`, user.role?.privileges);
    }

    // 3. Tester création vente antidatée
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    const saleData = JSON.stringify({
      clientId: null,
      modePaiement: 'comptant',
      montantRemise: 0.0,
      montantPaye: 10000.0,
      dateVente: yesterday.toISOString(),
      details: [{
        produitId: 1, // Supposons que le produit 1 existe
        quantite: 1,
        prixUnitaire: 10000.0,
        prixAffiche: 10000.0,
        remiseAppliquee: 0.0,
        justificationRemise: null
      }]
    });

    const saleOptions = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/sales',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Length': Buffer.byteLength(saleData)
      }
    };

    console.log('3. Test création vente antidatée...');
    console.log(`   Date: ${yesterday.toLocaleDateString()}`);
    
    const saleResponse = await makeRequest(saleOptions, saleData);
    const saleResult = JSON.parse(saleResponse);
    
    console.log(`📊 Statut: ${saleResult.success ? 'SUCCÈS' : 'ÉCHEC'}`);
    console.log(`📊 Message: ${saleResult.message}`);
    
    if (saleResult.success) {
      console.log('✅ Vente antidatée créée avec succès !');
      console.log(`✅ Numéro: ${saleResult.data?.numeroVente}`);
    } else {
      console.log('❌ Échec création vente antidatée');
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve(body));
    });

    req.on('error', reject);
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

// Exécuter le test
testAdminBackdate();