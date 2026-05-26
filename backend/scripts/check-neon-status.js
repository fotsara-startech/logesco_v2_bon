/**
 * Script pour vérifier l'état de Neon et diagnostiquer les problèmes de connexion
 */

require('dotenv').config();
const https = require('https');
const { URL } = require('url');

async function checkNeonStatus() {
  const cloudUrl = process.env.CLOUD_DB_URL;

  console.log('🔍 Vérification de l\'état de Neon\n');
  console.log('═'.repeat(60));

  if (!cloudUrl) {
    console.log('❌ CLOUD_DB_URL non défini dans .env');
    process.exit(1);
  }

  // Parser l'URL
  const urlMatch = cloudUrl.match(/postgresql:\/\/([^:]+):([^@]+)@([^\/]+)\/(.+)/);
  if (!urlMatch) {
    console.log('❌ Format CLOUD_DB_URL invalide');
    process.exit(1);
  }

  const [, user, password, host, dbname] = urlMatch;
  const hostOnly = host.split(':')[0]; // Enlever le port si présent

  console.log('\n📋 Configuration Neon');
  console.log('─'.repeat(60));
  console.log(`Hôte: ${hostOnly}`);
  console.log(`Base de données: ${dbname.split('?')[0]}`);
  console.log(`Utilisateur: ${user}`);

  // Test 1 : Résolution DNS
  console.log('\n🌐 Test 1 : Résolution DNS');
  console.log('─'.repeat(60));
  const dns = require('dns').promises;
  try {
    const addresses = await dns.resolve4(hostOnly);
    console.log(`✅ DNS résolu: ${addresses[0]}`);
  } catch (e) {
    console.log(`❌ Échec résolution DNS: ${e.message}`);
    console.log('\n💡 Suggestions:');
    console.log('  - Vérifiez votre connexion internet');
    console.log('  - Vérifiez que le nom d\'hôte Neon est correct');
    process.exit(1);
  }

  // Test 2 : Connectivité HTTPS (port 443)
  console.log('\n🔌 Test 2 : Connectivité HTTPS');
  console.log('─'.repeat(60));
  try {
    await new Promise((resolve, reject) => {
      const req = https.get(`https://${hostOnly}`, (res) => {
        console.log(`✅ Port 443 accessible (Status: ${res.statusCode})`);
        resolve();
      });
      req.on('error', reject);
      req.setTimeout(5000, () => {
        req.destroy();
        reject(new Error('Timeout'));
      });
    });
  } catch (e) {
    console.log(`⚠️  Port 443 non accessible: ${e.message}`);
    console.log('   (Normal si Neon n\'écoute pas sur HTTPS)');
  }

  // Test 3 : Connectivité PostgreSQL (port 5432)
  console.log('\n🐘 Test 3 : Connectivité PostgreSQL (port 5432)');
  console.log('─'.repeat(60));
  const net = require('net');
  try {
    await new Promise((resolve, reject) => {
      const socket = new net.Socket();
      socket.setTimeout(5000);
      
      socket.on('connect', () => {
        console.log('✅ Port 5432 accessible');
        socket.destroy();
        resolve();
      });
      
      socket.on('timeout', () => {
        socket.destroy();
        reject(new Error('Timeout de connexion'));
      });
      
      socket.on('error', (err) => {
        reject(err);
      });
      
      socket.connect(5432, hostOnly);
    });
  } catch (e) {
    console.log(`❌ Port 5432 inaccessible: ${e.message}`);
    console.log('\n💡 Causes possibles:');
    console.log('  1. Pare-feu bloquant le port 5432');
    console.log('  2. Base de données Neon en pause/inactive');
    console.log('  3. Problème de réseau/proxy');
    console.log('\n🔧 Solutions:');
    console.log('  1. Vérifiez sur https://console.neon.tech/ que la BD est active');
    console.log('  2. Désactivez temporairement le pare-feu/antivirus');
    console.log('  3. Essayez depuis un autre réseau (partage de connexion mobile)');
    process.exit(1);
  }

  // Test 4 : Connexion PostgreSQL complète
  console.log('\n🔐 Test 4 : Authentification PostgreSQL');
  console.log('─'.repeat(60));
  const { Pool } = require('pg');
  const pool = new Pool({
    connectionString: cloudUrl,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 10000,
  });

  try {
    const client = await pool.connect();
    console.log('✅ Authentification réussie');
    
    const result = await client.query('SELECT current_database(), current_user');
    console.log(`   Base de données: ${result.rows[0].current_database}`);
    console.log(`   Utilisateur: ${result.rows[0].current_user}`);
    
    client.release();
    await pool.end();
    
    console.log('\n✅ Tous les tests réussis - Neon est accessible');
    console.log('═'.repeat(60));
  } catch (e) {
    console.log(`❌ Échec authentification: ${e.message}`);
    console.log('\n💡 Suggestions:');
    console.log('  - Vérifiez le mot de passe dans CLOUD_DB_URL');
    console.log('  - Régénérez les credentials sur console.neon.tech');
    await pool.end();
    process.exit(1);
  }
}

checkNeonStatus();
