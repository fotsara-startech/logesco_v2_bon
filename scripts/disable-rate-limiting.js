/**
 * Script pour désactiver temporairement le rate limiting
 * LOGESCO v2 - Phase de test
 */

const fs = require('fs').promises;
const path = require('path');

async function disableRateLimiting() {
  console.log('🔧 Désactivation du rate limiting pour les tests...\n');

  try {
    // 1. Modifier le fichier .env pour ajouter TEST_MODE=true
    const envPath = path.join(__dirname, '..', '.env');
    
    try {
      let envContent = await fs.readFile(envPath, 'utf8');
      
      // Ajouter ou modifier TEST_MODE
      if (envContent.includes('TEST_MODE=')) {
        envContent = envContent.replace(/TEST_MODE=.*/, 'TEST_MODE=true');
      } else {
        envContent += '\n# Mode test - Rate limiting désactivé\nTEST_MODE=true\n';
      }
      
      // Ajouter DISABLE_RATE_LIMITING si pas présent
      if (!envContent.includes('DISABLE_RATE_LIMITING=')) {
        envContent += 'DISABLE_RATE_LIMITING=true\n';
      }
      
      await fs.writeFile(envPath, envContent);
      console.log('✅ Fichier .env mis à jour');
      
    } catch (error) {
      console.log('⚠️  Fichier .env non trouvé, création...');
      
      const defaultEnvContent = `# Configuration LOGESCO v2 - Mode Test
NODE_ENV=development
PORT=8080
DATABASE_URL="file:./database/logesco.db"
JWT_SECRET=test-secret-key-change-in-production
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info

# Mode test - Rate limiting désactivé
TEST_MODE=true
DISABLE_RATE_LIMITING=true
`;
      
      await fs.writeFile(envPath, defaultEnvContent);
      console.log('✅ Fichier .env créé avec mode test activé');
    }

    // 2. Créer un fichier de configuration temporaire
    const tempConfigPath = path.join(__dirname, 'temp-no-rate-limit.json');
    const tempConfig = {
      rateLimitingDisabled: true,
      timestamp: new Date().toISOString(),
      reason: 'Tests avec données réelles',
      instructions: [
        'Le rate limiting est temporairement désactivé',
        'Redémarrez le serveur pour appliquer les changements',
        'Utilisez enable-rate-limiting.js pour réactiver'
      ]
    };
    
    await fs.writeFile(tempConfigPath, JSON.stringify(tempConfig, null, 2));
    console.log('✅ Configuration temporaire créée');

    // 3. Afficher les instructions
    console.log('\n' + '='.repeat(60));
    console.log('🚨 RATE LIMITING DÉSACTIVÉ POUR LES TESTS');
    console.log('='.repeat(60));
    console.log('');
    console.log('📋 ÉTAPES SUIVANTES:');
    console.log('');
    console.log('1. 🔄 Redémarrez le serveur backend:');
    console.log('   - Arrêtez le serveur actuel (Ctrl+C)');
    console.log('   - Relancez: npm run dev');
    console.log('');
    console.log('2. 🧪 Lancez vos tests:');
    console.log('   - node scripts/comprehensive-real-data-test.js');
    console.log('   - Ou utilisez test-all-features.bat');
    console.log('');
    console.log('3. ✅ Vérifiez dans les logs du serveur:');
    console.log('   - Vous devriez voir "Rate limiting désactivé pour les tests"');
    console.log('');
    console.log('⚠️  IMPORTANT:');
    console.log('   - Cette configuration est temporaire');
    console.log('   - N\'oubliez pas de réactiver en production');
    console.log('   - Utilisez scripts/enable-rate-limiting.js pour réactiver');
    console.log('');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Erreur lors de la désactivation:', error.message);
    process.exit(1);
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  disableRateLimiting();
}

module.exports = disableRateLimiting;