require('dotenv').config();
const { Client } = require('pg');

const cloudDbUrl = process.env.CLOUD_DB_URL;

async function checkData() {
  const client = new Client({ connectionString: cloudDbUrl });
  
  try {
    await client.connect();
    console.log('🌐 Connecté à Neon\n');
    
    // Vérifier les colonnes
    console.log('📋 Colonnes de la table clients:');
    const columns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'clients' 
      ORDER BY ordinal_position
    `);
    columns.rows.forEach(col => {
      console.log(`  - ${col.column_name} (${col.data_type})`);
    });
    
    // Vérifier les données
    console.log('\n📊 Données clients (5 premiers):');
    const clients = await client.query(`
      SELECT id, nom, prenom, nui, rccm 
      FROM clients 
      ORDER BY id DESC 
      LIMIT 5
    `);
    
    if (clients.rows.length === 0) {
      console.log('  Aucun client trouvé');
    } else {
      clients.rows.forEach(c => {
        console.log(`  #${c.id}: ${c.nom} ${c.prenom || ''}`);
        console.log(`    NUI: ${c.nui || '(vide)'}`);
        console.log(`    RCCM: ${c.rccm || '(vide)'}`);
      });
    }
    
    // Compter combien ont des valeurs
    const stats = await client.query(`
      SELECT 
        COUNT(*) as total,
        COUNT(nui) as avec_nui,
        COUNT(rccm) as avec_rccm
      FROM clients
    `);
    
    console.log('\n📈 Statistiques:');
    console.log(`  Total clients: ${stats.rows[0].total}`);
    console.log(`  Avec NUI: ${stats.rows[0].avec_nui}`);
    console.log(`  Avec RCCM: ${stats.rows[0].avec_rccm}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await client.end();
  }
}

checkData();
