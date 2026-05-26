/**
 * Script de test de connexion Neon
 * Teste la connexion et affiche des informations détaillées
 */

require('dotenv').config();
const { Pool } = require('pg');

async function testNeonConnection() {
  const cloudUrl = process.env.CLOUD_DB_URL;

  console.log('🔍 Test de connexion Neon\n');
  console.log('═'.repeat(60));

  if (!cloudUrl) {
    console.log('❌ CLOUD_DB_URL non défini dans .env');
    process.exit(1);
  }

  console.log('\n📋 Configuration');
  console.log('─'.repeat(60));
  
  // Masquer le mot de passe dans l'affichage
  const urlParts = cloudUrl.match(/postgresql:\/\/([^:]+):([^@]+)@([^\/]+)\/(.+)/);
  if (urlParts) {
    const [, user, , host, dbname] = urlParts;
    console.log(`Utilisateur: ${user}`);
    console.log(`Hôte: ${host}`);
    console.log(`Base de données: ${dbname.split('?')[0]}`);
    console.log(`Mot de passe: ${'*'.repeat(10)}`);
  } else {
    console.log(`URL: ${cloudUrl.substring(0, 30)}...`);
  }

  console.log('\n🔌 Test de connexion');
  console.log('─'.repeat(60));

  const pool = new Pool({
    connectionString: cloudUrl,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 10000,
  });

  try {
    console.log('Tentative de connexion...');
    const startTime = Date.now();
    
    const client = await pool.connect();
    const duration = Date.now() - startTime;
    
    console.log(`✅ Connexion établie en ${duration}ms`);

    // Test de requête simple
    console.log('\n📊 Test de requête');
    console.log('─'.repeat(60));
    const result = await client.query('SELECT version()');
    console.log('Version PostgreSQL:');
    console.log(`  ${result.rows[0].version.substring(0, 80)}...`);

    // Lister les tables
    console.log('\n📋 Tables disponibles');
    console.log('─'.repeat(60));
    const tables = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      ORDER BY tablename
    `);
    
    if (tables.rows.length === 0) {
      console.log('⚠️  Aucune table trouvée (base de données vide)');
    } else {
      console.log(`${tables.rows.length} table(s) trouvée(s):`);
      for (const row of tables.rows.slice(0, 10)) {
        console.log(`  - ${row.tablename}`);
      }
      if (tables.rows.length > 10) {
        console.log(`  ... et ${tables.rows.length - 10} autre(s)`);
      }
    }

    // Compter les enregistrements dans les tables principales
    console.log('\n📈 Statistiques des données');
    console.log('─'.repeat(60));
    const mainTables = ['utilisateurs', 'produits', 'clients', 'ventes', 'boutiques'];
    
    for (const table of mainTables) {
      try {
        const count = await client.query(`SELECT COUNT(*) as count FROM "${table}"`);
        console.log(`  ${table.padEnd(20)}: ${count.rows[0].count} enregistrement(s)`);
      } catch (e) {
        console.log(`  ${table.padEnd(20)}: Table non trouvée`);
      }
    }

    client.release();

    console.log('\n✅ Test de connexion réussi');
    console.log('═'.repeat(60));

  } catch (error) {
    console.log('\n❌ Erreur de connexion');
    console.log('─'.repeat(60));
    console.log(`Type: ${error.constructor.name}`);
    console.log(`Message: ${error.message}`);
    console.log(`Code: ${error.code || 'N/A'}`);
    
    if (error.code === 'ENOTFOUND') {
      console.log('\n💡 Suggestions:');
      console.log('  - Vérifiez votre connexion internet');
      console.log('  - Vérifiez que l\'hôte Neon est correct');
    } else if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Suggestions:');
      console.log('  - Le serveur Neon refuse la connexion');
      console.log('  - Vérifiez que la base de données est active sur Neon');
    } else if (error.message.includes('password')) {
      console.log('\n💡 Suggestions:');
      console.log('  - Vérifiez le mot de passe dans CLOUD_DB_URL');
      console.log('  - Régénérez le mot de passe sur la console Neon si nécessaire');
    } else if (error.message.includes('timeout')) {
      console.log('\n💡 Suggestions:');
      console.log('  - La connexion a expiré (timeout)');
      console.log('  - Vérifiez votre connexion internet');
      console.log('  - Le serveur Neon peut être temporairement indisponible');
    }
    
    console.log('\n📚 Ressources:');
    console.log('  - Console Neon: https://console.neon.tech/');
    console.log('  - Documentation: https://neon.tech/docs/');
    
    console.log('\n═'.repeat(60));
    process.exit(1);
  } finally {
    await pool.end();
  }
}

testNeonConnection();
