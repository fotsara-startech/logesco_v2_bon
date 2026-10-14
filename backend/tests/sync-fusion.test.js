/**
 * Fusion champ par champ des fiches (produits, clients, fournisseurs, catégories).
 *
 * Exécution :  node --experimental-sqlite --test tests/sync-fusion.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

process.env.CLOUD_DB_URL = 'postgresql://fake';
const fusion = require('../src/services/sync-fusion');
const service = skip ? null : require('../src/services/sync-service');

const EDITION = '2026-10-13T10:00:00.000Z';

// ── Logique pure ────────────────────────────────────────────────────────────────

test('normalisation : booléens, dates, grands entiers ; objets ignorés ; colonnes gérées ailleurs écartées', () => {
  const i = fusion.instantane({
    id: 1, nom: 'X', est_actif: true, prix: 12.5, stock: 3n, cree: new Date('2026-01-02T03:04:05.000Z'),
    date_modification: 'x', date_creation: 'y', derniere_edition: 'z', categorie: { id: 1 }, liste: [1], _interne: 1, vide: null,
  });
  assert.deepStrictEqual(i, { nom: 'X', est_actif: 1, prix: 12.5, stock: 3, cree: '2026-01-02T03:04:05.000Z', vide: null });
});

test('colonnes modifiées : seulement celles qui diffèrent de la base (absente = modifiée)', () => {
  const base = { nom: 'A', prix: 10, description: null };
  assert.deepStrictEqual(fusion.colonnesModifiees({ nom: 'A', prix: 12, description: null }, base), ['prix']);
  assert.deepStrictEqual(fusion.colonnesModifiees({ nom: 'A', prix: 10, description: null, adresse: 'x' }, base), ['adresse']);
  assert.deepStrictEqual(fusion.colonnesModifiees({ nom: 'A', prix: 10, description: null }, base), []);
});

test("date d'édition : date de modification de la ligne, sinon maintenant", () => {
  assert.strictEqual(fusion.dateEdition({ date_modification: EDITION }), EDITION);
  assert.strictEqual(fusion.dateEdition({ dateModification: new Date(EDITION).getTime() }), EDITION);
  const maintenant = Date.now();
  const d = Date.parse(fusion.dateEdition({}));
  assert.ok(Math.abs(d - maintenant) < 5000);
});

test('avec base : seules les colonnes modifiées partent, chacune gardée par « inchangée depuis la base OU édition plus récente »', () => {
  const base = { nom: 'Commun', prix: 1000, description: null };
  const m = fusion.construireMiseAJour({
    table: 'produits',
    ligne: { id: 7, nom: 'Commun', prix: 3000, description: null, date_modification: EDITION },
    base,
  });
  assert.deepStrictEqual(m.colonnes, ['prix']);
  assert.match(m.sql, /UPDATE "produits" SET "prix" = CASE WHEN "produits"\."prix" IS NOT DISTINCT FROM \$3 OR e\.ed <= \$1::timestamp THEN \$2 ELSE "produits"\."prix" END/);
  assert.ok(!/"nom"|"description"/.test(m.sql), 'les colonnes non modifiées ne partent pas');
  assert.match(m.sql, /FROM "sync_edition" WHERE "table_name" = 'produits' AND "record_id" = \$4/, "la dernière édition est lue dans la table à part");
  assert.ok(!/derniere_edition"\s*=/.test(m.sql.split('RETURNING 1')[0]), "aucune colonne ajoutée aux tables de fiches (la mise à jour de la fiche ne touche pas derniere_edition)");
  assert.deepStrictEqual(m.params, [EDITION, 3000, 1000, 7]);
  assert.match(m.sql, /^WITH ecrit AS \(UPDATE/, 'une seule requête : la mise à jour est enveloppée');
  assert.match(m.sql, /INSERT INTO "sync_edition".*SELECT 'produits', \$4::bigint, \$1::timestamp WHERE EXISTS \(SELECT 1 FROM ecrit\).*GREATEST/s, "la date d'édition est enregistrée dans la même requête, et ne recule jamais");
  assert.ok(!/BEGIN|COMMIT/.test(m.sql), 'aucune transaction explicite');
});

test('avec base et rien de modifié : rien à envoyer', () => {
  const base = { nom: 'Commun', prix: 1000 };
  assert.strictEqual(fusion.construireMiseAJour({ table: 'produits', ligne: { id: 7, nom: 'Commun', prix: 1000 }, base }), null);
});

test("sans base : fiche entière, mais jamais par-dessus une édition plus récente", () => {
  const m = fusion.construireMiseAJour({
    table: 'clients',
    ligne: { id: 3, nom: 'Dupont', adresse: 'Adresse B', date_modification: EDITION },
    base: null,
  });
  assert.deepStrictEqual(m.colonnes, ['nom', 'adresse']);
  assert.match(m.sql, /WHERE "clients"\.id = \$\d+ AND e\.ed <= \$\d+::timestamp RETURNING 1\)/, 'jamais par-dessus une édition plus récente');
  assert.match(m.sql, /COALESCE\(\(SELECT "derniere_edition" FROM "sync_edition"/, 'édition inconnue = -infini : la mise à jour passe');
});

test('produit : une modification ordinaire n\'envoie pas est_actif = vrai, une réactivation explicite oui, une désactivation toujours', () => {
  const base = { nom: 'X', est_actif: 0 };
  const ordinaire = fusion.construireMiseAJour({ table: 'produits', ligne: { id: 1, nom: 'Y', est_actif: true }, base });
  assert.deepStrictEqual(ordinaire.colonnes, ['nom']);
  const explicite = fusion.construireMiseAJour({ table: 'produits', ligne: { id: 1, nom: 'X', est_actif: true }, base, reactivation: true });
  assert.deepStrictEqual(explicite.colonnes, ['est_actif']);
  const desactive = fusion.construireMiseAJour({ table: 'produits', ligne: { id: 1, nom: 'X', est_actif: false }, base: { nom: 'X', est_actif: 1 } });
  assert.deepStrictEqual(desactive.colonnes, ['est_actif']);
});

// ── Dans le service ─────────────────────────────────────────────────────────────

function nouveauPoste() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE produits (id INTEGER PRIMARY KEY, nom TEXT, prix_unitaire REAL, description TEXT, est_actif INTEGER DEFAULT 1, date_modification TEXT);`);
  return {
    db,
    // Prisma lie les booléens ; node:sqlite non : on les convertit comme le ferait Prisma
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p.map((v) => (typeof v === 'boolean' ? Number(v) : v))),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p.map((v) => (typeof v === 'boolean' ? Number(v) : v))).changes),
  };
}
function fauxCloud() {
  const requetes = [];
  return { requetes, query: async (sql, params) => { requetes.push({ sql, params }); return { rowCount: 1, rows: [] }; } };
}

test('réception : la colonne d\'édition (cloud seulement) est ignorée et la version reçue devient la base', { skip }, async () => {
  const A = nouveauPoste(); await fusion.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake';
  await service._mergeRemoteRow('produits', {
    id: 1, nom: 'Du cloud', prix_unitaire: 2500, description: null, est_actif: true,
    date_modification: new Date('2026-10-13T09:00:00.000Z'), derniere_edition: new Date('2026-10-13T08:59:00.000Z'),
  });
  assert.strictEqual(A.db.prepare('SELECT nom FROM produits WHERE id = 1').get().nom, 'Du cloud');
  assert.deepStrictEqual(await fusion.lireBase(A, 'produits', 1), { nom: 'Du cloud', prix_unitaire: 2500, description: null, est_actif: 1 });
});

test('envoi : avec la base retenue à la réception, seule la colonne modifiée localement part, puis la base est mise à jour', { skip }, async () => {
  const A = nouveauPoste(); await fusion.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service._colonneEditionPrete = false;
  await service._mergeRemoteRow('produits', { id: 1, nom: 'Commun', prix_unitaire: 1000, description: null, est_actif: true });

  const cloud = fauxCloud();
  // le poste change la description ; sa ligne complète (avec le nom et le prix inchangés) est dans l'opération
  await service._applyToCloudBrut(cloud, 'produits', 'UPDATE', {
    id: 1, nom: 'Commun', prixUnitaire: 1000, description: 'Posée par A', estActif: true, dateModification: EDITION,
  });
  const maj = cloud.requetes.find((r) => /UPDATE "produits" SET/.test(r.sql));
  assert.ok(maj, 'une mise à jour est envoyée');
  assert.match(maj.sql, /"description" = CASE/);
  assert.ok(!/"nom"|"prix_unitaire"|"est_actif"/.test(maj.sql), 'seule la description part');
  assert.ok(cloud.requetes.some((r) => /CREATE TABLE IF NOT EXISTS "sync_edition"/.test(r.sql)), "table des éditions créée au besoin");
  assert.ok(!cloud.requetes.some((r) => /ALTER TABLE/.test(r.sql)), 'aucune colonne ajoutée aux tables de fiches');
  assert.ok(!cloud.requetes.some((r) => /^(BEGIN|COMMIT|ROLLBACK)/.test(r.sql)), 'aucune transaction explicite');
  assert.match(maj.sql, /INSERT INTO "sync_edition"/, "la date d'édition est enregistrée dans la même requête");
  const ecritures = cloud.requetes.filter((r) => /UPDATE "produits" SET/.test(r.sql));
  assert.strictEqual(ecritures.length, 1, 'un seul aller-retour pour la mise à jour');
  assert.strictEqual((await fusion.lireBase(A, 'produits', 1)).description, 'Posée par A', 'la base reflète ce qui vient d\'être envoyé');

  // même opération rejouée : plus rien à envoyer
  const cloud2 = fauxCloud();
  await service._applyToCloudBrut(cloud2, 'produits', 'UPDATE', { id: 1, nom: 'Commun', prixUnitaire: 1000, description: 'Posée par A', estActif: true, dateModification: EDITION });
  assert.ok(!cloud2.requetes.some((r) => /UPDATE "produits" SET/.test(r.sql)), "aucune mise à jour : rien n'a changé");
});

test('envoi d\'un INSERT : la date d\'édition part avec la ligne et la base est retenue', { skip }, async () => {
  const A = nouveauPoste(); await fusion.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service._colonneEditionPrete = true;
  const cloud = fauxCloud();
  await service._applyToCloudBrut(cloud, 'produits', 'INSERT', { id: 5, nom: 'Neuf', prixUnitaire: 10, dateModification: EDITION });
  const ins = cloud.requetes.find((r) => /INSERT INTO "produits"/.test(r.sql));
  assert.ok(!/"produits" \([^)]*derniere_edition/.test(ins.sql), "aucune colonne ajoutée à la table de fiches");
  assert.match(ins.sql, /INSERT INTO "sync_edition"/, "la date d'édition est enregistrée dans la même requête");
  assert.ok(ins.params.includes(EDITION), "avec la date d'édition en paramètre");
  assert.strictEqual(cloud.requetes.filter((r) => /INSERT INTO "produits"/.test(r.sql)).length, 1, 'un seul aller-retour');
  assert.strictEqual((await fusion.lireBase(A, 'produits', 5)).nom, 'Neuf');
});

// ── Colonne propre au poste (ex. image_url) : le cloud ne la connaît pas ─────────────────────────────

test('colonne vide absente de la base : pas une modification (le cloud ne connaît peut-être pas cette colonne)', () => {
  assert.deepStrictEqual(fusion.colonnesModifiees({ nom: 'A', image_url: null }, { nom: 'A' }), []);
  assert.deepStrictEqual(fusion.colonnesModifiees({ nom: 'A', image_url: 'x.png' }, { nom: 'A' }), ['image_url'], 'mais une valeur renseignée est bien une modification');
});

test('colonnes inconnues du cloud : retirées avant la fusion', () => {
  const cloud = new Set(['id', 'nom', 'prix_unitaire']);
  const l = fusion.limiterAuxColonnes({ id: 1, nom: 'A', prix_unitaire: 5, image_url: 'x.png', date_modification: 'd' }, cloud);
  assert.deepStrictEqual(Object.keys(l).sort(), ['date_modification', 'id', 'nom', 'prix_unitaire']);
  assert.strictEqual(fusion.limiterAuxColonnes({ id: 1, a: 1 }, null).a, 1, 'colonnes du cloud inconnues : aucun filtre');
});

test("envoi : une colonne locale que le cloud n'a pas (image_url) ne part jamais", { skip }, async () => {
  const A = nouveauPoste(); await fusion.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service._colonneEditionPrete = true;
  service._cacheColonnesCloud = new Map();
  await service._mergeRemoteRow('produits', { id: 1, nom: 'Commun', prix_unitaire: 1000, description: null, est_actif: true });
  const requetes = [];
  const cloud = {
    requetes,
    query: async (sql, params) => {
      requetes.push({ sql, params });
      if (/information_schema/.test(sql)) return { rows: ['id', 'nom', 'prix_unitaire', 'description', 'est_actif', 'date_modification', 'derniere_edition'].map((c) => ({ column_name: c })) };
      return { rowCount: 1, rows: [] };
    },
  };
  await service._applyToCloudBrut(cloud, 'produits', 'UPDATE', { id: 1, nom: 'Commun', prixUnitaire: 1500, imageUrl: 'photo.png', estActif: true, dateModification: EDITION });
  const maj = requetes.find((r) => /UPDATE "produits" SET/.test(r.sql));
  assert.match(maj.sql, /"prix_unitaire" = CASE/);
  assert.ok(!/image_url/.test(maj.sql), 'la colonne propre au poste ne part pas');
});
