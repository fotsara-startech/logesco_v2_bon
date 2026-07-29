#!/usr/bin/env node
/**
 * Test direct de l'API /sales pour voir l'erreur complète
 */

const http = require('http');

// D'abord, authentification
const loginData = JSON.stringify({
  nomUtilisateur: 'admin',
  motDePasse: 'admin123'
});

const loginReq = http.request({
  hostname: 'localhost',
  port: 8080,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const loginResult = JSON.parse(data);
    if (!loginResult.success) {
      console.error('❌ Login failed:', loginResult.message);
      return;
    }
    
    const token = loginResult.data.accessToken;
    console.log('✅ Login successful\n');
    
    // Maintenant, requête /sales
    const salesReq = http.request({
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/sales?page=1&limit=20&boutiqueId=1',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }, (salesRes) => {
      let salesData = '';
      salesRes.on('data', chunk => salesData += chunk);
      salesRes.on('end', () => {
        console.log(`Status: ${salesRes.statusCode}`);
        console.log(`Headers:`, salesRes.headers);
        console.log(`\nBody:`);
        try {
          const parsed = JSON.parse(salesData);
          console.log(JSON.stringify(parsed, null, 2));
        } catch (e) {
          console.log(salesData);
        }
      });
    });
    
    salesReq.on('error', err => console.error('Request error:', err));
    salesReq.end();
  });
});

loginReq.on('error', err => console.error('Login error:', err));
loginReq.write(loginData);
loginReq.end();
