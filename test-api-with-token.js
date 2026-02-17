#!/usr/bin/env node

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const jwt = require('jsonwebtoken');
const http = require('http');

const JWT_SECRET = process.env.JWT_SECRET || 'logesco-default-secret-key';

// Créer un token valide
const payload = {
  userId: 1,
  nomUtilisateur: 'test_user',
  email: 'test@logesco.local'
};

const token = jwt.sign(payload, JWT_SECRET, {
  expiresIn: '24h',
  issuer: 'logesco-api',
  audience: 'logesco-client'
});

console.log('🔐 Token généré:', token.substring(0, 30) + '...\n');

// Faire une requête HTTP avec le token
function makeRequest(endpoint, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: `/api/v1${endpoint}`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        resolve({
          status: res.statusCode,
          body: data
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

async function testAPI() {
  try {
    console.log('📝 Test de l\'endpoint /inventory\n');
    
    const response = await makeRequest('/inventory?page=1&limit=10', token);
    
    if (response.status === 200) {
      const json = JSON.parse(response.body);
      console.log('✅ Réponse reçue (Status 200)');
      console.log(`   - Total produits: ${json.pagination?.total}`);
      console.log(`   - Page 1: ${json.data?.length} produits reçus`);
      console.log(`   - Pages totales: ${Math.ceil(json.pagination?.total / 10)}`);
      
      if (json.data && json.data.length > 0) {
        console.log(`\n📦 Premier produit:`);
        const first = json.data[0];
        console.log(`   - Nom: ${first.nom}`);
        console.log(`   - Stock: ${first.stock ? 'Initié ✓' : 'Pas initié'}`);
        if (first.stock) {
          console.log(`   - Quantité: ${first.stock.quantiteDisponible}`);
        }
      }
    } else {
      console.log(`❌ Erreur HTTP ${response.status}`);
      const errorBody = JSON.parse(response.body);
      console.log(`   - Message: ${errorBody.error?.message}`);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

// Attendre 1 seconde et faire la requête
setTimeout(testAPI, 1000);
