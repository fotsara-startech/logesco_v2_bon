/**
 * Postes HORS LIGNE : travail accumulé sans cloud, puis reliaison.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/30-hors-ligne.test.js
 *
 * « Hors ligne » = CLOUD_DB_URL pointe vers une adresse qui refuse la connexion (le poste connaît son cloud mais ne le
 * joint pas : coupure Internet) ; le cas « jamais configuré avec un cloud » est testé à part (scénario 1b).
 */
const test = require('node:test');
const assert = require('node:assert');
require('../harness/aide-reseau');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { pause } = require('../harness/station');
const aide = require('../harness/aide-horsligne');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;
const PLAGE = 10000000;

/** Passe un poste hors ligne (cloud injoignable) puis le relance */
async function mettreHorsLigne(poste) {
  await poste.arreter();
  poste.cloudUrl = aide.URL_INJOIGNABLE;
  await poste.demarrer();
}

async function relier(poste, c) {
  await poste.arreter();
  poste.cloudUrl = c.cloud.url;
  await poste.demarrer();
}

test('1. poste établi hors ligne : 50 produits + 20 ventes + mouvements, puis reliaison (plages d\'identifiants, convergence)', { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const idB = B.identite();
  const idA = A.identite();
  assert.ok(idA && idB && idA.installation_id !== idB.installation_id, 'chaque poste a réservé sa plage');

  await mettreHorsLigne(B);

  // A travaille en ligne pendant ce temps
  const produitsA = await aide.creerProduits(A, 15, 'ONA');
  const ventesA = await aide.creerVentes(A, produitsA, 5);

  // B travaille sans cloud
  const produitsB = await aide.creerProduits(B, 50, 'OFFB');
  const ventesB = await aide.creerVentes(B, produitsB, 20);
  await aide.ajusterStocks(B, produitsB.slice(0, 20), 5);

  const enAttente = B.enAttente();
  console.log(`   B hors ligne : ${enAttente} opérations en attente`);
  assert.ok(enAttente >= 100, `les écritures de B sont journalisées hors ligne (${enAttente})`);
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits', `WHERE reference LIKE 'OFFB-%'`), 0, 'rien de B dans le cloud pendant la coupure');

  // plage d'identifiants respectée dès le travail hors ligne
  const debutB = Number(idB.block_start);
  for (const id of [...produitsB, ...ventesB]) assert.ok(id > debutB && id < debutB + PLAGE, `id ${id} hors de la plage de B (${debutB})`);
  const debutA = Number(idA.block_start);
  for (const id of [...produitsA, ...ventesA]) assert.ok(id > debutA && id < debutA + PLAGE, `id ${id} hors de la plage de A (${debutA})`);

  await relier(B, c);
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 600000 });
  console.log(`   convergence en ${Math.round(r.dureeMs / 1000)} s (${r.tours} tour(s))`);
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);

  const perdu = (table) => r.perdus.filter((p) => p.table === table).length;
  const nProduits = produitsA.length + produitsB.length;
  const nVentes = ventesA.length + ventesB.length;
  console.log('   produits ' + nProduits + ', ventes ' + nVentes + ' ; erreurs API : ' + aide.erreursApi.length + ' ' + aide.erreursApi.slice(0, 3).join(' | '));
  assert.ok(produitsB.length >= 45 && ventesB.length >= 15, 'B a bien travaillé hors ligne (' + produitsB.length + ' produits, ' + ventesB.length + ' ventes)');
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits'), nProduits - perdu('produits'), 'tous les produits sont dans le cloud');
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'ventes'), nVentes - perdu('ventes'), 'toutes les ventes sont dans le cloud');
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon dans le cloud');
  // chaque poste possède TOUT
  for (const p of [A, B]) {
    assert.ok(aide.idsLocaux(p, 'produits').length >= nProduits - perdu('produits'), p.nom + ' a tous les produits envoyés');
    assert.ok(aide.idsLocaux(p, 'ventes').length >= nVentes - perdu('ventes'), p.nom + ' a toutes les ventes envoyées');
  }
  const ecarts = await aide.ecartsInexpliques(B);
  assert.strictEqual(ecarts.inexpliques, r.perdus.length, `écart inexpliqué (hors lignes jamais journalisées) sur B : ${aide.resumeEcarts(ecarts.ecarts)}`);
});

test('1b. premier démarrage SANS cloud (CLOUD_DB_URL absent) puis reliaison : les données saisies en local sont envoyées', { skip, timeout: 1500000 }, async (t) => {
  // Défaut n°10, corrigé : en mode « 100 % local », logOperation() ne journalise rien et le poste n'a pas d'identité.
  // Relié ensuite à un cloud, sync-graine.js envoie ses lignes locales sans journal, table par table, quand le cloud
  // n'a aucune ligne dans la table (jamais par-dessus des données d'un autre poste).
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', { nom: 'L', cloud: false, preload: [aide.PRELOAD_SANS_CLOUD] }], demarrer: false });
  t.after(() => c.terminer());
  const { A, L } = c.postes;
  await A.demarrer();
  await L.demarrer();
  assert.strictEqual(L.identite(), null, 'un poste sans cloud n\'a pas d\'identité');

  const produitsL = await aide.creerProduits(L, 10, 'LOC');
  await aide.creerVentes(L, produitsL, 4);
  assert.strictEqual(L.lire('SELECT COUNT(*) n FROM operation_log')[0].n, 0, 'aucun journal en mode local (constat)');

  L.cloudUrl = c.cloud.url;
  L.preload = [];
  await L.redemarrer();
  const attente = await aide.attendre(async () => (await aide.nombreCloud(c.cloudUrl, 'produits', `WHERE reference LIKE 'LOC-%'`)) === 10, { delaiMs: 240000 });
  const ecarts = await aide.ecartsInexpliques(L);
  console.log(`   écarts du poste relié : ${aide.resumeEcarts(ecarts.ecarts)} ; identité : ${JSON.stringify(L.identite())}`);
  assert.ok(attente.ok, `les 10 produits saisis hors cloud ne sont jamais envoyés (écarts : ${aide.resumeEcarts(ecarts.ecarts)})`);
});
