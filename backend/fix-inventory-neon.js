/**
 * Script pour ajouter date_modification aux tables stock_inventories et inventory_items sur Neon
 * Usage: node fix-inventory-neon.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function fixInventoryTables() {
  if (!process.env.CLOUD_DB_URL) {
    console.error('❌ CLOUD_DB_URL non défini dans .env');
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

    // Lire le fichier SQL
    const sqlPath = path.join(__dirname, 'prisma/migrations_pg/fix_inventory_date_modification.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('📝 Exécution du script SQL...');
    
    // Exécuter le script complet en une seule fois
    await client.query(sql);

    console.log('\n✅ Migration exécutée avec succès !');
    
    // Vérification
    console.log('\n📊 Vérification des colonnes ajoutées...');
    const result = await client.query(`
      SELECT 
        'stock_inventories' as table_name,
        COUNT(*) as total_rows,
        COUNT(date_modification) as rows_with_date_modification
      FROM stock_inventories
      UNION ALL
      SELECT 
        'inventory_items' as table_name,
        COUNT(*) as total_rows,
        COUNT(date_modification) as rows_with_date_modification
      FROM inventory_items
    `);
    
    console.table(result.rows);

    console.log('\n🔄 Redémarrez votre serveur backend pour que les changements prennent effet.');

  } catch (error) {
    console.error('\n❌ Erreur lors de l\'exécution:', error.message);
    console.error('\nDétails:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n👋 Déconnecté de Neon');
  }
}

// Charger les variables d'environnement
require('dotenv').config();

fixInventoryTables();
