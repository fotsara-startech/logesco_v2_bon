#!/usr/bin/env node

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const jwt = require('jsonwebtoken');
const http = require('http');
const { PrismaClient } = require('@prisma/client');

const JWT_SECRET = process.env.JWT_SECRET || 'logesco-default-secret-key';

async function testProcurement() {
  const prisma = new PrismaClient();
  
  try {
    console.log('📊 VÉRIFICATION DONNÉES PROCUREMENTS\n');
    
    // Compter les commandes dans la base
    const totalCommandes = await prisma.commandeApprovisionnement.count();
    console.log(`✅ Total commandes en BD: ${totalCommandes}`);
    
    if (totalCommandes > 0) {
      const firstFew = await prisma.commandeApprovisionnement.findMany({
        take: 3,
        include: {
          fournisseur: true,
          details: true
        }
      });
      
      console.log(`\n📋 Premières commandes:`);
      firstFew.forEach((cmd, i) => {
        console.log(`\n${i+1}. ID: ${cmd.id}`);
        console.log(`   - Fournisseur: ${cmd.fournisseur?.nom || 'N/A'}`);
        console.log(`   - Statut: ${cmd.statut}`);
        console.log(`   - Date: ${cmd.dateCommande}`);
        console.log(`   - Détails: ${cmd.details?.length || 0} produits`);
      });
    } else {
      console.log('\n⚠️  Aucune commande trouvée en base de données');
    }
    
    // Tester l'API
    console.log('\n\n🧪 TEST ENDPOINT /API/V1/PROCUREMENT\n');
    
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

    await new Promise((resolve, reject) => {
      const options = {
        hostname: 'localhost',
        port: 8080,
        path: '/api/v1/procurement?page=1&limit=10',
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
          if (res.statusCode === 200) {
            const json = JSON.parse(data);
            console.log('✅ Réponse API:');
            console.log(`   - Status: ${res.statusCode}`);
            console.log(`   - Total: ${json.data?.pagination?.total || 0}`);
            console.log(`   - Reçu: ${json.data?.commandes?.length || 0} commandes`);
            console.log(`   - Pages: ${json.data?.pagination?.pages || 0}`);
            
            if (json.data?.commandes?.length > 0) {
              console.log(`\n📦 Premières commandes de l'API:`);
              json.data.commandes.slice(0, 2).forEach((cmd, i) => {
                console.log(`\n${i+1}. ID: ${cmd.id}`);
                console.log(`   - Fournisseur: ${cmd.fournisseur?.nom || 'N/A'}`);
                console.log(`   - Statut: ${cmd.statut}`);
              });
            }
          } else {
            console.log(`❌ Erreur HTTP ${res.statusCode}`);
            console.log(`   Response: ${data.substring(0, 200)}`);
          }
          resolve();
        });
      });

      req.on('error', (error) => {
        console.error('❌ Erreur requête:', error.message);
        reject(error);
      });

      req.end();
    });
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testProcurement();
