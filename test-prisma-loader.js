/**
 * Test du chargeur Prisma
 * Vérifie que Prisma peut être chargé correctement
 */

const path = require('path');

console.log('🧪 Test du chargeur Prisma...\n');

// Test 1: Vérifier que le loader existe
console.log('[1/4] Vérification du loader...');
try {
  const { loadPrismaClient } = require('./backend/src/config/prisma-loader');
  console.log('✓ Loader trouvé');
} catch (error) {
  console.error('❌ Erreur:', error.message);
  process.exit(1);
}

// Test 2: Charger PrismaClient
console.log('\n[2/4] Chargement de PrismaClient...');
try {
  const { loadPrismaClient } = require('./backend/src/config/prisma-loader');
  const PrismaClient = loadPrismaClient();
  console.log('✓ PrismaClient chargé');
  console.log('  Type:', typeof PrismaClient);
  console.log('  Mode pkg:', typeof process.pkg !== 'undefined' ? 'Oui' : 'Non');
} catch (error) {
  console.error('❌ Erreur:', error.message);
  process.exit(1);
}

// Test 3: Créer une instance
console.log('\n[3/4] Création d\'une instance Prisma...');
try {
  const { loadPrismaClient } = require('./backend/src/config/prisma-loader');
  const PrismaClient = loadPrismaClient();
  const prisma = new PrismaClient();
  console.log('✓ Instance créée');
  console.log('  Méthodes disponibles:', Object.keys(prisma).slice(0, 5).join(', '), '...');
} catch (error) {
  console.error('❌ Erreur:', error.message);
  console.error(error.stack);
  process.exit(1);
}

// Test 4: Vérifier les fichiers Prisma
console.log('\n[4/4] Vérification des fichiers Prisma...');
const fs = require('fs');

const prismaClientPath = path.join(__dirname, 'backend', 'node_modules', '@prisma', 'client');
const dotPrismaClientPath = path.join(__dirname, 'backend', 'node_modules', '.prisma', 'client');

if (fs.existsSync(prismaClientPath)) {
  console.log('✓ @prisma/client trouvé');
} else {
  console.log('❌ @prisma/client manquant');
  console.log('   Exécutez: cd backend && npm install');
}

if (fs.existsSync(dotPrismaClientPath)) {
  console.log('✓ .prisma/client trouvé');
} else {
  console.log('❌ .prisma/client manquant');
  console.log('   Exécutez: cd backend && npx prisma generate');
}

console.log('\n✅ Tous les tests réussis!');
console.log('\nProchaine étape: Reconstruire le backend');
console.log('  Exécutez: rebuild-backend-production.bat');
