/**
 * Doublons probables de fiches (clients, fournisseurs, boutiques) : rendus visibles, jamais fusionnés.
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-doublons.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';
const { trouverDoublons } = skip ? {} : require('../src/services/sync-doublons');

function poste() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE clients (id INTEGER PRIMARY KEY, nom TEXT, prenom TEXT, telephone TEXT);
    CREATE TABLE comptes_clients (id INTEGER PRIMARY KEY, client_id INTEGER, solde_actuel REAL);
    CREATE TABLE fournisseurs (id INTEGER PRIMARY KEY, nom TEXT, telephone TEXT);
    CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);
  `);
  return { db, $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p) };
}

test('le même client saisi sur deux postes : un groupe, avec les deux fiches et leurs soldes', { skip }, async () => {
  const p = poste();
  p.db.exec(`
    INSERT INTO clients VALUES (10000001, 'Dupont', 'Jean', '699 00 01 11'), (20000001, 'DUPONT ', 'jean', '+699-000-111');
    INSERT INTO comptes_clients VALUES (1, 10000001, -3000), (2, 20000001, -1300);
  `);
  const g = await trouverDoublons(p);
  assert.strictEqual(g.length, 1);
  assert.strictEqual(g[0].table, 'clients');
  assert.strictEqual(g[0].nombre, 2);
  assert.deepStrictEqual(g[0].fiches.map((f) => [f.id, f.solde]), [[10000001, -3000], [20000001, -1300]], 'soldes visibles pour décider');
});

test('prudence : même nom mais téléphones différents, ou sans téléphone : pas un doublon', { skip }, async () => {
  const p = poste();
  p.db.exec(`
    INSERT INTO clients VALUES (1, 'Martin', 'Paul', '690000001'), (2, 'Martin', 'Paul', '690000002');
    INSERT INTO clients VALUES (3, 'Ngono', 'Marie', ''), (4, 'Ngono', 'Marie', NULL);
  `);
  assert.deepStrictEqual(await trouverDoublons(p), []);
});

test('fournisseurs : même nom et même téléphone', { skip }, async () => {
  const p = poste();
  p.db.exec(`INSERT INTO fournisseurs VALUES (1, 'Sodiba', '222 33 44 55'), (2, 'sodiba', '222334455'), (3, 'Sodiba', '111111111');`);
  const g = await trouverDoublons(p);
  assert.strictEqual(g.length, 1);
  assert.deepStrictEqual(g[0].fiches.map((f) => f.id), [1, 2], 'le fournisseur de même nom mais autre téléphone n\'est pas rapproché');
});

test('boutiques : même nom, sans tenir compte des majuscules ni des espaces', { skip }, async () => {
  const p = poste();
  p.db.exec(`INSERT INTO boutiques VALUES (1, 'Annexe'), (2, ' annexe '), (3, 'Principale');`);
  const g = await trouverDoublons(p);
  assert.strictEqual(g.length, 1);
  assert.strictEqual(g[0].table, 'boutiques');
  assert.deepStrictEqual(g[0].fiches.map((f) => f.id), [1, 2]);
});

test('rien en double : liste vide ; table absente : ignorée sans erreur', { skip }, async () => {
  const p = poste();
  p.db.exec(`INSERT INTO boutiques VALUES (1, 'A'), (2, 'B'); INSERT INTO clients VALUES (1, 'X', 'Y', '690000009');`);
  assert.deepStrictEqual(await trouverDoublons(p), []);
  const db = new DatabaseSync(':memory:');
  db.exec('CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);');
  assert.deepStrictEqual(await trouverDoublons({ $queryRawUnsafe: async (sql, ...q) => db.prepare(sql).all(...q) }), []);
});
