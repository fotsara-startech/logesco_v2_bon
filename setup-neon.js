/**
 * Script pour configurer complètement une base de données Neon pour LOGESCO
 * Usage: node setup-neon.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function setupNeon() {
  if (!process.env.CLOUD_DB_URL) {
    console.error('❌ CLOUD_DB_URL non défini dans .env');
    console.log('\n💡 Ajoutez votre URL Neon dans le fichier .env:');
    console.log('   CLOUD_DB_URL="postgresql://user:password@host/database?sslmode=require"');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔌 Connexion à Neon...');
    await client.connect();
    console.log('✅ Connecté à Neon\n');

    // Lire le fichier SQL complet
    const sqlPath = path.join(__dirname, 'prisma/migrations_pg/COMPLETE_NEON_SETUP.sql');
    
    if (!fs.existsSync(sqlPath)) {
      console.error('❌ Fichier COMPLETE_NEON_SETUP.sql introuvable');
      process.exit(1);
    }

    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('📝 Exécution du script de configuration complet...');
    console.log('   (Cela peut prendre quelques secondes)\n');
    
    // Exécuter le script complet
    await client.query(sql);

    console.log('\n✅ Configuration complète exécutée avec succès !');
    console.log('\n📊 Vérifiez les résultats ci-dessus pour confirmer que tout est OK.');
    console.log('\n🔄 Vous pouvez maintenant:');
    console.log('   1. Redémarrer votre serveur backend');
    console.log('   2. La synchronisation incrémentale sera automatiquement activée');
    console.log('   3. Les logs ne devraient plus afficher de "pull complet"');

  } catch (error) {
    console.error('\n❌ Erreur lors de l\'exécution:', error.message);
    
    if (error.message.includes('does not exist')) {
      console.log('\n💡 Certaines tables n\'existent pas encore.');
      console.log('   Assurez-vous d\'avoir exécuté la migration initiale:');
      console.log('   npx prisma migrate deploy');
    } else if (error.message.includes('permission denied')) {
      console.log('\n💡 Problème de permissions.');
      console.log('   Vérifiez que votre utilisateur Neon a les droits nécessaires.');
    } else {
      console.error('\nDétails:', error);
    }
    
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n👋 Déconnecté de Neon');
  }
}

// Charger les variables d'environnement
require('dotenv').config();

// Afficher les informations
console.log('============================================================');
console.log('LOGESCO - Configuration complète de Neon PostgreSQL');
console.log('============================================================\n');

setupNeon();
