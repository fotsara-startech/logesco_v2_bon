#!/usr/bin/env node
/**
 * Test direct de la fonction getSales pour voir l'erreur exacte
 */

const { PrismaClient } = require('@prisma/client');
const path = require('path');

const dbPath = path.join(
  process.env.LOCALAPPDATA || 'C:\\Users\\Default\\AppData\\Local',
  'LOGESCO',
  'backend',
  'database',
  'logesco.db'
);

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${dbPath.replace(/\\/g, '/')}`
    }
  },
  log: ['query', 'error', 'warn']
});

async function testGetSales() {
  console.log('🔍 Test direct de la requête SQL...\n');
  
  try {
    // Simuler la requête exacte du backend
    const page = 1;
    const limit = 20;
    const boutiqueId = 1;
    const skip = (page - 1) * limit;
    
    console.log('Paramètres:');
    console.log('  - page:', page);
    console.log('  - limit:', limit);
    console.log('  - boutiqueId:', boutiqueId);
    console.log('  - skip:', skip);
    console.log('');
    
    // Tester d'abord une requête simple
    console.log('Test 1: COUNT simple');
    const count = await prisma.vente.count({ where: { boutiqueId } });
    console.log(`✅ ${count} ventes trouvées\n`);
    
    // Test 2: Requête sans includes
    console.log('Test 2: SELECT sans includes');
    const ventesSimple = await prisma.vente.findMany({
      where: { boutiqueId },
      take: limit,
      skip,
      orderBy: { id: 'desc' }
    });
    console.log(`✅ ${ventesSimple.length} ventes récupérées\n`);
    
    // Test 3: Avec includes (comme dans le backend)
    console.log('Test 3: SELECT avec includes (client, vendeur, details)');
    const ventesComplete = await prisma.vente.findMany({
      where: { boutiqueId },
      take: limit,
      skip,
      orderBy: { id: 'desc' },
      include: {
        client: {
          select: {
            id: true,
            nom: true,
            prenom: true,
            telephone: true,
            adresse: true
          }
        },
        vendeur: {
          select: {
            id: true,
            nomUtilisateur: true
          }
        },
        details: {
          include: {
            produit: {
              select: {
                id: true,
                nom: true,
                reference: true
              }
            }
          }
        }
      }
    });
    console.log(`✅ ${ventesComplete.length} ventes complètes récupérées\n`);
    
    if (ventesComplete.length > 0) {
      console.log('Exemple de vente:');
      console.log(JSON.stringify(ventesComplete[0], null, 2));
    }
    
  } catch (error) {
    console.error('\n❌ ERREUR DÉTECTÉE:');
    console.error('Type:', error.constructor.name);
    console.error('Message:', error.message);
    console.error('Code:', error.code);
    console.error('\nStack trace:');
    console.error(error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

testGetSales();
