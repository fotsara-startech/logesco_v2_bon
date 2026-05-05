/**
 * Script de test pour vérifier que les hooks Prisma fonctionnent
 * Usage: node test-prisma-hooks.js
 */

require('dotenv').config();

async function testPrismaHooks() {
  console.log('=== Test des hooks Prisma ===\n');
  
  // 1. Vérifier les variables d'environnement
  console.log('1. Variables d\'environnement:');
  console.log('   CLOUD_DB_URL:', process.env.CLOUD_DB_URL ? 'DÉFINI' : 'NON DÉFINI');
  console.log('   DATABASE_URL:', process.env.DATABASE_URL || '(non défini)');
  console.log('   DEBUG_SYNC:', process.env.DEBUG_SYNC || 'false');
  console.log('');
  
  // 2. Charger Prisma
  console.log('2. Chargement de Prisma...');
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();
  console.log('   ✅ PrismaClient créé');
  console.log('   Type:', typeof prisma);
  console.log('   Méthode $extends:', typeof prisma.$extends);
  console.log('');
  
  // 3. Charger les hooks
  console.log('3. Chargement des hooks de synchronisation...');
  const { setupPrismaSyncHooks } = require('./src/middleware/prisma-sync-hooks');
  const extendedPrisma = setupPrismaSyncHooks(prisma);
  console.log('   Extension retournée:', extendedPrisma !== prisma ? 'NOUVELLE INSTANCE' : 'MÊME INSTANCE');
  console.log('');
  
  // 4. Tester une opération
  console.log('4. Test d\'une opération de base de données...');
  try {
    await extendedPrisma.$connect();
    console.log('   ✅ Connexion réussie');
    
    // Compter les mouvements de stock
    const count = await extendedPrisma.mouvementStock.count();
    console.log('   Nombre de mouvements de stock:', count);
    
    await extendedPrisma.$disconnect();
    console.log('   ✅ Déconnexion réussie');
  } catch (error) {
    console.error('   ❌ Erreur:', error.message);
  }
  console.log('');
  
  console.log('=== Test terminé ===');
}

testPrismaHooks().catch(console.error);
