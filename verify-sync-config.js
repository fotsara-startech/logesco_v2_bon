/**
 * Script de vérification de la configuration de synchronisation
 * Usage: node verify-sync-config.js
 */

require('dotenv').config();

console.log('╔══════════════════════════════════════════════════════════════════╗');
console.log('║         VÉRIFICATION CONFIGURATION SYNCHRONISATION               ║');
console.log('╚══════════════════════════════════════════════════════════════════╝');
console.log('');

// 1. Variables d'environnement
console.log('1. VARIABLES D\'ENVIRONNEMENT');
console.log('   ─────────────────────────────────────────────────────────────');
console.log('   DATABASE_URL:', process.env.DATABASE_URL ? '✅ DÉFINI' : '❌ NON DÉFINI');
console.log('   CLOUD_DB_URL:', process.env.CLOUD_DB_URL ? '✅ DÉFINI' : '❌ NON DÉFINI');
console.log('   DEBUG_SYNC:', process.env.DEBUG_SYNC || 'false');
console.log('');

if (process.env.CLOUD_DB_URL) {
  const url = process.env.CLOUD_DB_URL;
  const masked = url.substring(0, 30) + '...' + url.substring(url.length - 20);
  console.log('   CLOUD_DB_URL (masqué):', masked);
  console.log('');
}

// 2. Fichiers critiques
console.log('2. FICHIERS CRITIQUES');
console.log('   ─────────────────────────────────────────────────────────────');
const fs = require('fs');
const path = require('path');

const criticalFiles = [
  'src/routes/sales.js',
  'src/middleware/prisma-sync-hooks.js',
  'src/services/sync-service.js',
  'src/config/database.js'
];

for (const file of criticalFiles) {
  const filePath = path.join(__dirname, file);
  const exists = fs.existsSync(filePath);
  const size = exists ? fs.statSync(filePath).size : 0;
  console.log(`   ${exists ? '✅' : '❌'} ${file} (${size} bytes)`);
}
console.log('');

// 3. Vérifier le code de sync manuelle dans sales.js
console.log('3. CODE DE SYNCHRONISATION MANUELLE');
console.log('   ─────────────────────────────────────────────────────────────');
const salesPath = path.join(__dirname, 'src/routes/sales.js');
if (fs.existsSync(salesPath)) {
  const content = fs.readFileSync(salesPath, 'utf8');
  
  const hasManualSync = content.includes('[Manual Sync]');
  const hasSyncService = content.includes('syncService.enqueue');
  const hasCloudDbCheck = content.includes('if (process.env.CLOUD_DB_URL)');
  const hasDebugLogs = content.includes('🔧 [Sync]');
  
  console.log('   Sync manuelle présente:', hasManualSync ? '✅ OUI' : '❌ NON');
  console.log('   syncService.enqueue():', hasSyncService ? '✅ OUI' : '❌ NON');
  console.log('   Vérification CLOUD_DB_URL:', hasCloudDbCheck ? '✅ OUI' : '❌ NON');
  console.log('   Logs de debug:', hasDebugLogs ? '✅ OUI' : '❌ NON');
  
  // Compter les occurrences
  const manualSyncCount = (content.match(/\[Manual Sync\]/g) || []).length;
  const enqueueCount = (content.match(/syncService\.enqueue/g) || []).length;
  
  console.log('');
  console.log('   Nombre de logs [Manual Sync]:', manualSyncCount);
  console.log('   Nombre d\'appels enqueue():', enqueueCount);
} else {
  console.log('   ❌ Fichier sales.js non trouvé!');
}
console.log('');

// 4. Test de connexion Prisma
console.log('4. TEST CONNEXION BASE DE DONNÉES');
console.log('   ─────────────────────────────────────────────────────────────');
(async () => {
  try {
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    
    await prisma.$connect();
    console.log('   ✅ Connexion SQLite réussie');
    
    const venteCount = await prisma.vente.count();
    const mouvementCount = await prisma.mouvementStock.count();
    const stockBoutiqueCount = await prisma.stockBoutique.count();
    
    console.log('   Nombre de ventes:', venteCount);
    console.log('   Nombre de mouvements de stock:', mouvementCount);
    console.log('   Nombre de stock_boutiques:', stockBoutiqueCount);
    
    await prisma.$disconnect();
  } catch (error) {
    console.log('   ❌ Erreur de connexion:', error.message);
  }
  console.log('');
  
  // 5. Résumé
  console.log('5. RÉSUMÉ');
  console.log('   ─────────────────────────────────────────────────────────────');
  
  const allGood = 
    process.env.CLOUD_DB_URL &&
    fs.existsSync(path.join(__dirname, 'src/routes/sales.js'));
  
  if (allGood) {
    console.log('   ✅ Configuration semble correcte');
    console.log('');
    console.log('   PROCHAINES ÉTAPES:');
    console.log('   1. Redémarrer le backend: npm start');
    console.log('   2. Créer une vente dans l\'application');
    console.log('   3. Vérifier les logs pour "🔧 [Sync]"');
  } else {
    console.log('   ⚠️  Configuration incomplète');
    console.log('');
    console.log('   PROBLÈMES DÉTECTÉS:');
    if (!process.env.CLOUD_DB_URL) {
      console.log('   • CLOUD_DB_URL non défini dans .env');
    }
    if (!fs.existsSync(path.join(__dirname, 'src/routes/sales.js'))) {
      console.log('   • Fichier sales.js manquant');
    }
  }
  
  console.log('');
  console.log('╔══════════════════════════════════════════════════════════════════╗');
  console.log('║                    VÉRIFICATION TERMINÉE                         ║');
  console.log('╚══════════════════════════════════════════════════════════════════╝');
})();
