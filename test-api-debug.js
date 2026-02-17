#!/usr/bin/env node

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const jwt = require('jsonwebtoken');
const http = require('http');

const JWT_SECRET = process.env.JWT_SECRET || 'logesco-default-secret-key';

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
    const response = await makeRequest('/inventory?page=1&limit=2', token);
    
    if (response.status === 200) {
      const json = JSON.parse(response.body);
      console.log('📊 Réponse complète:\n');
      console.log(JSON.stringify(json, null, 2));
    } else {
      console.log(`Erreur: ${response.status}`);
    }
    
  } catch (error) {
    console.error('Erreur:', error.message);
  }
}

setTimeout(testAPI, 1000);
