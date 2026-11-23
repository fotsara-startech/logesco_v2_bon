const { Pool } = require('pg');

/**
 * Applique les changements de schéma Postgres manquants sur Neon, au
 * démarrage du backend local (mode hybride, quand CLOUD_DB_URL est
 * configuré). Compense le fait que schema.prisma (SQLite) et
 * schema.postgresql.prisma (Neon) sont deux fichiers maintenus à la main :
 * un champ ajouté dans l'un et oublié dans l'autre fait échouer la
 * synchro cloud avec des erreurs "column ... does not exist" en cascade
 * (toute ligne dépendante est ensuite rejetée par ses clés étrangères).
 *
 * Contrairement à SQLite (voir migration-runner.js, un poste par base),
 * Neon est une base PARTAGÉE par tous les postes clients en mode hybride :
 * chaque instruction ci-dessous doit être idempotente (IF NOT EXISTS),
 * pour ne jamais échouer si un autre poste l'a déjà appliquée entre-temps.
 *
 * Nouvelle colonne/table à ajouter sur Neon ? Ajoutez une entrée à
 * MIGRATIONS ci-dessous (ET faites le même ajout dans
 * prisma/schema.postgresql.prisma). C'est le seul endroit à toucher pour
 * que les postes déjà en service la reçoivent automatiquement.
 */
const MIGRATIONS = [
  {
    name: 'add_avance_utilisee',
    sql: 'ALTER TABLE ventes ADD COLUMN IF NOT EXISTS avance_utilisee DOUBLE PRECISION NOT NULL DEFAULT 0',
  },
  {
    name: 'add_annulation_articles_vente',
    sql: `ALTER TABLE details_ventes ADD COLUMN IF NOT EXISTS annule BOOLEAN NOT NULL DEFAULT false;
          ALTER TABLE details_ventes ADD COLUMN IF NOT EXISTS date_annulation TIMESTAMPTZ`,
  },
  {
    name: 'add_compta_socle',
    sql: require('./compta-schema-pg'),
  },
  {
    name: 'add_compta_immobilisations',
    sql: require('./compta-schema-pg-immobilisations'),
  },
];

const TRACKING_TABLE = '_app_migrations_pg';

/**
 * @param {string | undefined} cloudDbUrl process.env.CLOUD_DB_URL
 */
async function run(cloudDbUrl) {
  if (!cloudDbUrl) return; // mode local pur (pas de synchro cloud) : rien à faire

  const pool = new Pool({
    connectionString: cloudDbUrl,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 15000,
  });
  pool.on('error', (e) => console.warn('⚠️  [Neon] Connexion inactive perdue (migrations) —', e.message));

  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS ${TRACKING_TABLE} (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);

    const { rows } = await pool.query(`SELECT name FROM ${TRACKING_TABLE}`);
    const applied = new Set(rows.map((r) => r.name));
    const pending = MIGRATIONS.filter((m) => !applied.has(m.name));

    if (pending.length === 0) return;

    console.log(`🔄 [Neon] ${pending.length} migration(s) de schéma en attente — application...`);
    for (const migration of pending) {
      try {
        await pool.query(migration.sql);
        await pool.query(`INSERT INTO ${TRACKING_TABLE} (name) VALUES ($1) ON CONFLICT DO NOTHING`, [migration.name]);
        console.log(`✅ [Neon] Migration appliquée: ${migration.name}`);
      } catch (err) {
        // Non bloquant : la synchro continuera d'échouer pour les tables
        // concernées jusqu'à ce que ce soit corrigé, mais ne doit pas
        // empêcher le reste du backend de démarrer.
        console.warn(`⚠️  [Neon] Migration ${migration.name} échouée (sera retentée au prochain démarrage) : ${err.message}`);
      }
    }
  } catch (err) {
    console.warn(`⚠️  [Neon] Vérification des migrations cloud impossible (non bloquant) : ${err.message}`);
  } finally {
    await pool.end().catch(() => {});
  }
}

module.exports = { run, MIGRATIONS };
