/**
 * Synchronisation sur liaison LENTE : latence (scénario 1) et faible débit (scénario 2).
 * Le poste A passe par un banc de pannes (harness/network-faults.js) ; B a un accès direct au cloud.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/21-latence-debit.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
// network-faults en premier : il rend les requêtes directes au cloud tolérantes aux micro-coupures de la machine de test
const { avecReprise, BancPannes, statutsOperations, operationsRefusees, doublonsNaturels, tempsCpuPoste, mesurerApiLocale, lignesReseau } = require('../harness/network-faults');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { creerProduits, creerVentes, compterCloud } = require('../harness/charge-reseau');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

async function campagneLente(t) {
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: [{ nom: 'A', ...banc.optionsPoste() }, 'B'] }));
  t.after(() => c.terminer());
  return { banc, c };
}

function verifierEtat(c, A, B, doublons, attendus) {
  const st = statutsOperations(A);
  assert.strictEqual(st.failed || 0, 0, `aucune opération « failed » à tort : ${JSON.stringify(operationsRefusees(A)).slice(0, 600)}`);
  assert.strictEqual(st.pending || 0, 0, `plus rien en attente : ${JSON.stringify(st)}`);
  assert.deepStrictEqual(doublons.poste, {}, 'pas de doublon sur A');
  assert.deepStrictEqual(doublons.cloud, {}, 'pas de doublon dans le cloud');
  return st;
}

// ★ 1. Latence 300 ms, 1 s, 3 s (aller-retour) : 20 produits + 10 ventes sur A
// Charge réduite aux fortes latences : le coût mesuré est d'une quinzaine d'allers-retours par opération (voir le rapport)
const CHARGES = { 0: [10, 5], 300: [10, 5], 1000: [6, 3], 3000: [3, 2] };
for (const latenceMs of [0, 300, 1000, 3000]) {
  const [nProduits, nVentes] = CHARGES[latenceMs];
  test(`★1 latence ${latenceMs} ms : ${nProduits} produits + ${nVentes} ventes sur A convergent avec B`, { skip, timeout: 3600000 }, async (t) => {
    const { banc, c } = await campagneLente(t);
    const { A, B } = c.postes;
    banc.regler({ latenceMs, jitterMs: Math.round(latenceMs * 0.2) });
    const cpu0 = tempsCpuPoste(A);
    const t0 = Date.now();

    const ids = await creerProduits(A, nProduits, `LAT${latenceMs}`, { stock: 50 });
    const ventes = await creerVentes(A, ids, nVentes);
    const ecritures = Date.now() - t0;
    const api = await mesurerApiLocale(A, { appels: 5 });

    const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 3000000 }));
    const duree = Date.now() - t0;
    const cpu = (tempsCpuPoste(A) ?? 0) - (cpu0 ?? 0);
    console.log(`[latence ${latenceMs} ms] écritures locales ${ecritures} ms ; convergence totale ${Math.round(duree / 1000)} s ; ` +
      `API locale pendant la synchro médiane ${api.mediane} ms (max ${api.max}) ; CPU de A ${cpu.toFixed(1)} s ; ` +
      `connexions banc ${banc.stats.acceptees}, envois ${banc.stats.envoisMontants}, opérations ${Object.values(statutsOperations(A)).reduce((a, b) => a + b, 0)}`);

    assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}\n${lignesReseau(A).slice(-15).join('\n')}`);
    const doublons = await doublonsNaturels(A, c.cloudUrl);
    verifierEtat(c, A, B, doublons);
    assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), nProduits, 'les produits sont dans le cloud');
    assert.strictEqual(await compterCloud(c.cloudUrl, 'ventes'), nVentes, 'les ventes sont dans le cloud');
    assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM ventes')[0].n), nVentes, 'les ventes sont sur B');
    assert.ok(ventes.length === nVentes);
  });
}

// ★ 2. Débit très faible (≈ 20 ko/s) pendant l'envoi de 100 produits
test('★2 débit 20 ko/s : 100 produits envoyés et reçus', { skip, timeout: 3600000 }, async (t) => {
  const { banc, c } = await campagneLente(t);
  const { A, B } = c.postes;
  banc.regler({ debitOctetsParSec: 20000, latenceMs: 100 });
  const cpu0 = tempsCpuPoste(A);
  const t0 = Date.now();
  await creerProduits(A, 100, 'DEB');
  const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 3000000 }));
  const duree = Date.now() - t0;
  const cpu = (tempsCpuPoste(A) ?? 0) - (cpu0 ?? 0);
  console.log(`[débit 20 ko/s] convergence ${Math.round(duree / 1000)} s ; octets montants ${banc.stats.octetsMontants}, descendants ${banc.stats.octetsDescendants} ; CPU de A ${cpu.toFixed(1)} s`);
  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}\n${lignesReseau(A).slice(-15).join('\n')}`);
  const doublons = await doublonsNaturels(A, c.cloudUrl);
  verifierEtat(c, A, B, doublons);
  assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), 100);
  assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM produits')[0].n), 100);
});
