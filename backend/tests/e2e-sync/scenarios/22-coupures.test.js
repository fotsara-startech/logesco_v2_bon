/**
 * Synchronisation sur liaison INSTABLE : coupures aléatoires (★3), coupure totale de 90 s (★4), alternance rapide
 * marche/arrêt (7), perte de connexion pendant la réception (9).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/22-coupures.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
// network-faults en premier : il rend les requêtes directes au cloud tolérantes aux micro-coupures de la machine de test
const { avecReprise, BancPannes, statutsOperations, doublonsNaturels, tempsCpuPoste, mesurerApiLocale, lignesReseau, surveillerOperations, pause } = require('../harness/network-faults');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { requete } = require('../harness/cloud-admin');
const { creerProduits, creerVentes, compterCloud } = require('../harness/charge-reseau');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

/** Deux postes : A derrière le banc de pannes, B direct. */
async function campagne(t) {
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: [{ nom: 'A', ...banc.optionsPoste() }, 'B'] }));
  t.after(() => c.terminer());
  return { banc, c };
}

/** Vérifications communes de fin de scénario */
async function verifierFin(c, A, r, surveillance, { produits, ventes } = {}) {
  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}\n${lignesReseau(A).slice(-15).join('\n')}`);
  const st = statutsOperations(A);
  assert.strictEqual(st.pending || 0, 0, `plus rien en attente : ${JSON.stringify(st)}`);
  assert.strictEqual(surveillance.max.failed, 0, `une erreur de LIAISON a été classée « failed » (refus de données) : ${surveillance.messages.join(' | ')}`);
  const doublons = await doublonsNaturels(A, c.cloudUrl);
  assert.deepStrictEqual(doublons.poste, {}, 'pas de doublon sur A');
  assert.deepStrictEqual(doublons.cloud, {}, 'pas de doublon dans le cloud');
  if (produits !== undefined) assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), produits, 'nombre de produits dans le cloud');
  if (ventes !== undefined) assert.strictEqual(await compterCloud(c.cloudUrl, 'ventes'), ventes, 'nombre de ventes dans le cloud');
  const dup = await requete(c.cloudUrl, 'SELECT id, COUNT(*) n FROM produits GROUP BY id HAVING COUNT(*) > 1');
  assert.strictEqual(dup.length, 0);
}

// ★ 3. Coupures aléatoires de connexion pendant un envoi massif
for (const proba of [0.1, 0.3]) {
  test(`★3 coupures aléatoires (${proba * 100} % des connexions) pendant un envoi massif`, { skip, timeout: 3600000 }, async (t) => {
    const { banc, c } = await campagne(t);
    const { A, B } = c.postes;
    banc.regler({ coupureConnexion: proba, coupureMinOctets: 3000, coupureMaxOctets: 60000, coupureRequete: proba / 10, latenceMs: 150 });
    const surveillance = surveillerOperations(A);
    const cpu0 = tempsCpuPoste(A);
    const t0 = Date.now();
    const ids = await creerProduits(A, 60, `COUP${Math.round(proba * 100)}`, { stock: 30 });
    await creerVentes(A, ids, 20);
    const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 3000000 }));
    const rap = await surveillance.arreter();
    const cpu = (tempsCpuPoste(A) ?? 0) - (cpu0 ?? 0);
    console.log(`[coupures ${proba * 100} %] convergence ${Math.round((Date.now() - t0) / 1000)} s ; banc : ${JSON.stringify(banc.stats)} ; ` +
      `max pending ${rap.max.pending}, max failed ${rap.max.failed} ; CPU de A ${cpu.toFixed(1)} s ; journal : ${lignesReseau(A).length} lignes réseau`);
    await verifierFin(c, A, r, rap, { produits: 60, ventes: 20 });
  });
}

// ★ 4. Coupure totale de 90 s en plein envoi, puis retour
test('★4 coupure totale de 90 s en plein envoi puis retour : reprise automatique', { skip, timeout: 3600000 }, async (t) => {
  const { banc, c } = await campagne(t);
  const { A, B } = c.postes;
  banc.regler({ latenceMs: 400 });
  const surveillance = surveillerOperations(A);
  const ids = await creerProduits(A, 80, 'TOT', { stock: 20 });
  // attendre qu'une partie soit partie mais pas tout : la coupure tombe EN PLEIN envoi
  const debut = Date.now();
  while (Date.now() - debut < 120000) {
    const st = statutsOperations(A);
    if ((st.synced || 0) >= 15 && (st.pending || 0) > 15) break;
    await pause(300);
  }
  const avant = statutsOperations(A);
  banc.coupureTotale(90000);
  const t0 = Date.now();
  // pendant la coupure : le travail local continue
  const api = await mesurerApiLocale(A, { appels: 5 });
  await creerProduits(A, 10, 'TOT-PENDANT');
  await pause(Math.max(0, 95000 - (Date.now() - t0)));
  const pendant = statutsOperations(A);
  const statutPendant = await A.statutSync().catch(() => null);
  banc.normal();
  const t1 = Date.now();
  const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 900000 }));
  const rap = await surveillance.arreter();
  console.log(`[coupure 90 s] avant : ${JSON.stringify(avant)} ; fin de coupure : ${JSON.stringify(pendant)} ; statut pendant : ${JSON.stringify(statutPendant)} ; ` +
    `API locale pendant la coupure médiane ${api.mediane} ms ; reprise → convergence ${Math.round((Date.now() - t1) / 1000)} s ; banc : ${JSON.stringify(banc.stats)}`);
  assert.ok(api.max < 5000, `l'API locale reste réactive pendant la coupure (max ${api.max} ms)`);
  assert.ok((pendant.pending || 0) > 0, 'des opérations sont restées en attente pendant la coupure');
  await verifierFin(c, A, r, rap, { produits: 90 });
  assert.ok(ids.length === 80);
});

// 7. Alternance rapide marche/arrêt pendant 2 min avec des écritures continues
test('7 alternance marche/arrêt (2 à 5 s) pendant 2 min avec écritures continues', { skip, timeout: 3600000 }, async (t) => {
  const { banc, c } = await campagne(t);
  const { A, B } = c.postes;
  const surveillance = surveillerOperations(A);
  banc.alternance({ marcheMs: [2000, 5000], arretMs: [2000, 5000] });
  const cpu0 = tempsCpuPoste(A);
  const debut = Date.now();
  let n = 0;
  while (Date.now() - debut < 120000) {
    n++;
    const r = await A.api('POST', '/products', { reference: `ALT-${String(n).padStart(4, '0')}`, nom: `Alternance ${n}`, prixUnitaire: 1000, prixAchat: 500, seuilStockMinimum: 1 });
    assert.strictEqual(r.statut, 201);
    if (n % 5 === 0) {
      await A.api('POST', '/inventory/adjust', { produitId: r.corps.data.id, changementQuantite: 10 });
      await A.api('PUT', `/products/${r.corps.data.id}`, { prixUnitaire: 1100 });
    }
    await pause(800);
  }
  const phases = banc.stats.phases;
  banc.arreterAlternance();
  const cpu = (tempsCpuPoste(A) ?? 0) - (cpu0 ?? 0);
  const t1 = Date.now();
  const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 900000 }));
  const rap = await surveillance.arreter();
  console.log(`[alternance] ${n} produits écrits ; ${phases} phases ; banc : ${JSON.stringify(banc.stats)} ; CPU de A pendant les 2 min ${cpu.toFixed(1)} s ; ` +
    `max pending ${rap.max.pending}, max failed ${rap.max.failed} ; convergence après la fin ${Math.round((Date.now() - t1) / 1000)} s`);
  await verifierFin(c, A, r, rap, { produits: n });
  assert.ok(cpu < 100, `le poste ne boucle pas à 100 % de processeur pendant 2 min (CPU ${cpu.toFixed(1)} s sur ~120 s)`);
});

// 9. Perte de connexion pendant la RÉCEPTION (pull) : rien de perdu ni de dupliqué
test('9 perte de connexion pendant la réception : B reçoit tout malgré les coupures', { skip, timeout: 3600000 }, async (t) => {
  // A direct (écrit vite), B derrière le banc : on coupe ce que B REÇOIT
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: ['A', { nom: 'B', ...banc.optionsPoste() }] }));
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  banc.regler({ coupureConnexion: 0.5, coupureMinOctets: 2000, coupureMaxOctets: 40000, coupureRequete: 0.01, latenceMs: 100, debitOctetsParSec: 60000 });
  const surveillanceB = surveillerOperations(B);
  const ids = await creerProduits(A, 80, 'PULL', { stock: 15 });
  await creerVentes(A, ids, 15);
  const t0 = Date.now();
  // l'envoi de A est direct ; on attend qu'il soit fini avant de juger la réception
  const rA = await A.synchroniserJusquaCalme({ delaiMs: 300000 });
  assert.ok(rA.calme, 'A a tout envoyé');
  const apresEnvoi = Date.now() - t0;
  const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 3000000 }));
  const rap = await surveillanceB.arreter();
  const curseur = B.lire('SELECT * FROM sync_pull_state');
  const reprise = Number(B.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n);
  console.log(`[pull coupé] envoi A ${Math.round(apresEnvoi / 1000)} s ; convergence ${Math.round((Date.now() - t0) / 1000)} s ; banc : ${JSON.stringify(banc.stats)} ; ` +
    `file de reprise B : ${reprise} ; curseurs B : ${JSON.stringify(curseur.slice(0, 3), (k, v) => (typeof v === 'bigint' ? Number(v) : v))}`);
  await verifierFin(c, A, r, rap, { produits: 80, ventes: 15 });
  assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM produits')[0].n), 80, 'B a reçu les 80 produits');
  assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM ventes')[0].n), 15, 'B a reçu les 15 ventes');
  assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM details_ventes')[0].n), 15, 'B a reçu les 15 lignes de vente');
});
