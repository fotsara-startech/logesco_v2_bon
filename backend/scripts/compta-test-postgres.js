/**
 * Lance les suites comptables sur PostgreSQL, dans un schéma isolé qui est supprimé à la fin.
 *
 * Usage (l'adresse de la base ne doit JAMAIS être écrite dans un fichier du dépôt) :
 *   COMPTA_TEST_PG_URL="postgresql://utilisateur:motdepasse@hote/base?sslmode=require" node scripts/compta-test-postgres.js
 *
 * Étapes : génère un client Prisma pour Postgres dans node_modules/.compta-pg-client (sans toucher au client SQLite
 * utilisé par le reste du projet), puis exécute les suites avec COMPTA_PRISMA_CLIENT.
 */
const fs = require('node:fs');
const path = require('node:path');
const { execSync, spawnSync } = require('node:child_process');

const url = process.env.COMPTA_TEST_PG_URL;
if (!url) {
  console.error('COMPTA_TEST_PG_URL est requis (adresse PostgreSQL de la base de test).');
  process.exit(2);
}
const racine = path.join(__dirname, '..');
// Connexion directe (sans pgbouncer) : le pooler Neon garde le search_path d'une connexion à l'autre
process.env.COMPTA_TEST_PG_URL = url.replace('-pooler', '');
const sortie = path.join(racine, 'node_modules', '.compta-pg-client');
const schemaTemp = path.join(racine, 'prisma', 'schema.compta-test-pg.prisma');

try {
  const source = fs.readFileSync(path.join(racine, 'prisma', 'schema.postgresql.prisma'), 'utf8');
  const avecSortie = source.replace(/generator client \{([^}]*)\}/, (m, corps) => `generator client {${corps.replace(/\s*$/, '')}\n  output = "../node_modules/.compta-pg-client"\n}`);
  fs.writeFileSync(schemaTemp, avecSortie);
  execSync(`npx prisma generate --schema=${schemaTemp}`, { cwd: racine, stdio: 'inherit', env: { ...process.env, DATABASE_URL: url } });
} finally {
  fs.rmSync(schemaTemp, { force: true });
}

const suites = process.argv.slice(2);
const aLancer = suites.length ? suites : [
  'tests/compta-pg-migration.test.js', 'tests/compta-auto.test.js', 'tests/compta-etats.test.js', 'tests/compta-cloture.test.js', 'tests/compta-ouverture.test.js',
];
const r = spawnSync(process.execPath, ['--test', '--test-concurrency=1', ...aLancer], {
  cwd: racine, stdio: 'inherit', env: { ...process.env, COMPTA_PRISMA_CLIENT: sortie },
});
process.exit(r.status === null ? 1 : r.status);
