/**
 * Interblocages de doublons entre un poste et Neon (même fiche sous deux identifiants).
 *
 * Exécute le VRAI code du service de synchronisation sur une petite base SQLite en mémoire,
 * avec un faux Neon. Reproduit les deux cas rencontrés chez le client :
 *   - ligne de stock boutique (boutique 1, produit 3) : local 150000001 / cloud 100000003 ;
 *   - rôle « admin » créé sur la 2e machine alors que Neon le possède déjà.
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-reconcile.test.js
 * (le module node:sqlite est expérimental sous Node 22 : sans l'option, les tests sont ignorés)
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

process.env.CLOUD_DB_URL = 'postgresql://fake';
const service = skip ? null : require('../src/services/sync-service');
const { getSyncDetails } = skip ? {} : require('../src/services/sync-detail');

/** Petite base locale + adaptateur ($queryRawUnsafe / $executeRawUnsafe) attendu par le service. */
function nouvelleBase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT,
      record_id INTEGER, data TEXT, timestamp TEXT DEFAULT CURRENT_TIMESTAMP, synced_at TEXT, status TEXT DEFAULT 'pending',
      error_message TEXT, device_id TEXT, user_id INTEGER);
    CREATE TABLE sync_pull_retry (id INTEGER PRIMARY KEY AUTOINCREMENT, table_name TEXT, record_id TEXT, payload TEXT,
      attempts INTEGER DEFAULT 0, last_error TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT);
    CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, reference TEXT);
    CREATE TABLE stock_boutiques (id INTEGER PRIMARY KEY, boutique_id INTEGER, produit_id INTEGER, quantite_disponible INTEGER,
      quantite_reservee INTEGER DEFAULT 0, derniere_maj INTEGER, date_modification TEXT, UNIQUE (boutique_id, produit_id));
    CREATE TABLE user_roles (id INTEGER PRIMARY KEY, nom TEXT UNIQUE, display_name TEXT, is_admin INTEGER, privileges TEXT);
    CREATE TABLE utilisateurs (id INTEGER PRIMARY KEY, nom_utilisateur TEXT, role_id INTEGER REFERENCES user_roles(id) ON UPDATE CASCADE);
    INSERT INTO boutiques VALUES (1, 'SMART ENERGY SARL');
    INSERT INTO produits VALUES (3, 'LAMPADAIRE SOLAIRE RSK 120', 'PRD1');
  `);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux Neon : renvoie la ligne donnée pour un SELECT sur la table donnée. */
function fauxNeon(tables) {
  const requetes = [];
  return {
    requetes,
    client: {
      release() {},
      query: async (sql) => {
        requetes.push(sql);
        const m = sql.match(/FROM "(\w+)" WHERE/);
        return { rows: m && /^\s*SELECT \*/.test(sql) && tables[m[1]] ? [tables[m[1]]] : [] };
      },
    },
  };
}

function preparer(prisma) {
  service.localPrisma = prisma;
  service.cloudUrl = 'postgresql://fake';
  service.isCloudAvailable = false;
}

const silencieux = async (fn) => {
  const log = console.log, warn = console.warn;
  console.log = console.warn = () => {};
  try { return await fn(); } finally { console.log = log; console.warn = warn; }
};

test('stock boutique en doublon (cas du client SMART ENERGY) : id aligné sur le cloud, envois annulés', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO stock_boutiques VALUES (150000001, 1, 3, 52, 0, 1791017711713, NULL);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('a', 'UPDATE', 'stock_boutiques', 150000001, '{"id":150000001,"boutique_id":1,"produit_id":3,"quantite_disponible":52}', 'failed', 'duplicate key value violates unique constraint "stock_boutiques_boutique_id_produit_id_key"'),
      ('b', 'INSERT', 'stock_boutiques', 150000001, '{"id":150000001,"boutique_id":1,"produit_id":3,"quantite_disponible":52}', 'failed', 'duplicate key value violates unique constraint "stock_boutiques_boutique_id_produit_id_key"');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error) VALUES
      ('stock_boutiques', '100000003', '{"id":100000003,"boutique_id":1,"produit_id":3}', 19, 'UNIQUE constraint failed: stock_boutiques.boutique_id, stock_boutiques.produit_id');
  `);
  preparer(prisma);

  // Avant la fusion : 3 éléments, décrits en clair
  const avant = await getSyncDetails(prisma);
  assert.strictEqual(avant.length, 3);
  assert.strictEqual(avant[0].summary, 'LAMPADAIRE SOLAIRE RSK 120 — boutique SMART ENERGY SARL — quantité 52');

  const neon = fauxNeon({ stock_boutiques: { id: 100000003, boutique_id: 1, produit_id: 3, quantite_disponible: 52, quantite_reservee: 0, derniere_maj: new Date('2026-10-02T15:02:35.813Z'), date_modification: null } });
  const fusions = await silencieux(() => service._reconcileCompositeKeyConflicts(neon.client));

  assert.strictEqual(fusions, 1);
  const lignes = prisma.db.prepare('SELECT id, quantite_disponible FROM stock_boutiques').all();
  assert.deepStrictEqual(lignes.map((l) => [l.id, l.quantite_disponible]), [[100000003, 52]], 'une seule ligne, sous l\'identifiant du cloud');
  assert.strictEqual(prisma.db.prepare("SELECT COUNT(*) c FROM operation_log WHERE status IN ('pending','failed')").get().c, 0);
  assert.strictEqual(prisma.db.prepare('SELECT COUNT(*) c FROM sync_pull_retry').get().c, 0);
  assert.deepStrictEqual(await getSyncDetails(prisma), [], 'une fois résolu, rien n\'apparaît plus dans le détail');
});

test('rôle "admin" en doublon (2e machine) : aligné sur le cloud, utilisateur repointé', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO user_roles VALUES (150000020, 'admin', 'Admin local', 1, '{}');
    INSERT INTO utilisateurs VALUES (1, 'fotso', 150000020);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('r', 'INSERT', 'user_roles', 150000020, '{"id":150000020,"nom":"admin"}', 'failed', 'duplicate key value violates unique constraint "user_roles_nom_key"');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error) VALUES
      ('user_roles', '2', '{"id":2,"nom":"admin"}', 19, 'UNIQUE constraint failed: user_roles.nom');
  `);
  preparer(prisma);
  assert.strictEqual((await getSyncDetails(prisma)).length, 2, 'avant : l\'envoi refusé et la ligne reçue non appliquée');

  const neon = fauxNeon({ user_roles: { id: 2, nom: 'admin', display_name: 'Admin cloud', is_admin: 1, privileges: '{}' } });
  assert.strictEqual(await silencieux(() => service._reconcileCompositeKeyConflicts(neon.client)), 1);

  assert.deepStrictEqual(prisma.db.prepare("SELECT id, display_name FROM user_roles WHERE nom = 'admin'").all().map((r) => [r.id, r.display_name]), [[2, 'Admin cloud']]);
  assert.strictEqual(prisma.db.prepare('SELECT role_id FROM utilisateurs WHERE id = 1').get().role_id, 2, 'l\'utilisateur suit le rôle du cloud');
  assert.deepStrictEqual(await getSyncDetails(prisma), [], 'une fois résolu, rien n\'apparaît plus dans le détail');
});

test('quantité locale plus récente et différente : conservée et renvoyée au cloud', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO stock_boutiques VALUES (150000001, 1, 3, 40, 0, ${Date.parse('2026-10-05T10:00:00Z')}, NULL);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('a', 'INSERT', 'stock_boutiques', 150000001, '{"id":150000001,"boutique_id":1,"produit_id":3,"quantite_disponible":40}', 'failed', 'duplicate key value violates unique constraint "stock_boutiques_boutique_id_produit_id_key"');
  `);
  preparer(prisma);
  const neon = fauxNeon({ stock_boutiques: { id: 100000003, boutique_id: 1, produit_id: 3, quantite_disponible: 52, quantite_reservee: 0, derniere_maj: new Date('2026-10-02T15:02:35.813Z'), date_modification: null } });
  await silencieux(() => service._reconcileCompositeKeyConflicts(neon.client));

  assert.deepStrictEqual(prisma.db.prepare('SELECT id, quantite_disponible FROM stock_boutiques').all().map((l) => [l.id, l.quantite_disponible]), [[100000003, 40]]);
  const aRenvoyer = prisma.db.prepare("SELECT record_id, data FROM operation_log WHERE status = 'pending'").all();
  assert.strictEqual(aRenvoyer.length, 1);
  assert.strictEqual(aRenvoyer[0].record_id, 100000003);
  assert.strictEqual(JSON.parse(aRenvoyer[0].data).quantite_disponible, 40);
});

test('aucun doublon ni opération sensible en attente : aucune requête vers Neon', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  const neon = fauxNeon({});
  assert.strictEqual(await silencieux(() => service._reconcileCompositeKeyConflicts(neon.client)), 0);
  assert.strictEqual(neon.requetes.length, 0);
});

test('ligne reçue déjà présente localement (résolue par un autre chemin) : plus listée', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO user_roles VALUES (2, 'admin', 'Admin', 1, '{}');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error) VALUES
      ('user_roles', '2', '{"id":2,"nom":"admin"}', 25, 'UNIQUE constraint failed: user_roles.nom');
  `);
  assert.deepStrictEqual(await getSyncDetails(prisma), []);
});

test('ligne reçue réellement bloquée : listée avec sa cause', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO user_roles VALUES (150000020, 'admin', 'Admin local', 1, '{}');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error) VALUES
      ('user_roles', '2', '{"id":2,"nom":"admin"}', 19, 'UNIQUE constraint failed: user_roles.nom');
  `);
  const items = await getSyncDetails(prisma);
  assert.strictEqual(items.length, 1);
  assert.strictEqual(items[0].source, 'reception');
  assert.strictEqual(items[0].error.code, 'doublon');
  assert.match(items[0].error.action, /automatiquement/);
});
