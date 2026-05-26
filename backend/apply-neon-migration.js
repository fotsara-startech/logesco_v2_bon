/**
 * Applique migration.sql sur Neon via la connexion Node.js existante
 * Usage: node apply-neon-migration.js
 */
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function run() {
  const client = new Client({
    connectionString: 'postgresql://neondb_owner:npg_2gLKZJUC5RSa@ep-sweet-voice-alhik3h7.c-3.eu-central-1.aws.neon.tech/neondb',
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('Connexion à Neon...');
    await client.connect();
    console.log('✅ Connecté');

    const sqlPath = path.join(__dirname, 'prisma/migrations_pg/20260423221732_init_postgresql/migration.sql');
    // Lire et nettoyer le fichier
    let sql = fs.readFileSync(sqlPath, 'utf8');
    // Supprimer BOM si présent
    sql = sql.replace(/^\uFEFF/, '');
    // Convertir CRLF en LF
    sql = sql.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    console.log(`SQL chargé: ${sql.length} caractères, ${sql.split('\n').length} lignes`);
    console.log('Premier caractère code:', sql.charCodeAt(0));

    console.log('Application de la migration...');
    await client.query(sql);
    console.log('✅ Migration SQL appliquée avec succès');

    // Créer la table _prisma_migrations si elle n'existe pas
    await client.query(`
      CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
        id VARCHAR(36) NOT NULL,
        checksum VARCHAR(64) NOT NULL,
        finished_at TIMESTAMPTZ,
        migration_name VARCHAR(255) NOT NULL,
        logs TEXT,
        rolled_back_at TIMESTAMPTZ,
        started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        applied_steps_count INTEGER NOT NULL DEFAULT 0,
        CONSTRAINT "_prisma_migrations_pkey" PRIMARY KEY (id)
      )
    `);

    // Enregistrer la migration comme appliquée
    const { v4: uuidv4 } = require('uuid');
    await client.query(`
      INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
      VALUES ($1, $2, NOW(), $3, NULL, NULL, NOW(), 1)
      ON CONFLICT (id) DO NOTHING
    `, [uuidv4(), 'manual-apply', '20260423221732_init_postgresql']);

    console.log('✅ Migration enregistrée dans _prisma_migrations');
    console.log('\n🎉 Neon est prêt !');

  } catch (e) {
    console.error('❌ Erreur:', e.message);
    if (e.detail) console.error('   Detail:', e.detail);
    if (e.where) console.error('   Where:', e.where);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
