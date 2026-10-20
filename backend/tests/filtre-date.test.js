/**
 * Filtre de date fiable sur une VRAIE base SQLite où les dates sont en texte et en nombre.
 *
 * Exécution :  node --test tests/filtre-date.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');
const { PrismaClient } = require('@prisma/client');
const { appliquerFiltreDate, clauseDate } = require('../src/utils/filtre-date');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'filtre-date-'));
const url = `file:${path.join(dossier, 'essai.db').split(path.sep).join('/')}`;
let prisma;

const T = (a, m, j, h = 10, mi = 0, s = 0) => new Date(a, m - 1, j, h, mi, s);
const SPEC = { table: 'mouvements_stock', colonne: 'date_mouvement', champ: 'dateMouvement' };

/** Cinq jours d'octobre, dans trois formats différents */
const LIGNES = [
  ['A', T(2026, 10, 1), 'iso'],
  ['B', T(2026, 10, 10), 'sql'],
  ['C', T(2026, 10, 15), 'ms'],
  ['D', T(2026, 10, 20), 'iso'],
  ['E', T(2026, 10, 25), 'ms'],
];
const nomDe = {};

test.before(async () => {
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    cwd: path.join(__dirname, '..'),
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'ignore',
  });
  prisma = new PrismaClient({ datasources: { db: { url } } });
  await prisma.$executeRawUnsafe(`INSERT INTO produits (id, reference, nom, prix_unitaire, date_modification) VALUES (1, 'R1', 'P', 1, 0)`);
  for (const [nom, date, forme] of LIGNES) {
    const v =
      forme === 'ms' ? date.getTime() : forme === 'iso' ? date.toISOString() : date.toISOString().replace('T', ' ').replace(/\.\d+Z$/, '');
    await prisma.$executeRawUnsafe(
      `INSERT INTO mouvements_stock (produit_id, type_mouvement, changement_quantite, date_mouvement) VALUES (1, 'entree', 1, ?)`,
      v,
    );
    const r = await prisma.$queryRawUnsafe('SELECT last_insert_rowid() AS id');
    nomDe[Number(r[0].id)] = nom;
  }
});

test.after(async () => {
  if (prisma) await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

const noms = async (bornes, base = {}) => {
  const where = { ...base };
  await appliquerFiltreDate(prisma, where, SPEC, bornes);
  const lignes = await prisma.mouvementStock.findMany({ where, select: { id: true } });
  return lignes.map((l) => nomDe[l.id]).sort().join('');
};

test('PREUVE DU DEFAUT : le filtre brut de l ORM renvoie les lignes en texte pour "date >= 2030"', async () => {
  const apres2030 = await prisma.mouvementStock.count({ where: { dateMouvement: { gte: new Date(2030, 0, 1) } } });
  assert.strictEqual(apres2030, 3, 'les 3 lignes en texte passent a tort');
  const avantFin = await prisma.mouvementStock.count({ where: { dateMouvement: { lte: new Date(2026, 9, 30) } } });
  assert.strictEqual(avantFin, 2, 'seules les lignes en nombre passent : les 3 lignes en texte sont perdues');
});

test('a partir d une date', async () => assert.strictEqual(await noms({ gte: T(2026, 10, 15, 0) }), 'CDE'));
test('jusqu a une date', async () => assert.strictEqual(await noms({ lte: T(2026, 10, 15, 23) }), 'ABC'));
test('entre deux dates (le cas qui ne renvoyait rien)', async () =>
  assert.strictEqual(await noms({ gte: T(2026, 10, 5, 0), lte: T(2026, 10, 22, 0) }), 'BCD'));
test('aucune borne : pas de filtre', async () => assert.strictEqual(await noms({}), 'ABCDE'));
test('hors periode : rien', async () => assert.strictEqual(await noms({ gte: T(2030, 1, 1) }), ''));
test('bornes strictes gt / lt', async () => assert.strictEqual(await noms({ gt: T(2026, 10, 15), lt: T(2026, 10, 25) }), 'D'));

test('limites exactes : gte inclut l instant exact, gt l exclut', async () => {
  const exact = T(2026, 10, 20); // ligne D, texte ISO
  assert.strictEqual(await noms({ gte: exact, lte: exact }), 'D');
  assert.strictEqual(await noms({ gt: exact, lte: exact }), '');
});

test('se combine avec les autres conditions du filtre et avec un AND deja present', async () => {
  assert.strictEqual(await noms({ gte: T(2026, 10, 1, 0) }, { typeMouvement: 'entree' }), 'ABCDE');
  assert.strictEqual(await noms({ gte: T(2026, 10, 1, 0) }, { typeMouvement: 'sortie' }), '');
  assert.strictEqual(await noms({ gte: T(2026, 10, 12, 0) }, { AND: [{ typeMouvement: 'entree' }] }), 'CDE');
});

test('date invalide : ignoree', async () => assert.strictEqual(await clauseDate(prisma, SPEC, { gte: 'pas-une-date' }), null));

test('base qui n est pas SQLite : le filtre d origine est conserve', async () => {
  const faux = {
    $queryRawUnsafe: async () => {
      throw new Error('pas sqlite');
    },
  };
  const c = await clauseDate(faux, SPEC, { gte: T(2026, 10, 1) });
  assert.ok(c.dateMouvement && c.dateMouvement.gte instanceof Date);
});
