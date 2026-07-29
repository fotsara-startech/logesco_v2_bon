require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

// Utiliser le schéma PostgreSQL
process.env.DATABASE_URL = process.env.CLOUD_DB_URL;

const cloudDbUrl = process.env.CLOUD_DB_URL;

if (!cloudDbUrl) {
  console.error('❌ CLOUD_DB_URL non défini dans .env');
  process.exit(1);
}

console.log('🌐 Connexion à Neon...');

// Utiliser pg directement pour éviter les problèmes de schéma Prisma
const { Client } = require('pg');

async function runMigration() {
  const client = new Client({
    connectionString: cloudDbUrl,
  });

  try {
    console.log('🔌 Connexion à la base...');
    await client.connect();
    
    console.log('📋 Lecture du fichier de migration...');
    const migrationSQL = fs.readFileSync(
      path.join(__dirname, 'migrations', 'add_nui_rccm_to_clients.sql'),
      'utf8'
    );

    console.log('🚀 Exécution de la migration...');
    await client.query(migrationSQL);
    
    console.log('✅ Migration exécutée avec succès!');
    
    // Vérifier les colonnes
    console.log('\n🔍 Vérification des colonnes...');
    const result = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'clients' 
      AND column_name IN ('nui', 'rccm', 'nui_rccm')
      ORDER BY column_name
    `);
    
    console.log('Colonnes trouvées:');
    result.rows.forEach(col => {
      console.log(`  - ${col.column_name} (${col.data_type})`);
    });
    
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
