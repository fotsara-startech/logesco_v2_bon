/**
 * Données de base du premier poste envoyées à un cloud NEUF (et seulement à un cloud neuf).
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-graine.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';
const graine = skip ? null : require('../src/services/sync-graine');

function nouveauPoste({ roles = 1, boutiques = 1, assignations = 0 } = {}) {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE user_roles (id INTEGER PRIMARY KEY, nom TEXT, colonne_locale TEXT);
    CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE utilisateurs (id INTEGER PRIMARY KEY, nom_utilisateur TEXT);
    CREATE TABLE cash_registers (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE parametres_entreprise (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE user_boutique_assignments (id INTEGER PRIMARY KEY, user_id INTEGER);
  `);
  for (let i = 1; i <= roles; i++) db.exec(`INSERT INTO user_roles VALUES (${i}, 'ADMIN${i}', 'x')`);
  for (let i = 1; i <= boutiques; i++) db.exec(`INSERT INTO boutiques VALUES (${i}, 'Boutique ${i}')`);
  db.exec(`INSERT INTO utilisateurs VALUES (1, 'admin'); INSERT INTO cash_registers VALUES (1, 'Caisse 1'); INSERT INTO parametres_entreprise VALUES (1, 'Ma société')`);
  for (let i = 1; i <= assignations; i++) db.exec(`INSERT INTO user_boutique_assignments VALUES (${i}, 1)`);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux cloud : lignes par table ; colonne « colonne_locale » absente du cloud */
function fauxCloud(lignesParTable = {}, { coupure = false } = {}) {
  return {
    requetes: 0,
    async query(sql, params) {
      this.requetes++;
      if (coupure) { const e = new Error('connect ETIMEDOUT'); e.code = 'ETIMEDOUT'; throw e; }
      const m = sql.match(/COUNT\(\*\)::int AS n FROM "(\w+)"/);
      if (m) return { rows: [{ n: (lignesParTable[m[1]] || []).length }] };
      if (/information_schema/.test(sql)) return { rows: ['id', 'nom', 'nom_utilisateur', 'user_id'].map((c) => ({ column_name: c })) };
      throw new Error(`requête non prévue : ${sql.slice(0, 80)}`);
    },
  };
}

const enregistreur = () => { const ops = []; return { ops, enqueue: async (table, op, data) => { ops.push([table, op, data]); } }; };

test('cloud neuf : toute la graine locale est journalisée (INSERT), colonnes locales retirées', { skip }, async () => {
  const prisma = nouveauPoste();
  const { ops, enqueue } = enregistreur();
  const r = await graine.pousserGraineSiCloudVide({ prisma, client: fauxCloud(), enqueue });
  const tables = ops.map((o) => o[0]);
  assert.deepStrictEqual(tables.sort(), ['boutiques', 'cash_registers', 'parametres_entreprise', 'user_roles', 'utilisateurs'].sort());
  assert.ok(ops.every((o) => o[1] === 'INSERT'));
  const role = ops.find((o) => o[0] === 'user_roles')[2];
  assert.deepStrictEqual(role, { id: 1, nom: 'ADMIN1' }, 'la colonne purement locale n\'est pas envoyée');
  assert.strictEqual(r.envoyees, 5);
});

test('cloud neuf : l\'envoi n\'est fait qu\'une seule fois', { skip }, async () => {
  const prisma = nouveauPoste();
  const premier = enregistreur();
  await graine.pousserGraineSiCloudVide({ prisma, client: fauxCloud(), enqueue: premier.enqueue });
  const second = enregistreur();
  await graine.pousserGraineSiCloudVide({ prisma, client: fauxCloud(), enqueue: second.enqueue });
  assert.strictEqual(premier.ops.length, 5);
  assert.strictEqual(second.ops.length, 0, 'rien de renvoyé au cycle suivant');
});

test('cloud DÉJÀ rempli (client établi) : rien n\'est envoyé, et on n\'y revient pas', { skip }, async () => {
  const prisma = nouveauPoste();
  const cloud = fauxCloud({ user_roles: [{ id: 1 }], boutiques: [{ id: 1 }], utilisateurs: [{ id: 1 }], cash_registers: [{ id: 1 }], parametres_entreprise: [{ id: 1 }] });
  const { ops, enqueue } = enregistreur();
  const r = await graine.pousserGraineSiCloudVide({ prisma, client: cloud, enqueue });
  assert.strictEqual(ops.length, 0, 'aucune ligne locale ne doit écraser celles du cloud');
  assert.strictEqual(r.tables.user_roles, 'cloud_non_vide');
  assert.strictEqual(await graine.resteAFaire(prisma), false, 'rien ne reste à examiner : plus aucune connexion au cloud par cycle');
});

test('table partiellement remplie dans le cloud : seules les tables VIDES sont envoyées', { skip }, async () => {
  const prisma = nouveauPoste();
  const cloud = fauxCloud({ user_roles: [{ id: 1 }], utilisateurs: [{ id: 1 }] }); // boutique, caisse, paramètres manquent
  const { ops, enqueue } = enregistreur();
  await graine.pousserGraineSiCloudVide({ prisma, client: cloud, enqueue });
  assert.deepStrictEqual(ops.map((o) => o[0]).sort(), ['boutiques', 'cash_registers', 'parametres_entreprise']);
});

test('coupure réseau : erreur remontée, rien n\'est marqué (le cycle suivant reprendra)', { skip }, async () => {
  const prisma = nouveauPoste();
  const { ops, enqueue } = enregistreur();
  await assert.rejects(() => graine.pousserGraineSiCloudVide({ prisma, client: fauxCloud({}, { coupure: true }), enqueue }), /ETIMEDOUT/);
  assert.strictEqual(ops.length, 0);
  assert.strictEqual(await graine.resteAFaire(prisma), true, 'tout reste à faire');
  const apres = enregistreur();
  await graine.pousserGraineSiCloudVide({ prisma, client: fauxCloud(), enqueue: apres.enqueue });
  assert.strictEqual(apres.ops.length, 5, 'repris au cycle suivant');
});

test('poste sans aucune donnée locale : rien à faire, aucune connexion nécessaire', { skip }, async () => {
  const db = new DatabaseSync(':memory:');
  db.exec('CREATE TABLE user_roles (id INTEGER PRIMARY KEY)');
  const prisma = { $queryRawUnsafe: async (s, ...p) => db.prepare(s).all(...p), $executeRawUnsafe: async (s, ...p) => Number(db.prepare(s).run(...p).changes) };
  assert.strictEqual(await graine.resteAFaire(prisma), false);
});
