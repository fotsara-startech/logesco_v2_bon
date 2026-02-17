/**
 * Script pour réactiver le rate limiting
 * LOGESCO v2 - Après les tests
 */

const fs = require('fs').promises;
const path = require('path');

async function enableRateLimiting() {
  console.log('🔧 Réactivation du rate limiting...\n');

  try {
    // 1. Modifier le fichier .env pour désactiver TEST_MODE
    const envPath = path.join(__dirname, '..', '.env');
    
    try {
      let envContent = await fs.readFile(envPath, 'utf8');
      
      // Modifier TEST_MODE
      if (envContent.includes('TEST_MODE=true')) {
        envContent = envContent.replace(/TEST_MODE=true/, 'TEST_MODE=false');
      }
      
      // Supprimer DISABLE_RATE_LIMITING
      envContent = envContent.replace(/DISABLE_RATE_LIMITING=true\n?/, '');
      
      // Supprimer les commentaires de test
      envContent = envContent.replace(/# Mode test - Rate limiting désactivé\n?/, '');
      
      await fs.writeFile(envPath, envContent);
      console.log('✅ Fichier .env restauré');
      
    } catch (error) {
      console.log('⚠️  Fichier .env non trouvé');
    }

    // 2. Supprimer le fichier de configuration temporaire
    const tempConfigPath = path.join(__dirname, 'temp-no-rate-limit.json');
    try {
      await fs.unlink(tempConfigPath);
      console.log('✅ Configuration temporaire supprimée');
    } catch (error) {
      // Fichier n'existe pas, pas de problème
    }

    // 3. Afficher les instructions
    console.log('\n' + '='.repeat(60));
    console.log('🛡️  RATE LIMITING RÉACTIVÉ');
    console.log('='.repeat(60));
    console.log('');
    console.log('📋 ÉTAPES SUIVANTES:');
    console.log('');
    console.log('1. 🔄 Redémarrez le serveur backend:');
    console.log('   - Arrêtez le serveur actuel (Ctrl+C)');
    console.log('   - Relancez: npm run dev');
    console.log('');
    console.log('2. ✅ Vérifiez dans les logs du serveur:');
    console.log('   - Le rate limiting devrait être actif');
    console.log('   - Limites normales appliquées');
    console.log('');
    console.log('📊 LIMITES NORMALES:');
    console.log('   - Login: 5 tentatives / 15 minutes');
    console.log('   - Register: 3 inscriptions / heure');
    console.log('   - API générale: 100 requêtes / 15 minutes');
    console.log('');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Erreur lors de la réactivation:', error.message);
    process.exit(1);
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  enableRateLimiting();
}

module.exports = enableRateLimiting;