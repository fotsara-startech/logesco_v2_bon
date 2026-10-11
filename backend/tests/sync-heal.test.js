/**
 * Les deux défauts à l'origine des lignes jamais reçues :
 *
 *  1. Lignes jamais reçues : le curseur de réception est une date de modification ; une ligne poussée tard par un poste
 *     resté hors ligne (date d'origine plus ancienne que le curseur), ou sans date, n'est jamais ramenée. Une ligne
 *     laissée de côté à cause d'une écriture locale en attente était aussi perdue (le curseur avançait au-delà).
 *     → rattrapage par identifiant (_recupererLignes / _recupererManquants) et mémorisation des lignes protégées.
 *
 *  2. File de reprise : au bout de 20 échecs une ligne n'était plus JAMAIS rejouée, même quand son parent arrivait.
 *     → plus d'abandon définitif : les lignes en pause sont rejouées une fois par heure (ou après un rattrapage),
 *       et une ligne périmée ne peut pas écraser une version plus récente.
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-heal.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

process.env.CLOUD_DB_URL = 'postgresql://fake';
const service = skip ? null : require('../src/services/sync-service');

function nouvelleBase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys = ON;
    CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT,
      record_id INTEGER, data TEXT, timestamp TEXT DEFAULT CURRENT_TIMESTAMP, status TEXT DEFAULT 'pending');
    CREATE TABLE sync_pull_retry (id INTEGER PRIMARY KEY AUTOINCREMENT, table_name TEXT, record_id TEXT, payload TEXT,
      attempts INTEGER DEFAULT 0, last_error TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT,
      UNIQUE (table_name, record_id));
    CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, reference TEXT, date_modification TEXT);
    CREATE TABLE stock_boutiques (id INTEGER PRIMARY KEY, produit_id INTEGER NOT NULL REFERENCES produits(id), quantite_disponible INTEGER);
  `);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux Neon : tables = { nom: [lignes] } ; répond à SELECT * FROM "t" WHERE id = ANY($1::bigint[]) */
function fauxNeon(tables) {
  const requetes = [];
  return {
    requetes,
    query: async (sql, params) => {
      requetes.push(sql);
      const m = sql.match(/FROM "(\w+)" WHERE id = ANY/);
      if (!m) return { rows: [] };
      return { rows: (tables[m[1]] || []).filter((r) => params[0].includes(r.id)).map((r) => ({ ...r })) };
    },
  };
}

function preparer(prisma) {
  service.localPrisma = prisma;
  service.cloudUrl = 'postgresql://fake';
  service.isCloudAvailable = false;
  service._protegees = new Map();
}

const silencieux = async (fn) => {
  const log = console.log, warn = console.warn;
  console.log = console.warn = () => {};
  try { return await fn(); } finally { console.log = log; console.warn = warn; }
};

const ligne = (prisma, table, id) => prisma.db.prepare(`SELECT * FROM ${table} WHERE id = ?`).get(id);

// ── Défaut 2 : file de reprise ────────────────────────────────────────────────

test('file de reprise : une ligne en pause (20 échecs) est rejouée au bout d\'une heure, et répare dès que le parent est là', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  // le parent (produit 1) est arrivé entre-temps ; la ligne de stock attendait depuis 20+ essais, dernier essai il y a 2 h
  prisma.db.exec(`
    INSERT INTO produits VALUES (1, 'LUSTRE', 'R1', '2026-10-01T00:00:00Z');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at)
    VALUES ('stock_boutiques', '10', '{"id":10,"produit_id":1,"quantite_disponible":5}', 25, 'FOREIGN KEY constraint failed', datetime('now', '-2 hours'));
  `);
  await silencieux(() => service._processPullRetryQueue());
  assert.deepStrictEqual(ligne(prisma, 'stock_boutiques', 10).quantite_disponible, 5, 'ligne enfin appliquée');
  assert.strictEqual(prisma.db.prepare('SELECT COUNT(*) c FROM sync_pull_retry').get().c, 0, 'et sortie de la file');
});

test('file de reprise : une ligne en pause rejouée trop récemment attend, sauf après un rattrapage', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  prisma.db.exec(`
    INSERT INTO produits VALUES (1, 'LUSTRE', 'R1', '2026-10-01T00:00:00Z');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at)
    VALUES ('stock_boutiques', '10', '{"id":10,"produit_id":1,"quantite_disponible":5}', 25, 'x', datetime('now', '-5 minutes'));
  `);
  await silencieux(() => service._processPullRetryQueue());
  assert.strictEqual(ligne(prisma, 'stock_boutiques', 10), undefined, 'en pause : pas rejouée à chaque cycle');
  assert.strictEqual(prisma.db.prepare('SELECT COUNT(*) c FROM sync_pull_retry').get().c, 1, 'mais conservée');

  await silencieux(() => service._processPullRetryQueue({ ignorerDelai: true }));
  assert.strictEqual(ligne(prisma, 'stock_boutiques', 10).quantite_disponible, 5, 'rejouée après un rattrapage');
});

test('file de reprise : une ligne encore en échec reste (jamais abandonnée) et son compteur continue', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  // le produit 99 n'existe toujours pas : la ligne échoue encore, mais elle n'est pas supprimée
  prisma.db.exec(`INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at)
    VALUES ('stock_boutiques', '11', '{"id":11,"produit_id":99,"quantite_disponible":1}', 40, 'x', datetime('now', '-3 hours'))`);
  await silencieux(() => service._processPullRetryQueue());
  const r = prisma.db.prepare('SELECT attempts, last_error FROM sync_pull_retry').get();
  assert.strictEqual(r.attempts, 41);
  assert.match(r.last_error, /FOREIGN KEY/);
});

test('file de reprise : une ligne périmée n\'écrase pas une version plus récente déjà reçue ; une plus récente s\'applique', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  prisma.db.exec(`
    INSERT INTO produits VALUES (1, 'NOM RECENT', 'R1', '2026-10-10T10:00:00Z'), (2, 'ANCIEN NOM', 'R2', '2026-09-01T00:00:00Z');
    INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at) VALUES
      ('produits', '1', '{"id":1,"nom":"NOM PERIME","reference":"R1","date_modification":"2026-09-01T00:00:00Z"}', 3, 'x', datetime('now', '-1 day')),
      ('produits', '2', '{"id":2,"nom":"NOM A JOUR","reference":"R2","date_modification":"2026-10-05T00:00:00Z"}', 3, 'x', datetime('now', '-1 day'));
  `);
  await silencieux(() => service._processPullRetryQueue());
  assert.strictEqual(ligne(prisma, 'produits', 1).nom, 'NOM RECENT', 'la version locale plus récente est conservée');
  assert.strictEqual(ligne(prisma, 'produits', 2).nom, 'NOM A JOUR', 'la version distante plus récente est appliquée');
  assert.strictEqual(prisma.db.prepare('SELECT COUNT(*) c FROM sync_pull_retry').get().c, 0, 'les deux sortent de la file');
});

// ── Défaut 1 : lignes jamais reçues ───────────────────────────────────────────

test('rattrapage : des produits du cloud jamais reçus (date ancienne ou absente) sont récupérés par identifiant', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  prisma.db.exec(`INSERT INTO produits VALUES (1, 'DEJA LA', 'R1', '2026-10-01T00:00:00Z')`);
  const neon = fauxNeon({
    produits: [
      { id: 104, nom: 'LUSTRE D6328 P', reference: 'PRD20260097', date_modification: '2026-09-24T10:00:00Z' }, // plus ancienne que le curseur
      { id: 105, nom: 'LUSTRE D77A', reference: 'PRD20260098', date_modification: null }, // sans date : jamais sélectionnée par le curseur
    ],
  });
  const r = await silencieux(() => service._recupererLignes(neon, 'produits', [104, 105]));
  assert.strictEqual(r.applied, 2);
  assert.strictEqual(ligne(prisma, 'produits', 104).nom, 'LUSTRE D6328 P');
  assert.strictEqual(ligne(prisma, 'produits', 105).nom, 'LUSTRE D77A');
});

test('rattrapage : respecte les écritures locales en attente et les suppressions en cours', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  prisma.db.exec(`
    INSERT INTO produits VALUES (106, 'LOCAL EN COURS', 'R106', '2026-10-10T00:00:00Z');
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, status) VALUES
      ('a', 'UPDATE', 'produits', 106, 'pending'),
      ('b', 'DELETE', 'produits', 107, 'pending');
  `);
  const neon = fauxNeon({
    produits: [
      { id: 106, nom: 'VERSION CLOUD', reference: 'R106', date_modification: '2026-09-01T00:00:00Z' },
      { id: 107, nom: 'SUPPRIME ICI', reference: 'R107', date_modification: null },
      { id: 108, nom: 'NOUVEAU', reference: 'R108', date_modification: null },
    ],
  });
  const r = await silencieux(() => service._recupererLignes(neon, 'produits', [106, 107, 108]));
  assert.deepStrictEqual([r.applied, r.protegees], [1, 1]);
  assert.strictEqual(ligne(prisma, 'produits', 106).nom, 'LOCAL EN COURS', "l'écriture locale en attente n'est pas écrasée");
  assert.strictEqual(ligne(prisma, 'produits', 107), undefined, 'une suppression en cours ne ressuscite pas la ligne');
  assert.strictEqual(ligne(prisma, 'produits', 108).nom, 'NOUVEAU');
});

test('ligne laissée de côté (écriture locale en attente) : redemandée au cloud dès que l\'envoi est parti', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  prisma.db.exec(`
    INSERT INTO produits VALUES (106, 'LOCAL', 'R106', '2026-10-10T00:00:00Z');
    INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, status) VALUES ('a', 'UPDATE', 'produits', 106, 'pending');
  `);
  const cloud = { produits: [{ id: 106, nom: 'VERSION CLOUD FINALE', reference: 'R106', date_modification: '2026-10-11T00:00:00Z' }] };
  const neon = fauxNeon(cloud);

  // 1) le curseur ramène la ligne : elle est protégée, donc non appliquée, mais mémorisée
  const ctx = await service._contexteReception('produits');
  const st = await silencieux(() => service._appliquerLignesDistantes('produits', cloud.produits.map((r) => ({ ...r })), '', ctx));
  assert.strictEqual(st.protegees, 1);
  assert.ok(service._protegees.get('produits').has(106));

  // 2) tant que l'envoi local n'est pas parti : rien ne change
  assert.strictEqual(await silencieux(() => service._reprendreProtegees(neon, 'produits')), 0);
  assert.strictEqual(ligne(prisma, 'produits', 106).nom, 'LOCAL');

  // 3) l'envoi est parti : la ligne est redemandée et appliquée, puis oubliée
  prisma.db.exec(`UPDATE operation_log SET status = 'synced'`);
  assert.strictEqual(await silencieux(() => service._reprendreProtegees(neon, 'produits')), 1);
  assert.strictEqual(ligne(prisma, 'produits', 106).nom, 'VERSION CLOUD FINALE');
  assert.strictEqual(service._protegees.get('produits').size, 0);
});

test('_recupererManquants : ne récupère que « jamais reçu, cause inconnue », puis rejoue les lignes en pause', { skip }, async () => {
  const prisma = nouvelleBase();
  preparer(prisma);
  // une ligne de stock en pause attendait le produit 104
  prisma.db.exec(`INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at)
    VALUES ('stock_boutiques', '10', '{"id":10,"produit_id":104,"quantite_disponible":98}', 30, 'FOREIGN KEY constraint failed', datetime('now', '-5 minutes'))`);
  const neon = fauxNeon({
    produits: [
      { id: 104, nom: 'LUSTRE D6328 P', reference: 'PRD20260097', date_modification: null },
      { id: 200, nom: 'DEJA CONNU DU SYSTEME', reference: 'R200', date_modification: null },
    ],
  });
  const rapport = {
    ecarts: [
      { table: 'produits', sens: 'a_recevoir', cause: 'inconnue', connue: false, ids: [{ table: 'produits', id: 104, sens: 'a_recevoir' }] },
      { table: 'produits', sens: 'a_recevoir', cause: 'reprise', connue: true, ids: [{ table: 'produits', id: 200, sens: 'a_recevoir' }] },
      { table: 'produits', sens: 'a_envoyer', cause: 'inconnue', connue: false, ids: [{ table: 'produits', id: 300, sens: 'a_envoyer' }] },
    ],
  };
  const n = await silencieux(() => service._recupererManquants(neon, rapport));
  assert.strictEqual(n, 1);
  assert.ok(ligne(prisma, 'produits', 104), 'le produit manquant est récupéré');
  assert.strictEqual(ligne(prisma, 'produits', 200), undefined, 'une ligne déjà connue du système (file de reprise) est laissée au circuit normal');
  assert.strictEqual(ligne(prisma, 'stock_boutiques', 10).quantite_disponible, 98, 'et la ligne en pause qui l\'attendait est rejouée tout de suite');
});
