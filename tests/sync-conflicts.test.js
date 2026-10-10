/**
 * Conflits de synchronisation à trancher (étape 2 du centre de décisions).
 *
 * Exécute le VRAI code (sync-conflicts + sync-service) sur une base SQLite en mémoire avec un faux Neon.
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-conflicts.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

process.env.CLOUD_DB_URL = 'postgresql://fake';
const service = skip ? null : require('../src/services/sync-service');
const { SyncConflictCenter } = skip ? {} : require('../src/services/sync-conflicts');

function nouvelleBase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT,
      record_id INTEGER, data TEXT, timestamp TEXT DEFAULT CURRENT_TIMESTAMP, synced_at TEXT, status TEXT DEFAULT 'pending',
      error_message TEXT, device_id TEXT, user_id INTEGER);
    CREATE TABLE sync_pull_retry (id INTEGER PRIMARY KEY AUTOINCREMENT, table_name TEXT, record_id TEXT, payload TEXT,
      attempts INTEGER DEFAULT 0, last_error TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT);
    CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, reference TEXT UNIQUE, prix_unitaire REAL);
    CREATE TABLE stock_boutiques (id INTEGER PRIMARY KEY, produit_id INTEGER REFERENCES produits(id) ON UPDATE CASCADE, quantite_disponible INTEGER);
    CREATE TABLE clients (id INTEGER PRIMARY KEY, nom TEXT, prenom TEXT);
    CREATE TABLE comptes_clients (id INTEGER PRIMARY KEY, client_id INTEGER UNIQUE REFERENCES clients(id), solde_actuel REAL, limite_credit REAL);
    CREATE TABLE transactions_comptes (id INTEGER PRIMARY KEY, compte_id INTEGER REFERENCES comptes_clients(id) ON UPDATE CASCADE, montant REAL);
    CREATE TABLE ventes (id INTEGER PRIMARY KEY, numero_vente TEXT UNIQUE, montant_total REAL);
    INSERT INTO clients VALUES (4, 'MBARGA', 'Paul');
  `);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux Neon : tables = { nom_table: [lignes] }, répond à SELECT * FROM "t" WHERE "c" = $1 */
function fauxNeon(tables, { panne = false } = {}) {
  return {
    release() {},
    query: async (sql, params) => {
      if (panne) throw new Error('connect ETIMEDOUT');
      const m = sql.match(/FROM "(\w+)" WHERE "(\w+)" = \$1/);
      if (!m) return { rows: [] };
      return { rows: (tables[m[1]] || []).filter((r) => r[m[2]] === params[0]).slice(0, 1) };
    },
  };
}

function centre(prisma, cloud, { panneConnexion = false } = {}) {
  service.localPrisma = prisma;
  service.cloudUrl = 'postgresql://fake';
  service.isCloudAvailable = false;
  service.cloudPool = { connect: async () => { if (panneConnexion) throw new Error('ECONNREFUSED'); return cloud; } };
  const journal = [];
  const c = new SyncConflictCenter({ prisma, syncService: service, journal: async (...a) => { journal.push(a); } });
  c.traces = journal;
  return c;
}

const silencieux = async (fn) => {
  const log = console.log, warn = console.warn;
  console.log = console.warn = () => {};
  try { return await fn(); } finally { console.log = log; console.warn = warn; }
};

const REFUS = "duplicate key value violates unique constraint \"produits_reference_key\"";

function produitEnConflit(prisma) {
  prisma.db.exec(`
    INSERT INTO produits VALUES (150000005, 'LUSTRE LOCAL', 'LUS-1', 5000);
    INSERT INTO stock_boutiques VALUES (150000009, 150000005, 12);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('p1', 'INSERT', 'produits', 150000005, '{"id":150000005,"reference":"LUS-1"}', 'failed', '${REFUS}');
  `);
}
const produitCloud = { id: 7, nom: 'LUSTRE CLOUD', reference: 'LUS-1', prix_unitaire: 6000 };

test('produit : deux fiches à la même référence sont présentées avec les deux options', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  const c = centre(prisma, fauxNeon({ produits: [produitCloud] }));
  const { conflits, total, cloud } = await c.listConflicts();
  assert.strictEqual(total, 1);
  assert.strictEqual(cloud, 'ok');
  const cas = conflits[0];
  assert.strictEqual(cas.key, 'sync:produits:150000005');
  assert.strictEqual(cas.cle.valeur, 'LUS-1');
  assert.deepStrictEqual(cas.options.map((o) => o.id), ['fusionner', 'renommer']);
  assert.ok(cas.local.resume.some((l) => l.includes('LUSTRE LOCAL')));
  assert.ok(cas.cloud.resume.some((l) => l.includes('LUSTRE CLOUD')));
  assert.strictEqual(cas.options[1].valeurSuggeree, 'LUS-1-2');
});

test('produit : « renommer » change la référence locale et renvoie la fiche au cloud', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  const c = centre(prisma, fauxNeon({ produits: [produitCloud] }));
  const r = await silencieux(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'renommer' }));
  assert.strictEqual(r.nouvelle, 'LUS-1-2');
  assert.strictEqual(prisma.db.prepare('SELECT reference FROM produits WHERE id = 150000005').get().reference, 'LUS-1-2');
  const ops = prisma.db.prepare("SELECT status, data FROM operation_log WHERE table_name = 'produits' ORDER BY id").all();
  assert.strictEqual(ops[0].status, 'cancelled', "l'envoi refusé est annulé");
  assert.strictEqual(ops[1].status, 'pending');
  assert.strictEqual(JSON.parse(ops[1].data).reference, 'LUS-1-2', 'le nouvel envoi porte la nouvelle référence');
  assert.strictEqual(c.traces.length, 1, 'la décision est journalisée');
  assert.deepStrictEqual((await c.listConflicts()).conflits, [], 'plus de conflit une fois renommé');
});

test('produit : « renommer » avec une valeur choisie, refus si elle existe déjà', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  const c = centre(prisma, fauxNeon({ produits: [produitCloud, { id: 8, reference: 'PRIS' }] }));
  await assert.rejects(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'renommer', valeur: 'PRIS' }), (e) => e.status === 409);
  await assert.rejects(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'renommer', valeur: 'LUS-1' }), (e) => e.status === 400);
  await silencieux(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'renommer', valeur: 'LUS-LOCAL' }));
  assert.strictEqual(prisma.db.prepare('SELECT reference FROM produits WHERE id = 150000005').get().reference, 'LUS-LOCAL');
});

test('produit : « fusionner » aligne l\'identifiant sur le cloud et repointe le stock', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  prisma.db.exec(`INSERT INTO sync_pull_retry (table_name, record_id, payload, last_error)
    VALUES ('produits', '7', '{"id":7,"reference":"LUS-1"}', 'UNIQUE constraint failed: produits.reference')`);
  const c = centre(prisma, fauxNeon({ produits: [produitCloud] }));
  const r = await silencieux(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'fusionner' }));
  assert.deepStrictEqual([r.ancienId, r.nouveauId], [150000005, 7]);
  const p = prisma.db.prepare('SELECT id, nom, prix_unitaire FROM produits').all();
  assert.deepStrictEqual(p.map((x) => [x.id, x.nom, x.prix_unitaire]), [[7, 'LUSTRE CLOUD', 6000]], 'une seule fiche, valeurs du cloud');
  assert.strictEqual(prisma.db.prepare('SELECT produit_id FROM stock_boutiques').get().produit_id, 7, 'le stock suit la fiche');
  assert.strictEqual(prisma.db.prepare("SELECT COUNT(*) c FROM operation_log WHERE status IN ('pending','failed')").get().c, 0);
  assert.strictEqual(prisma.db.prepare('SELECT COUNT(*) c FROM sync_pull_retry').get().c, 0);
});

function compteEnConflit(prisma) {
  prisma.db.exec(`
    INSERT INTO comptes_clients VALUES (150000001, 4, -5000, 0);
    INSERT INTO transactions_comptes VALUES (150000050, 150000001, -5000);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('c1', 'INSERT', 'comptes_clients', 150000001, '{"id":150000001,"client_id":4,"solde_actuel":-5000}', 'failed',
       'duplicate key value violates unique constraint "comptes_clients_client_id_key"'),
      ('t1', 'INSERT', 'transactions_comptes', 150000050, '{"id":150000050,"compte_id":150000001,"montant":-5000}', 'failed',
       'insert or update on table "transactions_comptes" violates foreign key constraint');
  `);
}
const compteCloud = { id: 3, client_id: 4, solde_actuel: -20000, limite_credit: 0 };

test('compte client en double : soldes additionnés, écritures rattachées, cloud mis à jour', { skip }, async () => {
  const prisma = nouvelleBase();
  compteEnConflit(prisma);
  const c = centre(prisma, fauxNeon({ comptes_clients: [compteCloud] }));

  const { conflits } = await c.listConflicts();
  assert.strictEqual(conflits.length, 1);
  assert.ok(conflits[0].titre.includes('MBARGA Paul'), 'le client est nommé');
  assert.strictEqual(conflits[0].options[0].id, 'additionner');
  assert.ok(conflits[0].options[0].consequence.includes('25 000'), 'le résultat chiffré est annoncé');

  const r = await silencieux(() => c.apply({ caseKey: conflits[0].key, optionId: 'additionner' }));
  assert.strictEqual(r.soldeFinal, -25000);
  const compte = prisma.db.prepare('SELECT id, solde_actuel FROM comptes_clients').all();
  assert.deepStrictEqual(compte.map((x) => [x.id, x.solde_actuel]), [[3, -25000]]);
  assert.strictEqual(prisma.db.prepare('SELECT compte_id FROM transactions_comptes').get().compte_id, 3, 'écriture rattachée au compte du cloud');

  const ops = prisma.db.prepare("SELECT table_name, operation_type, status, data FROM operation_log WHERE status IN ('pending','failed') ORDER BY id").all();
  const maj = ops.find((o) => o.table_name === 'comptes_clients');
  assert.strictEqual(JSON.parse(maj.data).solde_actuel, -25000, 'le cloud recevra le solde cumulé');
  const tx = ops.find((o) => o.table_name === 'transactions_comptes');
  assert.strictEqual(tx.status, 'pending', "l'écriture refusée est remise en attente");
  assert.strictEqual(JSON.parse(tx.data).compte_id, 3, "avec l'identifiant du compte du cloud");
});

test('compte client en double : garder le solde du cloud ou celui du poste', { skip }, async () => {
  for (const [option, attendu, renvoye] of [['garder_cloud', -20000, false], ['garder_local', -5000, true]]) {
    const prisma = nouvelleBase();
    compteEnConflit(prisma);
    const c = centre(prisma, fauxNeon({ comptes_clients: [compteCloud] }));
    await silencieux(() => c.apply({ caseKey: 'sync:comptes_clients:150000001', optionId: option }));
    assert.strictEqual(prisma.db.prepare('SELECT solde_actuel FROM comptes_clients').get().solde_actuel, attendu, option);
    const aRenvoyer = prisma.db.prepare("SELECT COUNT(*) c FROM operation_log WHERE table_name = 'comptes_clients' AND status = 'pending'").get().c;
    assert.strictEqual(aRenvoyer > 0, renvoye, `${option} : envoi du solde au cloud`);
  }
});

test('numéro de vente en double : renommer le numéro local', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`
    INSERT INTO ventes VALUES (150000100, 'VTE-20261001-0001', 15000);
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status, error_message) VALUES
      ('v1', 'INSERT', 'ventes', 150000100, '{"id":150000100}', 'failed', 'duplicate key value violates unique constraint "ventes_numero_vente_key"');
  `);
  const c = centre(prisma, fauxNeon({ ventes: [{ id: 100, numero_vente: 'VTE-20261001-0001', montant_total: 9000 }] }));
  const { conflits } = await c.listConflicts();
  assert.deepStrictEqual(conflits[0].options.map((o) => o.id), ['renommer'], 'une vente ne se « fusionne » pas');
  assert.strictEqual(conflits[0].options[0].recommandee, true);
  await silencieux(() => c.apply({ caseKey: conflits[0].key, optionId: 'renommer' }));
  assert.strictEqual(prisma.db.prepare('SELECT numero_vente FROM ventes').get().numero_vente, 'VTE-20261001-0001-2');
  // le conflit est résolu : le rejouer est refusé proprement
  await assert.rejects(() => c.apply({ caseKey: conflits[0].key, optionId: 'renommer' }), (e) => e.status === 409);
});

test('rien à décider quand le cloud n\'a pas de fiche concurrente, ou la même fiche', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  assert.strictEqual((await centre(prisma, fauxNeon({ produits: [] })).listConflicts()).total, 0, 'le cloud ne connaît pas la référence');
  assert.strictEqual((await centre(prisma, fauxNeon({ produits: [{ ...produitCloud, id: 150000005 }] })).listConflicts()).total, 0, 'même identifiant : autre cause');
});

test('cloud injoignable : liste vide signalée, application refusée sans rien modifier', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  const c = centre(prisma, fauxNeon({}), { panneConnexion: true });
  const l = await c.listConflicts();
  assert.deepStrictEqual([l.total, l.cloud], [0, 'indisponible']);
  await assert.rejects(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'renommer' }), (e) => e.status === 503);
  assert.strictEqual(prisma.db.prepare('SELECT reference FROM produits').get().reference, 'LUS-1');
});

test('cas inconnu, option inconnue, fiche disparue', { skip }, async () => {
  const prisma = nouvelleBase();
  produitEnConflit(prisma);
  const c = centre(prisma, fauxNeon({ produits: [produitCloud] }));
  await assert.rejects(() => c.apply({ caseKey: 'n-importe-quoi', optionId: 'renommer' }), (e) => e.status === 404);
  await assert.rejects(() => c.apply({ caseKey: 'sync:produits:999', optionId: 'renommer' }), (e) => e.status === 409);
  await assert.rejects(() => c.apply({ caseKey: 'sync:produits:150000005', optionId: 'magie' }), (e) => e.status === 400);
});
