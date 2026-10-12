/**
 * RATTRAPAGE des lignes « jamais reçues », FILE DE REPRISE et LIGNES PÉRIMÉES.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/30-rattrapage.test.js
 *
 * Les lignes sont injectées directement dans le cloud de test (requêtes SQL), comme si un autre poste les avait
 * poussées. Les déclencheurs de date du cloud ne jouant que sur les UPDATE, une insertion garde la date fournie
 * (c'est ce qui arrive à une ligne créée hors ligne puis poussée tard).
 */
const test = require('node:test');
const assert = require('node:assert');
require('../harness/aide-reseau');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { requete } = require('../harness/cloud-admin');
const aide = require('../harness/aide-horsligne');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

/** Deux postes réglés : un produit de base a fait avancer les curseurs de réception jusqu'à « maintenant » */
async function postesReglesAvecCurseurs(c) {
  const { A, B } = c.postes;
  await aide.creerProduits(A, 1, 'BASE');
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
  assert.ok(r.ok, `mise en place sans convergence : ${decrire(r.autres)}`);
  const curseur = A.lire("SELECT last_modified_at FROM sync_pull_state WHERE table_name = 'produits'")[0];
  assert.ok(curseur && curseur.last_modified_at, 'le curseur de réception des produits a avancé');
  return curseur.last_modified_at;
}

const nbLocal = (p, table, ou) => Number(p.lire(`SELECT COUNT(*) n FROM "${table}" WHERE ${ou}`)[0].n);

test('4. lignes « jamais reçues » (date ancienne, stock sans date) : rattrapées par le contrôle d\'écart, plus d\'écart inexpliqué', { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const curseur = await postesReglesAvecCurseurs(c);
  console.log(`   curseur produits de A : ${curseur}`);

  // produits antérieurs au curseur : il y a 30 jours, 2 heures, 1 minute ; avec leurs lignes de stock SANS date
  const specs = [
    { id: 2000000001, reference: 'JAMAIS-30J', dateMod: "NOW() - INTERVAL '30 days'" },
    { id: 2000000002, reference: 'JAMAIS-2H', dateMod: "NOW() - INTERVAL '2 hours'" },
    { id: 2000000003, reference: 'JAMAIS-1MIN', dateMod: "NOW() - INTERVAL '1 minute'" },
    { id: 2000000004, reference: 'JAMAIS-RECENT', dateMod: 'NOW()' },
  ];
  for (const s of specs) await aide.insererProduitCloud(c.cloudUrl, { ...s, avecStock: true, quantite: 9 });
  // un client ancien et son compte sans date
  await requete(c.cloudUrl, `INSERT INTO clients (id, nom, prenom, telephone, date_creation, date_modification) VALUES (2000000010, 'Ancien', 'Client', '699777001', NOW(), NOW() - INTERVAL '10 days')`);
  await requete(c.cloudUrl, `INSERT INTO comptes_clients (id, client_id, solde_actuel, limite_credit, date_derniere_maj, date_modification) VALUES (2000000010, 2000000010, 0, 0, NOW(), NULL)`);

  // rattrapage attendu au contrôle d'écart (1er à ~20 s du démarrage, puis toutes les 60 s) : ≤ 2 min
  const debut = Date.now();
  const toutArrive = async () => [A, B].every((p) => nbLocal(p, 'produits', "reference LIKE 'JAMAIS-%'") === 4 && nbLocal(p, 'stock_boutiques', 'id >= 2000000001 AND id <= 2000000004') === 4 && nbLocal(p, 'clients', 'id = 2000000010') === 1 && nbLocal(p, 'comptes_clients', 'id = 2000000010') === 1);
  const r1 = await aide.attendre(toutArrive, { delaiMs: 180000, pauseMs: 4000 });
  console.log(`   rattrapage ${r1.ok ? 'terminé' : 'INCOMPLET'} en ${Math.round((Date.now() - debut) / 1000)} s`);
  const manque = [A, B].map((p) => `${p.nom}: produits=${nbLocal(p, 'produits', "reference LIKE 'JAMAIS-%'")}/4, stock_boutiques=${nbLocal(p, 'stock_boutiques', 'id >= 2000000001 AND id <= 2000000004')}/4, client=${nbLocal(p, 'clients', 'id = 2000000010')}, compte=${nbLocal(p, 'comptes_clients', 'id = 2000000010')}`);
  assert.ok(r1.ok, `lignes jamais rattrapées : ${manque.join(' ; ')}`);
  assert.match(A.journal(3000), /Rattrapage produits/, 'le rattrapage par identifiant est bien ce qui les a ramenées');

  // GET /sync/drift?refresh=1 renvoie l'ANCIEN rapport quand un contrôle est déjà en cours : on réinterroge jusqu'à un rapport propre
  for (const p of [A, B]) {
    let e;
    const propre = await aide.attendre(async () => { e = await aide.ecartsInexpliques(p); return e.inexpliques === 0; }, { delaiMs: 120000, pauseMs: 5000 });
    assert.ok(propre.ok, "écart inexpliqué restant sur " + p.nom + " : " + aide.resumeEcarts(e.ecarts));
  }
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 120000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  assert.strictEqual(Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n), 0, 'file de reprise vide');
});

test('5. file de reprise : enfant reçu avant son parent, puis parent arrivé ; ligne « abandonnée » (25 essais) rejouée', { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  await postesReglesAvecCurseurs(c);

  // 5a. parent ancien (jamais pris par le curseur) + enfant récent : l'enfant arrive seul et part en file de reprise
  const P = 2000000101;
  await aide.insererProduitCloud(c.cloudUrl, { id: P, reference: 'PARENT-A', dateMod: "NOW() - INTERVAL '30 days'" });
  const b = await aide.boutiqueCloud(c.cloudUrl);
  await requete(c.cloudUrl, `INSERT INTO stock_boutiques (id, boutique_id, produit_id, quantite_disponible, quantite_reservee, derniere_maj, date_modification) VALUES ($1, $2, $1, 7, 0, NOW(), NOW())`, [P, b]);

  const enFile = await aide.attendre(async () => Number(A.lire("SELECT COUNT(*) n FROM sync_pull_retry WHERE table_name = 'stock_boutiques' AND record_id = ?", String(P))[0].n) > 0, { delaiMs: 40000, pauseMs: 500 });
  console.log(`   enfant en file de reprise sur A : ${enFile.ok ? 'oui' : 'non'} (${enFile.ok ? 'dernière erreur : ' + String(A.lire('SELECT last_error e FROM sync_pull_retry')[0].e).replace(/\s+/g, ' ').slice(0, 120) : 'arrivé directement ou rattrapé avant observation'})`);
  if (enFile.ok) assert.strictEqual(nbLocal(A, 'stock_boutiques', `id = ${P}`), 0, "l'enfant n'est pas appliqué tant que le parent manque");

  // le parent « arrive » : une modification dans le cloud fixe sa date à maintenant (déclencheur) → reçu par le curseur
  await requete(c.cloudUrl, 'UPDATE produits SET nom = $2 WHERE id = $1', [P, 'Parent A arrivé']);
  const r5 = await aide.attendre(async () => [A, B].every((p) => nbLocal(p, 'produits', `id = ${P}`) === 1 && nbLocal(p, 'stock_boutiques', `id = ${P}`) === 1), { delaiMs: 150000, pauseMs: 3000 });
  assert.ok(r5.ok, `enfant jamais appliqué après l'arrivée du parent (A: produit=${nbLocal(A, 'produits', `id = ${P}`)} stock=${nbLocal(A, 'stock_boutiques', `id = ${P}`)}; file: ${JSON.stringify(A.lire('SELECT table_name, record_id, attempts FROM sync_pull_retry'))})`);
  await aide.attendre(async () => Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n) === 0, { delaiMs: 30000, pauseMs: 2000 });
  assert.strictEqual(Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n), 0, 'la file de reprise est vide');

  // 5b. ligne « abandonnée » : 25 essais, dernière tentative il y a longtemps, parent présent → doit être rejouée
  const ligne = await aide.ligneCloud(c.cloudUrl, 'stock_boutiques', P);
  ligne.quantite_disponible = 42; // version « du cloud » que la file transporte
  ligne.date_modification = new Date(Date.now() + 3600 * 1000); // plus récente que la version locale (sinon « périmée »)
  const payload = JSON.stringify(ligne);
  aide.ecrireLocal(A, 'DELETE FROM stock_boutiques WHERE id = ?', P);
  aide.ecrireLocal(A, "INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at) VALUES ('stock_boutiques', ?, ?, 25, 'test: parent absent', '2020-01-01 00:00:00')", String(P), payload);
  const r5b = await aide.attendre(async () => nbLocal(A, 'stock_boutiques', `id = ${P} AND quantite_disponible = 42`) === 1, { delaiMs: 60000, pauseMs: 2000 });
  assert.ok(r5b.ok, `ligne à 25 essais jamais rejouée (file : ${JSON.stringify(A.lire('SELECT table_name, record_id, attempts, updated_at FROM sync_pull_retry'))})`);
  assert.strictEqual(Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n), 0, 'ligne retirée de la file après rejeu');
});

test('6. lignes périmées : une ligne de la file plus ANCIENNE que la version locale ne l\'écrase pas (et une plus récente s\'applique)', { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  await postesReglesAvecCurseurs(c);

  const [p1, p2] = await aide.creerProduits(A, 2, 'PER', { stock: 0 });
  const maj = await A.api('PUT', `/products/${p1}`, { nom: 'V2-ACTUEL' });
  assert.ok([200, 201].includes(maj.statut), JSON.stringify(maj.corps).slice(0, 200));
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000, tables: ['produits'] });
  assert.ok(r.ok, `mise en place sans convergence : ${decrire(r.autres)}`);

  const brut = A.lire('SELECT date_modification d FROM produits WHERE id = ?', p1)[0].d;
  const mLocal = typeof brut === 'number' || typeof brut === 'bigint' ? Number(brut) : Date.parse(String(brut).includes('T') ? brut : String(brut).replace(' ', 'T') + 'Z');
  console.log(`   version locale de A : ${new Date(mLocal).toISOString()} (brut: ${typeof brut} ${brut})`);

  // lignes en file : la 1re (p1) est plus vieille d'une heure que la version locale, la 2e (p2) plus récente d'une heure
  const perimee = { ...(await aide.ligneCloud(c.cloudUrl, 'produits', p1)), nom: 'V0-PERIMEE', date_modification: new Date(mLocal - 3600 * 1000) };
  const recente = { ...(await aide.ligneCloud(c.cloudUrl, 'produits', p2)), nom: 'V3-RECENTE', date_modification: new Date(Date.now() + 3600 * 1000) };
  aide.ecrireLocal(A, "INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at) VALUES ('produits', ?, ?, 1, 'test', '2020-01-01 00:00:00')", String(p1), JSON.stringify(perimee));
  aide.ecrireLocal(A, "INSERT INTO sync_pull_retry (table_name, record_id, payload, attempts, last_error, updated_at) VALUES ('produits', ?, ?, 1, 'test', '2020-01-01 00:00:00')", String(p2), JSON.stringify(recente));

  const vide = await aide.attendre(async () => Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n) === 0, { delaiMs: 60000, pauseMs: 2000 });
  assert.ok(vide.ok, `la file n'a pas été traitée : ${JSON.stringify(A.lire('SELECT table_name, record_id, attempts FROM sync_pull_retry'))}`);
  assert.strictEqual(A.lire('SELECT nom FROM produits WHERE id = ?', p1)[0].nom, 'V2-ACTUEL', 'la ligne périmée de la file n\'a pas écrasé la version locale');
  assert.strictEqual(A.lire('SELECT nom FROM produits WHERE id = ?', p2)[0].nom, 'V3-RECENTE', 'la ligne plus récente de la file est appliquée');
  assert.match(A.journal(3000), /périmée\(s\) retirée\(s\)/, 'le poste signale la ligne périmée retirée');
});
