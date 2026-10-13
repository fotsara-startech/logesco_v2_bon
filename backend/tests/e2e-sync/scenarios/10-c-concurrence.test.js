/**
 * Concurrence entre trois postes :
 *  ★4 ventes simultanées du même produit (A, B, C) : stock final = stock initial - total vendu (aucune mise à jour perdue)
 *  ★5 modification simultanée du prix : tous convergent vers la même valeur, sans oscillation
 *  ★6 création massive simultanée : 3 x 20 produits -> 60 partout, aucun doublon, identifiants dans la plage du poste
 *  ★7 suppression sur A pendant que B modifie : état final cohérent, pas de résurrection
 *   9 numéros de vente : aucun doublon malgré des ventes dans la même seconde
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/10-c-concurrence.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { pause } = require('../harness/station');
const { convergenceRobuste, manuels, creerProduit, ajusterStock, vendre, ok, cloudSql } = require('../harness/aide-multi');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

const stockDe = (st, produitId) => Number(st.lire('SELECT quantite_disponible q FROM stock WHERE produit_id = ?', produitId)[0]?.q);

async function converger(c, stations, delaiMs = 300000) {
  const r = await convergenceRobuste({ stations, cloudUrl: c.cloudUrl, delaiMs });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}`);
  return r;
}

for (const mode of ['manuel', 'automatique']) {
  test(`★4 ventes simultanées du même produit depuis A, B et C (synchro ${mode})`, { skip, timeout: 1200000 }, async (t) => {
    const postes = mode === 'manuel' ? manuels('A', 'B', 'C') : ['A', 'B', 'C'];
    const c = await nouvelleCampagne({ etiquette: 'multi', postes });
    t.after(() => c.terminer());
    const { A, B, C } = c.postes;
    const tous = [A, B, C];

    const p = await creerProduit(A, { reference: `VENTE-${mode}`, nom: 'Produit vendu partout', prix: 1000 });
    await ajusterStock(A, p.id, 300);
    await converger(c, tous);
    for (const st of tous) assert.strictEqual(stockDe(st, p.id), 300, `stock initial sur ${st.nom}`);

    // A : 5 ventes de 3 (15) ; B : 4 ventes de 5 (20) ; C : 3 ventes de 7 (21) -> 56 vendus, en parallèle
    const lot = async (st, nb, q) => { for (let i = 0; i < nb; i++) ok(await vendre(st, { produitId: p.id, quantite: q })); };
    await Promise.all([lot(A, 5, 3), lot(B, 4, 5), lot(C, 3, 7)]);
    assert.strictEqual(stockDe(A, p.id), 285);
    assert.strictEqual(stockDe(B, p.id), 280);
    assert.strictEqual(stockDe(C, p.id), 279);

    const conv = await convergenceRobuste({ stations: tous, cloudUrl: c.cloudUrl, delaiMs: 300000 });
    await t.test('convergence des trois postes et du cloud après les ventes', () => {
      assert.ok(conv.ok, decrire(conv.differences));
    });
    const attendu = 300 - 56;
    const cloud = await cloudSql(c, 'SELECT quantite_disponible::int q FROM stock WHERE produit_id = $1', [p.id]);
    const vus = { cloud: cloud[0].q, A: stockDe(A, p.id), B: stockDe(B, p.id), C: stockDe(C, p.id) };
    t.diagnostic(`stock final ${JSON.stringify(vus)} (attendu ${attendu})`);

    await t.test('stock final partout = stock initial - total vendu (aucune mise à jour perdue)', () => {
      assert.deepStrictEqual(vus, { cloud: attendu, A: attendu, B: attendu, C: attendu });
    });

    await t.test('12 ventes partout, numéros de vente tous distincts (suffixe de poste)', async () => {
      const nums = await cloudSql(c, 'SELECT numero_vente FROM ventes');
      assert.strictEqual(nums.length, 12, `ventes dans le cloud : ${nums.length}`);
      assert.strictEqual(new Set(nums.map((n) => n.numero_vente)).size, 12, 'numéros de vente en double');
      for (const st of tous) assert.strictEqual(Number(st.lire('SELECT COUNT(*) n FROM ventes')[0].n), 12, `ventes sur ${st.nom}`);
    });

    await t.test('mouvements de stock : somme des changements = -56 dans le cloud', async () => {
      const m = await cloudSql(c, "SELECT COALESCE(SUM(changement_quantite),0)::int s FROM mouvements_stock WHERE produit_id = $1 AND changement_quantite < 0", [p.id]);
      t.diagnostic(`somme des mouvements de vente : ${m[0].s}`);
      assert.strictEqual(m[0].s, -56);
    });
  });
}

test('★5 modification simultanée du prix d\'un même produit sur A et B', { skip, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const p = await creerProduit(A, { reference: 'PRIX-1', nom: 'Produit au prix disputé', prix: 1000 });
  await converger(c, [A, B]);

  await t.test('B écrit après A (dernière écriture) : 2200 partout, stable', async () => {
    ok(await A.api('PUT', `/products/${p.id}`, { prixUnitaire: 1800 }));
    await pause(1500);
    ok(await B.api('PUT', `/products/${p.id}`, { prixUnitaire: 2200 }));
    // l'ordre de synchronisation est l'inverse de l'ordre d'écriture : B (le plus récent) envoie d'abord
    await B.synchroniserJusquaCalme({ delaiMs: 60000 });
    await A.synchroniserJusquaCalme({ delaiMs: 60000 });
    await converger(c, [A, B]);
    const vus = [A, B].map((st) => Number(st.lire('SELECT prix_unitaire p FROM produits WHERE id = ?', p.id)[0].p));
    const cloud = Number((await cloudSql(c, 'SELECT prix_unitaire::float p FROM produits WHERE id = $1', [p.id]))[0].p);
    assert.deepStrictEqual([...vus, cloud], [2200, 2200, 2200], `prix finaux A/B/cloud : ${[...vus, cloud]}`);
    // pas d'oscillation : après deux cycles supplémentaires, rien n'a bougé
    await pause(8000);
    await converger(c, [A, B]);
    assert.deepStrictEqual([A, B].map((st) => Number(st.lire('SELECT prix_unitaire p FROM produits WHERE id = ?', p.id)[0].p)), [2200, 2200], 'le prix a oscillé');
  });

  await t.test('écritures vraiment simultanées : même valeur finale partout, sans oscillation', async () => {
    await Promise.all([
      A.api('PUT', `/products/${p.id}`, { prixUnitaire: 3100 }),
      B.api('PUT', `/products/${p.id}`, { prixUnitaire: 3300 }),
    ]);
    await Promise.all([A.synchroniserJusquaCalme({ delaiMs: 60000 }), B.synchroniserJusquaCalme({ delaiMs: 60000 })]);
    await converger(c, [A, B]);
    const lire = async () => [
      ...[A, B].map((st) => Number(st.lire('SELECT prix_unitaire p FROM produits WHERE id = ?', p.id)[0].p)),
      Number((await cloudSql(c, 'SELECT prix_unitaire::float p FROM produits WHERE id = $1', [p.id]))[0].p),
    ];
    const avant = await lire();
    assert.strictEqual(new Set(avant).size, 1, `valeurs différentes : ${avant}`);
    assert.ok([3100, 3300].includes(avant[0]), `valeur inattendue ${avant[0]}`);
    await pause(8000);
    await converger(c, [A, B]);
    assert.deepStrictEqual(await lire(), avant, 'le prix a oscillé après stabilisation');
  });
});

test('★6 création massive simultanée : 3 x 20 produits', { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B', 'C') });
  t.after(() => c.terminer());
  const tous = Object.values(c.postes);

  await Promise.all(tous.map(async (st) => {
    for (let i = 1; i <= 20; i++) {
      await creerProduit(st, { reference: `MASSE-${st.nom}-${String(i).padStart(2, '0')}`, nom: `Masse ${st.nom} ${i}`, prix: 500 + i });
    }
  }));
  await converger(c, tous, 420000);

  const cloud = await cloudSql(c, "SELECT id, reference FROM produits WHERE reference LIKE 'MASSE-%'");
  assert.strictEqual(cloud.length, 60, `produits dans le cloud : ${cloud.length}`);
  assert.strictEqual(new Set(cloud.map((x) => x.reference)).size, 60, 'doublons de référence');
  for (const st of tous) {
    assert.strictEqual(Number(st.lire("SELECT COUNT(*) n FROM produits WHERE reference LIKE 'MASSE-%'")[0].n), 60, `produits sur ${st.nom}`);
    assert.strictEqual(Number(st.lire("SELECT COUNT(DISTINCT reference) n FROM produits WHERE reference LIKE 'MASSE-%'")[0].n), 60, `doublons sur ${st.nom}`);
    assert.strictEqual(Number(st.lire("SELECT COUNT(*) n FROM stock s JOIN produits p ON p.id = s.produit_id WHERE p.reference LIKE 'MASSE-%'")[0].n), 60, `lignes de stock sur ${st.nom}`);
  }
  // identifiants dans la plage du poste créateur
  for (const st of tous) {
    const debut = Number(st.identite().block_start);
    const siens = cloud.filter((x) => x.reference.startsWith(`MASSE-${st.nom}-`));
    assert.strictEqual(siens.length, 20);
    for (const x of siens) assert.ok(Number(x.id) >= debut && Number(x.id) < debut + 10000000, `produit ${x.reference} id ${x.id} hors de la plage de ${st.nom} (${debut})`);
  }
});

test('★7 suppression sur A pendant que B modifie : état cohérent, pas de résurrection', { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const x1 = await creerProduit(A, { reference: 'SUPPR-1', nom: 'Supprimé puis modifié ailleurs', prix: 1000 });
  const x2 = await creerProduit(A, { reference: 'SUPPR-2', nom: 'Modifié puis supprimé ailleurs', prix: 1000 });
  await converger(c, [A, B]);

  // X1 : A supprime d'abord, B modifie ensuite (écriture B plus récente que la suppression)
  const d1 = await A.api('DELETE', `/products/${x1.id}`);
  assert.ok([200, 204].includes(d1.statut), JSON.stringify(d1.corps).slice(0, 300));
  await pause(1500);
  ok(await B.api('PUT', `/products/${x1.id}`, { prixUnitaire: 1111 }));
  // X2 : B modifie d'abord, A supprime ensuite
  ok(await B.api('PUT', `/products/${x2.id}`, { prixUnitaire: 2222 }));
  await pause(1500);
  const d2 = await A.api('DELETE', `/products/${x2.id}`);
  assert.ok([200, 204].includes(d2.statut), JSON.stringify(d2.corps).slice(0, 300));

  // A envoie en premier, puis B
  await A.synchroniserJusquaCalme({ delaiMs: 60000 });
  await B.synchroniserJusquaCalme({ delaiMs: 60000 });
  const conv = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 150000 });
  await t.test('convergence postes / cloud après suppression + modification', () => {
    assert.ok(conv.ok, decrire(conv.differences));
  });

  const etat = async (id) => ({
    cloud: (await cloudSql(c, 'SELECT est_actif, prix_unitaire::float p FROM produits WHERE id = $1', [id]))[0] || null,
    A: A.lire('SELECT est_actif, prix_unitaire p FROM produits WHERE id = ?', id)[0] || null,
    B: B.lire('SELECT est_actif, prix_unitaire p FROM produits WHERE id = ?', id)[0] || null,
  });
  const e1 = await etat(x1.id);
  const e2 = await etat(x2.id);
  t.diagnostic(`X1 (suppr. puis modif.) : ${JSON.stringify(e1)}`);
  t.diagnostic(`X2 (modif. puis suppr.) : ${JSON.stringify(e2)}`);
  const present = (e) => [e.cloud, e.A, e.B].map((l) => !!l && !!Number(l.est_actif));

  await t.test('X2 (modifié puis supprimé) : absent / désactivé partout', () => {
    assert.deepStrictEqual(present(e2), [false, false, false], JSON.stringify(e2));
  });
  await t.test('X1 (supprimé puis modifié ailleurs) : état identique partout', () => {
    assert.strictEqual(new Set(present(e1)).size, 1, `états divergents : ${JSON.stringify(e1)}`);
  });
  await t.test('X1 (supprimé sur A, modifié ensuite sur B) ne ressuscite pas', { todo: 'DÉFAUT CONNU n°6 (écriture de ligne entière) : B, qui ne connaît pas encore la désactivation, modifie le prix et renvoie la ligne entière avec est_actif=1 : la désactivation de A est écrasée (le produit ressuscite partout, prix 1111)' }, () => {
    assert.deepStrictEqual(present(e1), [false, false, false], `résurrection : ${JSON.stringify(e1)}`);
  });
});
