/**
 * Renvoi vers le cloud des lignes jamais envoyées — uniquement quand c'est sans risque.
 *
 * Reproduit les cas du client : MC4 et système d'alarme (rien dans le cloud : à envoyer), contrôleur de tension
 * (le cloud a déjà des mouvements : à décider), coussin de massage (supprimé dans le cloud : à ne pas ressusciter).
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-resend.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

const { renvoyerVersCloud } = skip ? {} : require('../src/services/sync-resend');

function nouvelleBase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT, record_id INTEGER, status TEXT DEFAULT 'pending');
    CREATE TABLE boutiques (id INTEGER PRIMARY KEY, nom TEXT);
    CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, reference TEXT);
    CREATE TABLE stock (id INTEGER PRIMARY KEY, produit_id INTEGER, quantite_disponible INTEGER);
    CREATE TABLE stock_boutiques (id INTEGER PRIMARY KEY, boutique_id INTEGER, produit_id INTEGER, quantite_disponible INTEGER);
    CREATE TABLE mouvements_stock (id INTEGER PRIMARY KEY, produit_id INTEGER, boutique_id INTEGER, type_mouvement TEXT, changement_quantite INTEGER, stock_final INTEGER);
    CREATE TABLE historique_prix_achat (id INTEGER PRIMARY KEY, produit_id INTEGER, prix_achat REAL);
    INSERT INTO boutiques VALUES (1, 'SMART ENERGY SARL');
    INSERT INTO produits VALUES (48, 'CONTROLLEUR DE TENSION 230V', 'R48'), (29, 'COUSSIN DE MASSAGE', 'R29'), (51, 'MC4 (Petit)', 'R51'), (100000001, 'Systeme d''alarme', 'R100');
    -- MC4 et alarme : jamais envoyés, le cloud n'a rien pour eux
    INSERT INTO stock VALUES (51, 51, 0), (100000001, 100000001, 0);
    INSERT INTO stock_boutiques VALUES (48, 1, 51, 400), (100000001, 1, 100000001, 7);
    INSERT INTO mouvements_stock VALUES (14, 51, 1, 'achat', 400, 400), (100000001, 100000001, 1, 'achat', 7, 7);
    INSERT INTO historique_prix_achat VALUES (14, 51, 750);
    -- contrôleur de tension : le cloud a déjà des mouvements
    INSERT INTO mouvements_stock VALUES (16, 48, 1, 'achat', 100, 100);
    -- coussin : supprimé dans le cloud
    INSERT INTO stock VALUES (29, 29, 0); INSERT INTO stock_boutiques VALUES (26, 1, 29, 0);
  `);
  return {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
}

/** Faux Neon basé sur des tables { nom: [lignes] } : gère SELECT 1/COUNT/id avec les filtres utilisés par le module */
function fauxNeon(t) {
  return {
    query: async (sql, p = []) => {
      const table = (sql.match(/FROM "?(\w+)"?/) || [])[1];
      const rows = t[table];
      if (!rows) throw new Error(`relation "${table}" does not exist`);
      if (/COUNT\(\*\)/.test(sql)) return { rows: [{ n: rows.filter((r) => r.produit_id === p[0]).length }] };
      if (/WHERE produit_id = \$1 AND boutique_id = \$2/.test(sql)) return { rows: rows.filter((r) => r.produit_id === p[0] && r.boutique_id === p[1]).slice(0, 1).map(() => ({ '?column?': 1 })) };
      if (/WHERE produit_id = \$1/.test(sql)) return { rows: rows.filter((r) => r.produit_id === p[0]).slice(0, 1).map(() => ({ '?column?': 1 })) };
      if (/WHERE id = \$1/.test(sql)) return { rows: rows.filter((r) => r.id === p[0]).slice(0, 1).map(() => ({ '?column?': 1 })) };
      if (/SELECT id FROM/.test(sql)) return { rows: rows.map((r) => ({ id: r.id })) };
      return { rows };
    },
  };
}

const CLOUD = () => ({
  produits: [{ id: 48 }, { id: 51 }, { id: 100000001 }], // 29 (coussin) supprimé
  boutiques: [{ id: 1 }],
  stock: [{ id: 48, produit_id: 48 }],
  stock_boutiques: [{ id: 45, produit_id: 48, boutique_id: 1 }],
  mouvements_stock: [{ id: 1, produit_id: 48 }, { id: 2, produit_id: 48 }, { id: 3, produit_id: 48 }],
  historique_prix_achat: [],
  deleted_records: [{ table_name: 'produits', record_id: 29 }],
});

const lancer = (prisma, cloud, extra = {}) => {
  const ops = [];
  const p = renvoyerVersCloud({ prisma, client: fauxNeon(cloud), logOperation: async (t, o, d) => ops.push([t, o, d]), ...extra });
  return p.then((r) => ({ ...r, ops }));
};

test('aperçu : annonce ce qui partirait et ce qui est refusé, sans rien envoyer', { skip }, async () => {
  const r = await lancer(nouvelleBase(), CLOUD(), { dryRun: true });
  assert.strictEqual(r.envoyes, 0);
  assert.deepStrictEqual(r.ops, [], 'aucune opération journalisée en aperçu');
  assert.strictEqual(r.aEnvoyer, 7, 'MC4 : stock, stock boutique, mouvement, prix ; alarme : stock, stock boutique, mouvement');
  assert.strictEqual(r.refuses, 3, 'contrôleur (mouvement), coussin (stock et stock boutique)');
});

test('envoi : MC4 et alarme partent (INSERT), dans le bon contenu', { skip }, async () => {
  const r = await lancer(nouvelleBase(), CLOUD());
  assert.strictEqual(r.envoyes, 7);
  const mc4 = r.ops.find(([t, , d]) => t === 'stock_boutiques' && d.id === 48);
  assert.ok(mc4);
  assert.strictEqual(mc4[1], 'INSERT');
  assert.strictEqual(mc4[2].quantite_disponible, 400);
  assert.ok(r.ops.some(([t, , d]) => t === 'mouvements_stock' && d.id === 14 && d.changement_quantite === 400));
  assert.ok(r.ops.some(([t, , d]) => t === 'mouvements_stock' && d.id === 100000001 && d.changement_quantite === 7));
});

test('contrôleur de tension : le cloud a déjà des mouvements → refusé, à décider', { skip }, async () => {
  const r = await lancer(nouvelleBase(), CLOUD());
  const refus = r.details.refuses.find((x) => x.table === 'mouvements_stock' && x.id === 16);
  assert.ok(refus, 'mouvement refusé');
  assert.match(refus.raison, /3 mouvement\(s\).*Décisions à prendre/);
  assert.ok(!r.ops.some(([t, , d]) => t === 'mouvements_stock' && d.id === 16), 'et pas envoyé');
});

test('coussin de massage : produit supprimé dans le cloud → ses lignes ne sont jamais ressuscitées', { skip }, async () => {
  const r = await lancer(nouvelleBase(), CLOUD());
  const refus = r.details.refuses.filter((x) => x.id === 29 || x.id === 26);
  assert.strictEqual(refus.length, 2);
  assert.ok(refus.every((x) => /supprimé dans le cloud/.test(x.raison)));
  assert.ok(!r.ops.some(([, , d]) => d.id === 29 || d.id === 26));
});

test('jamais d\'écrasement : un identifiant déjà présent dans le cloud est ignoré', { skip }, async () => {
  const cloud = CLOUD();
  cloud.mouvements_stock = [{ id: 14, produit_id: 99 }]; // autre mouvement, MÊME identifiant 14
  const r = await lancer(nouvelleBase(), cloud);
  assert.ok(!r.ops.some(([t, , d]) => t === 'mouvements_stock' && d.id === 14), "le mouvement 14 n'est pas renvoyé");
  assert.ok(!r.details.refuses.some((x) => x.table === 'mouvements_stock' && x.id === 14), 'il est simplement considéré comme présent');
});

test('ligne équivalente sous un autre identifiant : refusée (clé produit + boutique)', { skip }, async () => {
  const cloud = CLOUD();
  cloud.stock_boutiques = [{ id: 7777, produit_id: 51, boutique_id: 1 }];
  const r = await lancer(nouvelleBase(), cloud);
  const refus = r.details.refuses.find((x) => x.table === 'stock_boutiques' && x.id === 48);
  assert.match(refus.raison, /autre identifiant/);
});

test('déjà prévu à l\'envoi : non doublonné ; cloud injoignable : l\'erreur remonte sans rien envoyer', { skip }, async () => {
  const prisma = nouvelleBase();
  prisma.db.exec(`INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, status) VALUES ('x', 'INSERT', 'stock_boutiques', 48, 'pending')`);
  const r = await lancer(prisma, CLOUD());
  assert.ok(!r.ops.some(([t, , d]) => t === 'stock_boutiques' && d.id === 48), 'déjà en attente');

  const ops = [];
  await assert.rejects(
    () => renvoyerVersCloud({
      prisma: nouvelleBase(),
      client: { query: async () => { throw new Error('connect ETIMEDOUT'); } },
      logOperation: async (...a) => ops.push(a),
      isConnectionError: (e) => /ETIMEDOUT/.test(e.message),
    }),
    /ETIMEDOUT/
  );
  assert.deepStrictEqual(ops, []);
});
