const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://neondb_owner:npg_2gLKZJUC5RSa@ep-sweet-voice-alhik3h7.c-3.eu-central-1.aws.neon.tech/neondb',
  ssl: { rejectUnauthorized: false }
});

client.connect().then(async () => {
  // Supprimer les doublons - garder seulement le plus recent
  const del = await client.query(`
    DELETE FROM _prisma_migrations
    WHERE migration_name = '20260423221732_init_postgresql'
    AND id NOT IN (
      SELECT id FROM _prisma_migrations
      WHERE migration_name = '20260423221732_init_postgresql'
      ORDER BY started_at DESC
      LIMIT 1
    )
  `);
  console.log('Doublons supprimes:', del.rowCount);

  // S'assurer que l'entree restante est marquee comme appliquee
  await client.query(`
    UPDATE _prisma_migrations
    SET finished_at = NOW(), rolled_back_at = NULL, applied_steps_count = 1
    WHERE migration_name = '20260423221732_init_postgresql'
  `);

  const check = await client.query(
    "SELECT id, migration_name, finished_at, rolled_back_at, applied_steps_count FROM _prisma_migrations"
  );
  console.log('Etat final:');
  check.rows.forEach(r => console.log(' -', r.migration_name, '| finished:', r.finished_at ? 'OUI' : 'NON', '| steps:', r.applied_steps_count));

  await client.end();
}).catch(e => { console.error(e.message); process.exit(1); });
