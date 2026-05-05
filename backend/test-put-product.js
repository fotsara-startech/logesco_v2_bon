const http = require('http');

// D'abord, obtenir un token valide
const loginData = JSON.stringify({ nomUtilisateur: 'admin', motDePasse: 'admin123' });

const loginReq = http.request({
  hostname: 'localhost',
  port: 8080,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': loginData.length }
}, (res) => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => {
    const loginResult = JSON.parse(body);
    const token = loginResult.data?.accessToken;
    console.log('Token:', token ? 'OK' : 'FAILED');
    if (!token) { console.log('Login response:', body); return; }

    // Maintenant tester le PUT
    const putData = JSON.stringify({
      reference: 'PRD20261033',
      nom: 'AMPOULE DE MICRO - SCOPE',
      prixUnitaire: 1200,
      prixAchat: 800,
      categorie: 'CONSOMMABLE',
      seuilStockMinimum: 0,
      remiseMaxAutorisee: 0,
      estActif: true,
      estService: false,
      gestionPeremption: false
    });

    const putReq = http.request({
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/products/1033',
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': putData.length,
        'Authorization': `Bearer ${token}`
      }
    }, (res2) => {
      let body2 = '';
      res2.on('data', d => body2 += d);
      res2.on('end', () => {
        console.log('Status:', res2.statusCode);
        const result = JSON.parse(body2);
        console.log('Response:', JSON.stringify(result, null, 2));
      });
    });
    putReq.write(putData);
    putReq.end();
  });
});
loginReq.write(loginData);
loginReq.end();
