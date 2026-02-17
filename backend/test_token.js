/**
 * Script pour générer un token de test
 */

const jwt = require('jsonwebtoken');

// Configuration (doit correspondre à celle du serveur)
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key';
const JWT_EXPIRES_IN = '24h';

// Utilisateur de test
const testUser = {
  id: 1,
  nomUtilisateur: 'admin',
  email: 'admin@logesco.com'
};

// Générer le token
const payload = {
  userId: testUser.id,
  nomUtilisateur: testUser.nomUtilisateur,
  email: testUser.email
};

const accessToken = jwt.sign(
  payload,
  JWT_SECRET,
  { 
    expiresIn: JWT_EXPIRES_IN,
    issuer: 'logesco-api',
    audience: 'logesco-client'
  }
);

console.log('🔑 Token de test généré:');
console.log(accessToken);
console.log('\n📋 Pour tester l\'API, utilisez ce header:');
console.log(`Authorization: Bearer ${accessToken}`);
console.log('\n🧪 Test avec curl:');
console.log(`curl -H "Authorization: Bearer ${accessToken}" http://localhost:3002/api/v1/sales`);