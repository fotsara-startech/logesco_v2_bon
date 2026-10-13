/**
 * Envoi du stock par différence : deux postes qui vendent en même temps ne s'écrasent plus.
 *
 * Cas réel : produit à 1000, A vend 3 (997), B vend 2 (998). Avant : le cloud finissait à 998 (dernier envoi gagnant).
 * Maintenant : le cloud ajoute la DIFFÉRENCE de chaque poste et arrive à 995.
 *
 * Exécution :  node --experimental-sqlite --test tests/stock-difference.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

let DatabaseSync = null;
try { ({ DatabaseSync } = require('node:sqlite')); } catch (_) { /* option --experimental-sqlite absente */ }
const skip = DatabaseSync ? false : 'node:sqlite indisponible (lancer avec --experimental-sqlite)';

process.env.CLOUD_DB_URL = 'postgresql://fake';
const sd = skip ? null : require('../src/services/stock-difference');
const service = skip ? null : require('../src/services/sync-service');

function nouveauPoste() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE stock (id INTEGER PRIMARY KEY, produit_id INTEGER, quantite_disponible INTEGER, quantite_reservee INTEGER DEFAULT 0, derniere_maj TEXT);`);
  const prisma = {
    db,
    $queryRawUnsafe: async (sql, ...p) => db.prepare(sql).all(...p),
    $executeRawUnsafe: async (sql, ...p) => Number(db.prepare(sql).run(...p).changes),
  };
  return prisma;
}

/** Faux cloud : une table « stock » en mémoire, un registre d'opérations, de vraies transactions (BEGIN/COMMIT/ROLLBACK) */
function fauxCloud(lignes = { 1: 1000 }) {
  const etat = { stock: new Map(Object.entries(lignes).map(([id, q]) => [Number(id), { quantite: q, reservee: 0 }])), registre: new Set() };
  let sauvegarde = null;
  const copie = () => ({ stock: new Map([...etat.stock].map(([k, v]) => [k, { ...v }])), registre: new Set(etat.registre) });
  const client = {
    etat,
    requetes: [],
    query: async (sql, params = []) => {
      client.requetes.push(sql.trim().split('\n')[0].slice(0, 60));
      if (/^BEGIN/.test(sql)) { sauvegarde = copie(); return { rows: [] }; }
      if (/^COMMIT/.test(sql)) { sauvegarde = null; return { rows: [] }; }
      if (/^ROLLBACK/.test(sql)) { if (sauvegarde) { etat.stock = sauvegarde.stock; etat.registre = sauvegarde.registre; } sauvegarde = null; return { rows: [] }; }
      if (/CREATE TABLE IF NOT EXISTS "sync_applied_ops"/.test(sql)) { client.registreCree = (client.registreCree || 0) + 1; return { rows: [] }; }
      if (/information_schema/.test(sql)) return { rows: [] };
      if (/INSERT INTO "sync_applied_ops"/.test(sql)) {
        if (etat.registre.has(params[0])) return { rows: [] };
        etat.registre.add(params[0]);
        return { rows: [{ operation_id: params[0] }] };
      }
      if (/^UPDATE "stock"/.test(sql.trim())) {
        const ligne = etat.stock.get(params[params.length - 1]);
        if (!ligne) return { rows: [], rowCount: 0 };
        ligne.quantite += params[0];
        return { rows: [{ quantite_disponible: ligne.quantite }], rowCount: 1 };
      }
      throw new Error(`requête non prévue par le faux cloud : ${sql.slice(0, 80)}`);
    },
  };
  return client;
}

const ligne = (id, quantite) => ({ id, produit_id: 1, quantite_disponible: quantite, quantite_reservee: 0, derniere_maj: new Date().toISOString() });
const envoyer = (cloud, prisma, quantite, operationId, id = 1) => sd.appliquerParDifference({ client: cloud, prisma, table: 'stock', row: ligne(id, quantite), operationId });

test('le cas réel : A vend 3 et B vend 2 sur un stock de 1000 → 995 dans le cloud (et non 998)', { skip }, async () => {
  const cloud = fauxCloud({ 1: 1000 });
  const A = nouveauPoste(); const B = nouveauPoste();
  await sd.creerBaseLocale(A); await sd.creerBaseLocale(B);
  await sd.ecrireBase(A, 'stock', 1, 1000); // les deux postes avaient synchronisé le stock à 1000
  await sd.ecrireBase(B, 'stock', 1, 1000);

  const rA = await envoyer(cloud, A, 997, 'op-A');
  const rB = await envoyer(cloud, B, 998, 'op-B');
  assert.deepStrictEqual([rA.traite, rA.difference, rB.traite, rB.difference], [true, -3, true, -2]);
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 995, 'le cloud ajoute les deux différences');
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 997, 'la base de A devient la valeur qu\'il vient d\'envoyer');
  assert.strictEqual(await sd.lireBase(B, 'stock', 1), 998);
});

test('un envoi rejoué après un accusé de réception perdu n\'est jamais compté deux fois', { skip }, async () => {
  const cloud = fauxCloud({ 1: 1000 });
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  await sd.ecrireBase(A, 'stock', 1, 1000);

  await envoyer(cloud, A, 997, 'op-1');
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 997);
  // l'opération est rejouée (même identifiant) : le cloud l'a déjà appliquée
  await sd.ecrireBase(A, 'stock', 1, 1000); // la base locale n'avait pas été mise à jour (coupure juste après l'envoi)
  const rejeu = await envoyer(cloud, A, 997, 'op-1');
  assert.strictEqual(rejeu.doublon, true);
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 997, 'toujours 997 : pas de seconde déduction');
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 997, 'la base est remise à niveau');
});

test('plusieurs ventes successives du même poste : chaque envoi ajoute sa propre différence', { skip }, async () => {
  const cloud = fauxCloud({ 1: 100 });
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  await sd.ecrireBase(A, 'stock', 1, 100);
  await envoyer(cloud, A, 95, 'op-1');   // −5
  await envoyer(cloud, A, 90, 'op-2');   // −5
  await envoyer(cloud, A, 92, 'op-3');   // +2 (annulation partielle)
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 92);
});

test('sans base connue (première synchronisation, anciennes données) : on ne touche pas, l\'appelant envoie la valeur totale', { skip }, async () => {
  const cloud = fauxCloud({ 1: 1000 });
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  const r = await envoyer(cloud, A, 997, 'op-1');
  assert.strictEqual(r.traite, false);
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 1000, 'rien n\'a été modifié par ce chemin');
  assert.strictEqual(cloud.etat.registre.size, 0, 'et rien n\'a été inscrit au registre');
});

test('ligne absente du cloud : l\'envoi de la valeur totale la créera, et l\'opération n\'est pas inscrite au registre', { skip }, async () => {
  const cloud = fauxCloud({}); // aucune ligne
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  await sd.ecrireBase(A, 'stock', 1, 50);
  const r = await envoyer(cloud, A, 45, 'op-1');
  assert.strictEqual(r.traite, false);
  assert.strictEqual(cloud.etat.registre.size, 0, 'annulé avec la transaction : l\'opération sera rejouée par le chemin normal');
});

test('différence nulle (autre colonne modifiée) : le total du cloud n\'est pas touché', { skip }, async () => {
  const cloud = fauxCloud({ 1: 995 });
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  await sd.ecrireBase(A, 'stock', 1, 997);
  const r = await envoyer(cloud, A, 997, 'op-1');
  assert.deepStrictEqual([r.traite, r.difference], [true, 0]);
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 995, 'les autres ventes déjà présentes dans le cloud sont conservées');
});

test('une erreur pendant l\'envoi annule tout (pas de moitié d\'opération) et la remonte', { skip }, async () => {
  const cloud = fauxCloud({ 1: 1000 });
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  await sd.ecrireBase(A, 'stock', 1, 1000);
  const origine = cloud.query;
  cloud.query = async (sql, p) => { if (/^UPDATE "stock"/.test(sql.trim())) throw new Error('connect ETIMEDOUT'); return origine(sql, p); };
  await assert.rejects(() => envoyer(cloud, A, 997, 'op-1'), /ETIMEDOUT/);
  assert.strictEqual(cloud.etat.registre.size, 0, 'l\'inscription au registre est annulée avec la transaction');
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 1000, 'la base n\'a pas bougé : l\'opération sera rejouée entière');
});

test('réception : la valeur du cloud devient la nouvelle base du poste', { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake';
  await service._mergeRemoteRow('stock', { id: 1, produit_id: 1, quantite_disponible: 995, quantite_reservee: 0 });
  assert.strictEqual(Number(A.db.prepare('SELECT quantite_disponible q FROM stock WHERE id = 1').get().q), 995);
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 995, 'après la réception, la base = valeur du cloud');
});

test('réception : une vente locale pas encore envoyée est conservée, la valeur du cloud est relative à la base', { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake';
  // A avait synchronisé 300, a vendu 15 (285, pas encore envoyé) ; pendant ce temps B a vendu 20 : le cloud est à 280
  A.db.exec('INSERT INTO stock (id, produit_id, quantite_disponible) VALUES (1, 1, 285)');
  await sd.ecrireBase(A, 'stock', 1, 300);
  await service._mergeRemoteRow('stock', { id: 1, produit_id: 1, quantite_disponible: 280, quantite_reservee: 0 });
  assert.strictEqual(Number(A.db.prepare('SELECT quantite_disponible q FROM stock WHERE id = 1').get().q), 265, '280 (cloud) − 15 (vente locale non envoyée)');
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 280, 'la base devient la valeur du cloud');
  // l'envoi de la vente de A ajoutera exactement −15 au cloud
  const cloud = fauxCloud({ 1: 280 });
  await sd.appliquerParDifference({ client: cloud, prisma: A, table: 'stock', row: ligne(1, 265), operationId: 'op-A' });
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 265);
});

test("envoi : une opération journalisée avec une quantité périmée est envoyée avec la quantité ACTUELLE de la ligne", { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  service.localPrisma = A;
  A.db.exec('INSERT INTO stock (id, produit_id, quantite_disponible) VALUES (1, 1, 279)'); // 3 ventes faites : 300 → 279
  await sd.ecrireBase(A, 'stock', 1, 300);
  const cloud = fauxCloud({ 1: 300 });
  // la fusion des opérations en attente a gardé la quantité de la PREMIÈRE vente (293)
  await service._applyToCloud(cloud, 'stock', 'UPDATE', { id: 1, produitId: 1, quantiteDisponible: 293 }, { operationId: 'op-1' });
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 279, '−21 et non −7');
  assert.strictEqual(await sd.lireBase(A, 'stock', 1), 279);
});

test('envoi : le solde d\'un compte client est envoyé avec la valeur ACTUELLE de la ligne, pas celle de l\'opération journalisée', { skip }, async () => {
  const A = nouveauPoste();
  A.db.exec('CREATE TABLE comptes_clients (id INTEGER PRIMARY KEY, solde_actuel REAL); INSERT INTO comptes_clients VALUES (1, -1300)');
  service.localPrisma = A;
  const envoyes = [];
  const brutAvant = service._applyToCloudBrut;
  service._applyToCloudBrut = async (client, table, operation, data) => { envoyes.push(data.soldeActuel); };
  try {
    // opération périmée : journalisée avec le solde d'après la vente (-1800), alors qu'un paiement l'a ramené à -1300
    await service._applyToCloud({}, 'comptes_clients', 'UPDATE', { id: 1, soldeActuel: -1800 }, { operationId: 'op-1' });
    assert.deepStrictEqual(envoyes, [-1300]);
  } finally { service._applyToCloudBrut = brutAvant; }
});

test("journal : une écriture refusée parce que la base est occupée est réessayée, pas perdue", { skip }, async () => {
  const A = nouveauPoste();
  A.db.exec(`CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT, record_id INTEGER, data TEXT, user_id INTEGER, status TEXT, timestamp TEXT)`);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service.isCloudAvailable = false;
  let refus = 2;
  const exec = A.$executeRawUnsafe;
  A.$executeRawUnsafe = async (sql, ...p) => {
    if (/^\s*INSERT INTO operation_log/.test(sql) && refus-- > 0) throw new Error('database is locked');
    return exec(sql, ...p);
  };
  await service.logOperation('details_ventes', 'INSERT', { id: 7, quantite: 2 });
  assert.strictEqual(Number(A.db.prepare("SELECT COUNT(*) n FROM operation_log WHERE table_name = 'details_ventes' AND record_id = 7").get().n), 1, 'journalisée malgré deux refus');
});

test("envoi : le registre du cloud est créé au besoin (cloud injoignable au démarrage), une seule fois", { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  service.localPrisma = A;
  service._registreCloudPret = false;
  A.db.exec('INSERT INTO stock (id, produit_id, quantite_disponible) VALUES (1, 1, 95)');
  await sd.ecrireBase(A, 'stock', 1, 100);
  const cloud = fauxCloud({ 1: 100 });
  await service._applyToCloud(cloud, 'stock', 'UPDATE', { id: 1, produitId: 1, quantiteDisponible: 95 }, { operationId: 'op-1' });
  assert.strictEqual(cloud.registreCree, 1, 'registre créé avant le premier envoi par différence');
  A.db.exec('UPDATE stock SET quantite_disponible = 90 WHERE id = 1');
  await service._applyToCloud(cloud, 'stock', 'UPDATE', { id: 1, produitId: 1, quantiteDisponible: 90 }, { operationId: 'op-2' });
  assert.strictEqual(cloud.registreCree, 1, 'pas recréé à chaque envoi');
  assert.strictEqual(cloud.etat.stock.get(1).quantite, 90);
});

test("stock modifié en local mais jamais journalisé (arrêt avant l'écriture différée) : retrouvé grâce à la base de référence", { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  A.db.exec(`CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT, record_id INTEGER, data TEXT, user_id INTEGER, status TEXT, timestamp TEXT)`);
  service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service.isCloudAvailable = false;
  // ligne 1 : +5 jamais journalisé ; ligne 2 : modifiée mais une opération est déjà en attente ; ligne 3 : inchangée
  A.db.exec(`INSERT INTO stock (id, produit_id, quantite_disponible) VALUES (1, 1, 65), (2, 2, 40), (3, 3, 10)`);
  await sd.ecrireBase(A, 'stock', 1, 60);
  await sd.ecrireBase(A, 'stock', 2, 50);
  await sd.ecrireBase(A, 'stock', 3, 10);
  A.db.exec(`INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status) VALUES ('deja', 'UPDATE', 'stock', 2, '{}', 'pending')`);

  const n = await service._rattraperStockNonJournalise();
  assert.strictEqual(n, 1, 'une seule ligne rattrapée');
  const ops = A.db.prepare("SELECT record_id r, operation_type o, status s FROM operation_log WHERE table_name = 'stock' ORDER BY id").all();
  assert.deepStrictEqual(ops.map((o) => [Number(o.r), o.o, o.s]), [[2, 'UPDATE', 'pending'], [1, 'UPDATE', 'pending']], 'ligne 1 journalisée, ligne 2 non doublée, ligne 3 ignorée');

  // un second passage ne recrée rien (l'opération est maintenant en attente)
  assert.strictEqual(await service._rattraperStockNonJournalise(), 0);
  // et une opération déjà envoyée (synced) ne compte pas comme « en attente » : un nouvel écart est retrouvé
  A.db.exec("UPDATE operation_log SET status = 'synced' WHERE record_id = 1");
  assert.strictEqual(await service._rattraperStockNonJournalise(), 1);
});

test("historique créé par CE poste mais jamais journalisé : retrouvé (bloc d'identifiants du poste), le reste est ignoré", { skip }, async () => {
  const installation = require('../src/utils/installation');
  const avant = installation.getInstallationId();
  installation.setInstallationId(2); // bloc 20 000 000 … 29 999 999
  try {
    const A = nouveauPoste();
    A.db.exec(`CREATE TABLE operation_log (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT, operation_type TEXT, table_name TEXT, record_id INTEGER, data TEXT, user_id INTEGER, status TEXT, timestamp TEXT);
      CREATE TABLE mouvements_stock (id INTEGER PRIMARY KEY, produit_id INTEGER, changement_quantite INTEGER);`);
    service.localPrisma = A; service.cloudUrl = 'postgresql://fake'; service.isCloudAvailable = false;
    A.db.exec(`INSERT INTO mouvements_stock VALUES (20000001, 1, 5), (20000002, 1, 3), (20000003, 1, 7), (10000009, 1, 9), (4, 1, 1)`);
    // 20000002 : déjà journalisé (envoyé) ; 10000009 : reçu d'un autre poste (autre bloc) ; 4 : donnée d'avant la synchro
    A.db.exec(`INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, status) VALUES ('o1', 'INSERT', 'mouvements_stock', 20000002, '{}', 'synced')`);

    assert.strictEqual(await service._rattraperHistoriqueNonJournalise(), 2, 'les deux lignes de notre bloc sans journal');
    const ops = A.db.prepare("SELECT record_id r, operation_type o, status s FROM operation_log WHERE table_name = 'mouvements_stock' AND operation_id <> 'o1' ORDER BY record_id").all();
    assert.deepStrictEqual(ops.map((o) => [Number(o.r), o.o, o.s]), [[20000001, 'INSERT', 'pending'], [20000003, 'INSERT', 'pending']]);
    assert.strictEqual(await service._rattraperHistoriqueNonJournalise(), 0, 'rien à refaire au passage suivant');
  } finally { installation.setInstallationId(avant); }
});

test('chemin complet du service : sans base → valeur totale puis base établie ; avec base → différence', { skip }, async () => {
  const A = nouveauPoste(); await sd.creerBaseLocale(A);
  service.localPrisma = A;
  const cloud = fauxCloud({ 1: 1000 });
  const brutAvant = service._applyToCloudBrut;
  const appelsBruts = [];
  service._applyToCloudBrut = async (client, table, operation, data) => { appelsBruts.push([table, operation, data.quantiteDisponible ?? data.quantite_disponible]); };
  try {
    // 1) première synchronisation : pas de base → chemin habituel (valeur totale)
    await service._applyToCloud(cloud, 'stock', 'UPDATE', { id: 1, produitId: 1, quantiteDisponible: 997 }, { operationId: 'op-1' });
    assert.deepStrictEqual(appelsBruts, [['stock', 'UPDATE', 997]]);
    assert.strictEqual(await sd.lireBase(A, 'stock', 1), 997, 'la base est établie');
    // 2) la vente suivante : base connue → différence, le chemin habituel n'est plus emprunté
    await service._applyToCloud(cloud, 'stock', 'UPDATE', { id: 1, produitId: 1, quantiteDisponible: 990 }, { operationId: 'op-2' });
    assert.strictEqual(appelsBruts.length, 1, 'pas de second envoi de valeur totale');
    assert.strictEqual(cloud.etat.stock.get(1).quantite, 993, '1000 + (990 − 997)');
    // 3) les tables autres que le stock ne sont pas concernées
    await service._applyToCloud(cloud, 'produits', 'UPDATE', { id: 5, nom: 'X' }, { operationId: 'op-3' });
    assert.strictEqual(appelsBruts.length, 2);
  } finally { service._applyToCloudBrut = brutAvant; }
});
