/**
 * ★1 — Même RÉFÉRENCE produit saisie à la main sur deux postes avant toute synchronisation
 *      (cas réel : PRD20260097 sur deux postes pour deux produits différents).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/10-a-reference-produit.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { convergenceRobuste, manuels, creerProduit, syncBref, attendreConflits, trancher, ok, cloudSql } = require('../harness/aide-multi');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

test('la génération automatique de référence donne des références distinctes sur A et B', { skip, timeout: 600000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const refA = ok(await A.api('GET', '/products/generate-reference')).reference;
  const refB = ok(await B.api('GET', '/products/generate-reference')).reference;
  assert.notStrictEqual(refA, refB, `A et B proposent la même référence : ${refA}`);
  // et après enregistrement du produit, la suivante est encore distincte entre postes
  await creerProduit(A, { reference: refA, nom: 'Auto A' });
  await creerProduit(B, { reference: refB, nom: 'Auto B' });
  const refA2 = ok(await A.api('GET', '/products/generate-reference')).reference;
  const refB2 = ok(await B.api('GET', '/products/generate-reference')).reference;
  assert.ok(new Set([refA, refB, refA2, refB2]).size === 4, `références non distinctes : ${[refA, refB, refA2, refB2]}`);
  const r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl });
  assert.ok(r.ok, decrire(r.differences));
  const n = await cloudSql(c, 'SELECT COUNT(*)::int n FROM produits');
  assert.strictEqual(n[0].n, 2);
});

test('même référence saisie à la main sur A et B : conflit visible, résolu par « renommer », convergence', { skip, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  const pa = await creerProduit(A, { reference: 'PRD20260097', nom: 'Produit saisi sur A', prix: 1500 });
  const pb = await creerProduit(B, { reference: 'PRD20260097', nom: 'Produit saisi sur B', prix: 2500 });
  assert.notStrictEqual(pa.id, pb.id, 'plages d\'identifiants distinctes');

  // A synchronise d'abord (le cloud reçoit sa fiche), puis B se heurte à la référence déjà prise
  await syncBref(A);
  const vus = await attendreConflits([A, B], { table: 'produits', delaiMs: 90000 });
  assert.ok(vus.length >= 1, 'aucun conflit visible dans GET /decisions (champ conflits) alors que la référence est en double');
  const un = vus[0].conflit;
  assert.ok(un.options.some((o) => o.id === 'renommer'), `option « renommer » absente : ${un.options.map((o) => o.id)}`);

  // On tranche : ce sont deux produits différents -> renommer la fiche du poste concerné
  const faits = [];
  for (const st of [A, B]) {
    const siens = vus.filter((v) => v.poste === st).map((v) => v.conflit);
    faits.push(...await trancher(st, siens, () => ({ optionId: 'renommer' })));
  }
  assert.ok(faits.length >= 1 && faits.every((f) => f.statut === 200), JSON.stringify(faits).slice(0, 500));

  const r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
  assert.ok(r.ok, `pas de convergence après renommage : ${decrire(r.differences)}`);

  const cloud = await cloudSql(c, "SELECT id, reference, nom FROM produits WHERE reference LIKE 'PRD20260097%' ORDER BY id");
  assert.strictEqual(cloud.length, 2, `deux produits attendus dans le cloud : ${JSON.stringify(cloud)}`);
  assert.strictEqual(new Set(cloud.map((x) => x.reference)).size, 2, 'références distinctes');
  assert.deepStrictEqual(cloud.map((x) => x.nom).sort(), ['Produit saisi sur A', 'Produit saisi sur B']);
  for (const st of [A, B]) assert.strictEqual(st.lire("SELECT COUNT(*) n FROM produits WHERE reference LIKE 'PRD20260097%'")[0].n, 2);
  // plus de conflit résiduel
  for (const st of [A, B]) {
    const d = await st.api('GET', '/decisions');
    assert.strictEqual((d.corps.data.conflits || []).length, 0, `conflit résiduel sur ${st.nom}`);
  }
});
