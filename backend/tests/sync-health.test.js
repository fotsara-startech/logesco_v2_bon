/**
 * Contrôle d'écart entre ce poste et le cloud.
 *
 * Exécute le VRAI code (sync-health) sur une base SQLite en mémoire avec un faux Neon.
 * Reproduit le cas rencontré chez le client : des produits présents dans le cloud mais jamais reçus,
 * sans aucune trace dans les envois ni dans la file de reprise (donc invisibles du détail de synchronisation).
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-health.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

const { computeDrift } = skip ? {} : require('../src/services/sync-health');

const JOUR = 24 * 60 * 60 * 1000;
const T0 = Date.parse('2026-10-10T10:00:00Z');

function nouvelleBase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT,
      record_id INTEGER, data TEXT, timestamp TEXT DEFAULT CURRENT_TIMESTAMP, synced_at TEXT, status TEXT DEFAULT 'pending', error_message TEXT);
    CREATE TABLE sync_pull_retry (id INTEGER PRIMARY KEY AUTOINCREMENT, table_name TEXT, record_id TEXT, payload TEXT, attempts INTEGER, last_error TEXT);
    CREATE TABLE deleted_records (id INTEGER PRIMARY KEY AUTOINCREMENT, table_name TEXT, record_id INTEGER, deleted_at TEXT);
    CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, reference TEXT);
    CREATE TABLE stock_boutiques (id INTEGER PRIMARY KEY, boutique_id INTEGER, produit_id INTEGER, quantite_disponible INTEGER);
    INSERT INTO boutiques VALUES (1, 'SMART ENERGY SARL');
  `);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux Neon : tables = { nom: [lignes] } ; une table absente lève « relation does not exist » */
function fauxNeon(tables, { panne = false } = {}) {
  return {
    query: async (sql, params) => {
      if (panne) throw new Error('connect ETIMEDOUT');
      let m = sql.match(/FROM "?(\w+)"?(?: WHERE id = \$1)?/);
      const table = m && m[1];
      if (table === 'deleted_records') return { rows: tables.deleted_records || [] };
      if (!tables[table]) throw new Error(`relation "${table}" does not exist`);
      if (/WHERE id = \$1/.test(sql)) return { rows: tables[table].filter((r) => r.id === params[0]).slice(0, 1) };
      const v = sql.match(/"(\w+)" AS v/);
      return { rows: tables[table].map((r) => (v ? { id: r.id, v: r[v[1]] } : { id: r.id })) };
    },
  };
}

const lancer = (prisma, cloud, extra = {}) =>
  computeDrift({ prisma, client: fauxNeon(cloud, extra.neon), tables: ['produits', 'stock_boutiques'], now: T0, ...extra.opts });

test('tout concorde : aucun écart, rien à signaler', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1'), (2, 'POTEAU', 'R2'); INSERT INTO stock_boutiques VALUES (10, 1, 1, 5);`);
  const r = await lancer(p, { produits: [{ id: 1 }, { id: 2 }], stock_boutiques: [{ id: 10, quantite_disponible: 5 }] });
  assert.deepStrictEqual(r.ecarts, []);
  assert.deepStrictEqual(r.resume, { inexpliques: 0, anciens: 0, connus: 0 });
  assert.deepStrictEqual(r.tables.map((t) => [t.table, t.nbLocal, t.nbCloud]), [['produits', 2, 2], ['stock_boutiques', 1, 1]]);
});

test('produits du cloud jamais reçus (cas du client) : détectés, décrits en clair, non expliqués', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1');`);
  const r = await lancer(p, { produits: [{ id: 1 }, { id: 104, nom: 'LUSTRE MODÈLE D6328 P', reference: 'PRD20260097' }, { id: 105, nom: 'LUSTRE MODÈLE D77A', reference: 'PRD20260098' }], stock_boutiques: [] });
  assert.strictEqual(r.resume.inexpliques, 2);
  const e = r.ecarts[0];
  assert.deepStrictEqual([e.table, e.sens, e.cause, e.connue, e.nombre], ['produits', 'a_recevoir', 'inconnue', false, 2]);
  assert.ok(e.exemples.some((x) => x.resume.includes('LUSTRE MODÈLE D6328 P')), 'la ligne est décrite par son nom, lu côté cloud');
});

test('écart déjà connu du système (envoi en attente, file de reprise) : compté comme « connu », pas comme alerte', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`
    INSERT INTO produits VALUES (1, 'LUSTRE', 'R1'), (7, 'NOUVEAU', 'R7');
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, status) VALUES ('a', 'INSERT', 'produits', 7, 'pending');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts) VALUES ('produits', '9', '{}', 3);
  `);
  const r = await lancer(p, { produits: [{ id: 1 }, { id: 9, nom: 'RECU' }], stock_boutiques: [] });
  assert.strictEqual(r.resume.inexpliques, 0);
  assert.strictEqual(r.resume.connus, 2);
  assert.ok(r.ecarts.every((e) => e.connue && e.anciens === 0));
});

test('produit supprimé dans le cloud mais encore présent ici : signalé (cas « coussin de massage »)', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (29, 'COUSSIN DE MASSAGE', 'R29');`);
  const r = await lancer(p, { produits: [], stock_boutiques: [], deleted_records: [{ table_name: 'produits', record_id: 29 }] });
  assert.strictEqual(r.resume.inexpliques, 1);
  assert.strictEqual(r.ecarts[0].cause, 'supprime_cloud');
});

test('stock différent entre ce poste et le cloud : signalé avec les deux valeurs ; ignoré si une modification est en cours', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1'); INSERT INTO stock_boutiques VALUES (10, 1, 1, 52), (11, 1, 2, 3);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, status) VALUES ('s', 'UPDATE', 'stock_boutiques', 11, 'pending');`);
  const r = await lancer(p, { produits: [{ id: 1 }], stock_boutiques: [{ id: 10, quantite_disponible: 104 }, { id: 11, quantite_disponible: 9 }] });
  const valeurs = r.ecarts.filter((e) => e.sens === 'valeur');
  assert.strictEqual(valeurs.length, 1);
  assert.deepStrictEqual([valeurs[0].nombre, valeurs[0].exemples[0].local, valeurs[0].exemples[0].cloud], [1, 52, 104]);
});

test('ancienneté : un écart qui dure plus d\'un jour est « ancien » ; résolu, il disparaît du suivi', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1');`);
  const cloudAvecEcart = { produits: [{ id: 1 }, { id: 104, nom: 'LUSTRE D6328' }], stock_boutiques: [] };

  const j0 = await lancer(p, cloudAvecEcart);
  assert.strictEqual(j0.resume.anciens, 0, 'détecté à l\'instant');
  const j1 = await lancer(p, cloudAvecEcart, { opts: { now: T0 + 25 * 3600 * 1000 } });
  assert.strictEqual(j1.resume.anciens, 1, 'toujours là 25 h plus tard');
  assert.strictEqual(j1.ecarts[0].depuis, new Date(T0).toISOString(), 'première détection conservée');

  p.db.exec(`INSERT INTO produits VALUES (104, 'LUSTRE D6328', 'R104');`);
  const j2 = await lancer(p, cloudAvecEcart, { opts: { now: T0 + 2 * JOUR } });
  assert.deepStrictEqual(j2.ecarts, []);
  assert.strictEqual(p.db.prepare('SELECT COUNT(*) c FROM sync_drift_state').get().c, 0, 'suivi effacé');
});

test('cloud injoignable : l\'erreur remonte, aucun faux rapport « tout va bien »', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1');`);
  await assert.rejects(
    () => lancer(p, {}, { neon: { panne: true }, opts: { isConnectionError: (e) => /ETIMEDOUT/.test(e.message) } }),
    /ETIMEDOUT/
  );
});

test('table absente du cloud (ancienne installation) : ignorée sans bloquer le reste', { skip }, async () => {
  const p = nouvelleBase();
  p.db.exec(`INSERT INTO produits VALUES (1, 'LUSTRE', 'R1');`);
  const r = await lancer(p, { produits: [{ id: 1 }, { id: 2, nom: 'A' }] }); // pas de stock_boutiques côté cloud
  assert.deepStrictEqual(r.tables.map((t) => t.table), ['produits']);
  assert.strictEqual(r.resume.inexpliques, 1);
});
