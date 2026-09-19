const fs = require('fs');
const path = require('path');

/**
 * Runner de migration SQLite in-process pour les postes clients.
 *
 * Contexte : les postes clients n'exécutent jamais le CLI `prisma migrate`
 * (spawn trop lent — c'est pour ça qu'un fast-path avait été ajouté qui
 * sautait toute vérification dès que la DB existait déjà). Résultat : plus
 * aucune migration réelle n'était rejouée après la première installation,
 * et le rattrapage reposait sur 2-3 listes de ALTER TABLE codées à la main
 * dans server.js/schema-validator.js, désynchronisées de schema.prisma.
 *
 * Ce module lit directement les fichiers migration.sql de prisma/migrations
 * (source unique de vérité, partagée avec l'historique Prisma) et les
 * applique un par un, dans l'ordre, en gardant la trace de ce qui a déjà
 * été fait dans une table _app_migrations. Aucun process n'est spawné :
 * tout passe par la connexion Prisma déjà ouverte.
 *
 * Nouvelle migration à livrer ? Ajoutez le dossier prisma/migrations/<nom>/
 * comme d'habitude (migration.sql), puis ajoutez son nom à MIGRATION_ORDER
 * ci-dessous, à la fin. C'est le seul endroit à toucher.
 */
const MIGRATION_ORDER = [
  '20260602145015_add_stock_snapshots',
  'add_date_modification_columns',
  'add_date_modification_more_tables',
  'add_date_modification_remaining_tables',
  'add_operation_log',
  'add_stock_date_modification',
  'fix_null_date_modifications',
  'add_deleted_records',
  'add_product_image',
  '20260717125521_add_nui_rccm_to_clients',
  'add_financial_movements_statut',
  'add_missing_date_modification_columns',
  'add_proforma_tables',
  '20260810185100_add_commerciaux',
  '20260811093000_snapshot_zone_ville_sur_ventes',
  'add_separation_commande_visibilite_ventes',
];

const TRACKING_TABLE = '_app_migrations';

// Erreurs sans danger : l'effet visé existe déjà (colonne/table/index déjà
// présent, souvent via un des anciens correctifs ad-hoc). On les avale pour
// que la migration soit quand même marquée comme appliquée.
const BENIGN_ERROR_PATTERNS = [/duplicate column name/i, /already exists/i];

function migrationsDir() {
  return path.join(__dirname, '../../prisma/migrations');
}

// Les fichiers migration.sql de ce projet ne contiennent que des
// ALTER/CREATE/UPDATE simples (pas de triggers ni de blocs BEGIN...END) :
// un split naïf sur ';' après retrait des lignes de commentaire suffit.
function splitStatements(sql) {
  return sql
    .split('\n')
    .filter((line) => !line.trim().startsWith('--'))
    .join('\n')
    .split(';')
    .map((s) => s.trim())
    .filter(Boolean);
}

async function ensureTrackingTable(prisma) {
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS ${TRACKING_TABLE} (
      name TEXT PRIMARY KEY,
      applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

async function getAppliedNames(prisma) {
  const rows = await prisma.$queryRawUnsafe(`SELECT name FROM ${TRACKING_TABLE}`);
  return new Set(rows.map((r) => r.name));
}

async function markApplied(prisma, name) {
  await prisma.$executeRawUnsafe(
    `INSERT OR IGNORE INTO ${TRACKING_TABLE} (name) VALUES (?)`,
    name
  );
}

/**
 * @param {import('@prisma/client').PrismaClient} prisma
 * @param {{ freshInstall?: boolean }} opts freshInstall=true si la base vient
 *   d'être créée par `prisma db push` (schéma déjà à jour) : on marque tout
 *   l'historique comme appliqué sans rejouer le SQL.
 */
async function run(prisma, { freshInstall = false } = {}) {
  await ensureTrackingTable(prisma);

  if (freshInstall) {
    for (const name of MIGRATION_ORDER) {
      await markApplied(prisma, name);
    }
    console.log(`✅ ${MIGRATION_ORDER.length} migration(s) marquée(s) comme appliquées (installation neuve)`);
    return;
  }

  const applied = await getAppliedNames(prisma);
  const pending = MIGRATION_ORDER.filter((name) => !applied.has(name));

  if (pending.length === 0) {
    return; // fast path : une seule requête, aucun fichier lu
  }

  console.log(`🔄 ${pending.length} migration(s) en attente — application...`);
  const dir = migrationsDir();

  for (const name of pending) {
    const sqlPath = path.join(dir, name, 'migration.sql');
    if (!fs.existsSync(sqlPath)) {
      console.warn(`⚠️  Migration ${name} introuvable (${sqlPath}) — ignorée`);
      continue;
    }

    const statements = splitStatements(fs.readFileSync(sqlPath, 'utf8'));
    for (const statement of statements) {
      try {
        await prisma.$executeRawUnsafe(statement);
      } catch (err) {
        const benign = BENIGN_ERROR_PATTERNS.some((p) => p.test(err.message || ''));
        if (!benign) {
          console.warn(`⚠️  ${name}: ${err.message}`);
        }
      }
    }

    await markApplied(prisma, name);
    console.log(`✅ Migration appliquée: ${name}`);
  }
}

module.exports = { run, MIGRATION_ORDER };
