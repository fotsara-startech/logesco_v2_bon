const { setupDatabase } = require('./scripts/setup-database');
const { ensureAdminExists } = require('./scripts/ensure-admin');
const server = require('./src/server');

async function startWithSetup() {
  try {
    console.log('🚀 Démarrage de LOGESCO Backend avec configuration automatique...');
    
    // 1. Configurer la base de données
    console.log('📦 Étape 1: Configuration de la base de données');
    await setupDatabase();
    
    // 2. S'assurer que l'utilisateur admin existe
    console.log('👑 Étape 2: Vérification de l\'utilisateur admin');
    await ensureAdminExists();
    
    // 3. Démarrer le serveur
    console.log('🌐 Étape 3: Démarrage du serveur');
    await server.start();
    
    console.log('✅ LOGESCO Backend démarré avec succès!');
    console.log('📋 Informations de connexion:');
    console.log('   - API: http://localhost:3002/api/v1');
    console.log('   - Admin: admin@logesco.com / admin123');
    console.log('   - Modules disponibles: users, roles, cash-registers, stock-inventory');
    
  } catch (error) {
    console.error('❌ Erreur lors du démarrage:', error);
    process.exit(1);
  }
}

// Démarrer si ce script est exécuté directement
if (require.main === module) {
  startWithSetup();
}

module.exports = { startWithSetup };