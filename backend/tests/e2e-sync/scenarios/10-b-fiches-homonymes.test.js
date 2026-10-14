/**
 * ★2 — Même nom de catégorie, de fournisseur et de boutique créés sur A et B avant toute synchronisation.
 * ★3 — Même client (nom + téléphone) créé sur A et B, puis dette / paiement sur chaque poste : le solde cumulé
 *      de tous les comptes doit être la somme des opérations des deux postes.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/10-b-fiches-homonymes.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire, SPECS_PAR_DEFAUT } = require('../harness/oracle');

// L'historique des écritures de compte est vérifié à part (voir plus bas)
const { transactions_comptes: _tc, ...SPECS_SANS_ECRITURES } = SPECS_PAR_DEFAUT;
const { convergenceRobuste, manuels, creerProduit, ajusterStock, vendre, ok, resoudreTout, cloudSql, decisions } = require('../harness/aide-multi');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

test('★2 même catégorie / fournisseur / boutique saisis sur A et B', { skip, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  for (const st of [A, B]) {
    ok(await st.api('POST', '/categories', { nom: 'Boissons' }));
    ok(await st.api('POST', '/suppliers', { nom: 'Sodiba', telephone: '677001122' }));
    ok(await st.api('POST', '/boutiques', { nom: 'Annexe' }));
    await creerProduit(st, { reference: `CAT-${st.nom}`, nom: `Produit ${st.nom} en Boissons`, categorie: 'Boissons' });
  }

  // Les conflits éventuels sont tranchés comme le ferait l'utilisateur : « même fiche » quand c'est proposé
  const res = await resoudreTout([A, B], (conflit) => {
    const fusion = conflit.options.find((o) => o.id === 'fusionner') || conflit.options.find((o) => o.recommandee) || conflit.options[0];
    return { optionId: fusion.id };
  });
  t.diagnostic(`décisions prises : ${JSON.stringify(res.journal.map((j) => [j.tour, j.poste, j.table, j.optionId, j.statut]))}`);
  assert.ok(!res.incomplet, 'des conflits restent après 6 tours de résolution');

  const r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}`);

  await t.test('catégorie : une seule « Boissons », les deux produits y sont rattachés', async () => {
    const cats = await cloudSql(c, "SELECT id FROM categories WHERE nom = 'Boissons'");
    assert.strictEqual(cats.length, 1, `catégories « Boissons » dans le cloud : ${cats.length}`);
    for (const st of [A, B]) {
      const lignes = st.lire("SELECT p.reference, p.categorie_id, (SELECT COUNT(*) FROM categories WHERE nom = 'Boissons') nb FROM produits p WHERE p.reference LIKE 'CAT-%'");
      assert.strictEqual(lignes.length, 2, `produits attendus sur ${st.nom}`);
      assert.ok(lignes.every((l) => Number(l.categorie_id) === Number(cats[0].id) && Number(l.nb) === 1), `produit non rattaché à la catégorie unique sur ${st.nom} : ${JSON.stringify(lignes)}`);
    }
  });

  await t.test('boutique : une seule « Annexe » après synchronisation (pas de doublon silencieux)', { todo: 'FUSION AUTOMATIQUE NON FAITE (volontaire : décision humaine ; le doublon est SIGNALÉ, voir le sous-test suivant) : deux boutiques « Annexe » coexistent partout (Boutique.nom non unique : aucun refus du cloud ; la fusion par clé naturelle de sync-service.js ~l.802 ne s applique pas)' }, async () => {
    const b = await cloudSql(c, "SELECT id, nom FROM boutiques WHERE nom LIKE 'Annexe%'");
    t.diagnostic(`boutiques « Annexe » dans le cloud : ${JSON.stringify(b)}`);
    assert.strictEqual(b.length, 1, `${b.length} boutiques « Annexe » (doublon non signalé)`);
  });

  await t.test('fournisseur : même nom + même téléphone sur A et B -> une seule fiche (pas de doublon silencieux)', { todo: 'FUSION AUTOMATIQUE NON FAITE (volontaire : décision humaine ; le doublon est SIGNALÉ) : deux fiches « Sodiba » coexistent' }, async () => {
    const f = await cloudSql(c, "SELECT id, nom, telephone FROM fournisseurs WHERE nom = 'Sodiba'");
    t.diagnostic(`fournisseurs « Sodiba » : ${f.length}`);
    assert.strictEqual(f.length, 1, `${f.length} fiches « Sodiba » (doublon non signalé)`);
  });

  await t.test('rien de perdu : chaque poste voit au moins un « Sodiba »', async () => {
    for (const st of [A, B]) {
      assert.ok(Number(st.lire("SELECT COUNT(*) n FROM fournisseurs WHERE nom = 'Sodiba'")[0].n) >= 1);
    }
    const d = await decisions(A);
    t.diagnostic(`décisions restantes : ${d.totalConflits} conflits, ${d.total} cas`);
  });

  // Fusionner seul deux fiches touche à des comptes : l'application ne le fait pas, mais le doublon doit être VISIBLE
  await t.test('les doublons (boutique « Annexe », fournisseur « Sodiba ») sont SIGNALÉS par le contrôle des écarts', async () => {
    const vus = [];
    for (const st of [A, B]) {
      const r = await st.api('GET', '/sync/drift?refresh=1', undefined, { delaiMs: 120000 });
      const groupes = (r.corps && r.corps.data && r.corps.data.doublons) || [];
      vus.push(`${st.nom}: ${groupes.map((g) => `${g.table}×${g.nombre}`).join(',') || 'rien'}`);
      assert.ok(groupes.some((g) => g.table === 'boutiques' && g.nombre >= 2), `boutiques en double non signalées sur ${st.nom} (${vus.join(' ; ')})`);
      assert.ok(groupes.some((g) => g.table === 'fournisseurs' && g.nombre >= 2), `fournisseurs en double non signalés sur ${st.nom} (${vus.join(' ; ')})`);
    }
  });
});

test('★3 même client sur A et B, puis dette et paiement depuis chaque poste : le solde total est conservé', { skip, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  // Produit et stock communs
  const p = await creerProduit(A, { reference: 'DETTE-1', nom: 'Produit à crédit', prix: 1000 });
  await ajusterStock(A, p.id, 1000);
  let r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, specs: SPECS_SANS_ECRITURES });
  assert.ok(r.ok, decrire(r.differences));

  // Même client saisi des deux côtés avant toute synchro
  const ca = ok(await A.api('POST', '/customers', { nom: 'Dupont', prenom: 'Jean', telephone: '699000111' }));
  const cb = ok(await B.api('POST', '/customers', { nom: 'Dupont', prenom: 'Jean', telephone: '699000111' }));

  // Opérations : dette = vente à crédit (solde négatif), paiement = solde qui remonte
  ok(await vendre(A, { produitId: p.id, quantite: 3, clientId: ca.id, credit: true }));
  ok(await A.api('POST', `/customers/${ca.id}/payment`, { montant: 500 }));
  ok(await vendre(B, { produitId: p.id, quantite: 2, clientId: cb.id, credit: true }));
  ok(await B.api('POST', `/customers/${cb.id}/payment`, { montant: 700 }));
  const attendu = -3000 + 500 - 2000 + 700; // -3800

  const solde = (st) => st.lire('SELECT COALESCE(SUM(solde_actuel),0) s, COUNT(*) n FROM comptes_clients')[0];
  assert.strictEqual(Number(solde(A).s), -2500, 'solde local A avant synchro');
  assert.strictEqual(Number(solde(B).s), -1300, 'solde local B avant synchro');

  const res = await resoudreTout([A, B], (conflit) => {
    // compte en double -> on additionne ; fiche -> même fiche
    if (conflit.type === 'compte') return { optionId: 'additionner' };
    const f = conflit.options.find((o) => o.id === 'fusionner');
    return { optionId: (f || conflit.options[0]).id };
  });
  t.diagnostic(`décisions : ${JSON.stringify(res.journal.map((j) => [j.poste, j.table, j.optionId, j.statut]))}`);
  r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, specs: SPECS_SANS_ECRITURES, delaiMs: 240000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}`);

  await t.test('la somme de tous les soldes (cloud et postes) = somme des opérations', async () => {
    const cloud = await cloudSql(c, 'SELECT COALESCE(SUM(solde_actuel),0)::float s, COUNT(*)::int n FROM comptes_clients');
    t.diagnostic(`comptes dans le cloud : ${cloud[0].n}, somme ${cloud[0].s} ; détail ${JSON.stringify(await cloudSql(c, 'SELECT id, client_id, solde_actuel::float s FROM comptes_clients ORDER BY id'))} ; A=${JSON.stringify(A.lire('SELECT id, solde_actuel s FROM comptes_clients'))} ; ecritures A=${JSON.stringify(A.lire('SELECT id, compte_id, type_transaction t, montant m, solde_apres sa FROM transactions_comptes'))}`);
    assert.strictEqual(cloud[0].s, attendu, `somme cloud ${cloud[0].s} au lieu de ${attendu}`);
    for (const st of [A, B]) assert.strictEqual(Number(solde(st).s), attendu, `somme sur ${st.nom}`);
  });

  await t.test('un seul client « Dupont Jean » 699000111 après synchronisation', { todo: 'FUSION AUTOMATIQUE NON FAITE (volontaire : fusionner deux comptes est une décision humaine ; le doublon est SIGNALÉ avec le solde de chaque fiche) : le même client saisi sur deux postes reste deux fiches' }, async () => {
    const n = await cloudSql(c, "SELECT COUNT(*)::int n FROM clients WHERE nom = 'Dupont' AND telephone = '699000111'");
    assert.strictEqual(n[0].n, 1, `${n[0].n} fiches client identiques`);
  });

  await t.test('le client « Dupont Jean » en double est SIGNALÉ par le contrôle des écarts, avec le solde de chaque fiche', async () => {
    for (const st of [A, B]) {
      const r = await st.api('GET', '/sync/drift?refresh=1', undefined, { delaiMs: 120000 });
      const groupes = (r.corps && r.corps.data && r.corps.data.doublons) || [];
      const g = groupes.find((x) => x.table === 'clients');
      assert.ok(g && g.nombre >= 2, `client en double non signalé sur ${st.nom} : ${JSON.stringify(groupes)}`);
      assert.ok(g.fiches.every((f) => f.solde !== null), 'le solde de chaque fiche est affiché pour aider à décider');
    }
  });

  await t.test('les 4 écritures de compte (2 dettes + 2 paiements) sont présentes dans le cloud', async () => {
    const n = await cloudSql(c, 'SELECT type_transaction, COUNT(*)::int n FROM transactions_comptes GROUP BY 1');
    const total = n.reduce((s, x) => s + x.n, 0);
    t.diagnostic(`écritures dans le cloud : ${JSON.stringify(n)} ; locales A=${A.lire('SELECT COUNT(*) n FROM transactions_comptes')[0].n} B=${B.lire('SELECT COUNT(*) n FROM transactions_comptes')[0].n}`);
    assert.strictEqual(total, 4, `${total} écriture(s) dans le cloud au lieu de 4`);
  });
});
