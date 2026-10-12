/**
 * 8 — Installation d'un 2ᵉ poste (installation neuve, baseline « independant ») sur un cloud déjà alimenté par le 1ᵉʳ.
 * 9 — Numéros de documents (commande d'approvisionnement) générés le même jour sur deux postes : pas de doublon.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/10-d-numeros-et-installation.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer, copierVersCloud } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { convergenceRobuste, manuels, creerProduit, ajusterStock, ok, resoudreTout, cloudSql, decisions } = require('../harness/aide-multi');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

test('9 commandes d\'approvisionnement créées le même jour sur A et B : numéros distincts', { skip, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: manuels('A', 'B') });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  const four = ok(await A.api('POST', '/suppliers', { nom: 'Fournisseur commun', telephone: '655000001' }));
  const p = await creerProduit(A, { reference: 'CMD-P1', nom: 'Produit commandé' });
  let r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl });
  assert.ok(r.ok, decrire(r.differences));

  const commander = (st) => st.api('POST', '/procurement', { fournisseurId: four.id, modePaiement: 'credit', details: [{ produitId: p.id, quantiteCommandee: 5, coutUnitaire: 400 }] });
  const ra = await commander(A);
  const rb = await commander(B);
  const na = ra.corps.data?.numeroCommande || ra.corps.data?.commande?.numeroCommande;
  const nb = rb.corps.data?.numeroCommande || rb.corps.data?.commande?.numeroCommande;
  t.diagnostic(`numéros : A=${na} B=${nb} (HTTP ${ra.statut}/${rb.statut})`);
  assert.ok([200, 201].includes(ra.statut) && [200, 201].includes(rb.statut), `création refusée : ${JSON.stringify(ra.corps).slice(0, 200)} / ${JSON.stringify(rb.corps).slice(0, 200)}`);

  await t.test('les deux postes produisent des numéros de commande différents', {
    todo: 'DÉFAUT CONNU : routes/procurement.js generateNumeroCommande() (CMDaaaammjjNNN) n\'ajoute pas installation.documentSuffix() : deux postes donnent le même numéro le même jour',
  }, () => {
    assert.notStrictEqual(na, nb, `numéro identique sur A et B : ${na}`);
  });

  await t.test('après synchronisation : deux commandes partout, convergence (conflit résolu si nécessaire)', async () => {
    const res = await resoudreTout([A, B], () => ({ optionId: 'renommer' }));
    t.diagnostic(`décisions : ${JSON.stringify(res.journal.map((j) => [j.poste, j.table, j.optionId, j.statut]))}`);
    r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
    assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}`);
    const n = await cloudSql(c, 'SELECT numero_commande FROM commandes_approvisionnement');
    assert.strictEqual(n.length, 2, `commandes dans le cloud : ${JSON.stringify(n)}`);
    for (const st of [A, B]) assert.strictEqual(Number(st.lire('SELECT COUNT(*) n FROM commandes_approvisionnement')[0].n), 2, `commandes sur ${st.nom}`);
  });
});

test('8 installation d\'un 2ᵉ poste neuf sur un cloud déjà alimenté par le 1ᵉʳ', { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'multi', postes: ['A', 'B'], baseline: 'independant', demarrer: false });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  // 1er poste : installation, quelques données, tout est envoyé au cloud
  await A.demarrer();
  // Client établi : le cloud possède déjà les données de base du 1er poste. (Sans cela, une installation neuve sur un cloud
  // vide ne pousse jamais sa boutique de base : stock_boutiques est alors refusé par clé étrangère -- voir le rapport.)
  await copierVersCloud(A, c.cloudUrl);
  const p = await creerProduit(A, { reference: 'INSTALL-1', nom: 'Produit du premier poste', prix: 1200 });
  await ajusterStock(A, p.id, 40);
  ok(await A.api('POST', '/customers', { nom: 'Client historique', telephone: '690000009' }));
  const calmeA = await A.synchroniserJusquaCalme({ delaiMs: 180000 });
  assert.ok(calmeA.calme, `le 1er poste n arrive pas au calme : ${JSON.stringify(calmeA)} ${JSON.stringify(A.lire("SELECT table_name, record_id, operation_type, status, error_message FROM operation_log WHERE status IN ('pending','failed')"))}`);

  // 2e poste : installation neuve (crée son propre ADMIN, sa boutique, sa caisse, son utilisateur admin), puis se relie au cloud
  await B.demarrer();
  const debut = Date.now();
  const res = await resoudreTout([A, B], (conflit, st) => {
    t.diagnostic(`conflit sur ${st.nom} : ${conflit.table} « ${conflit.cle.valeur} » options=${conflit.options.map((o) => o.id)}`);
    const f = conflit.options.find((o) => o.id === 'fusionner');
    if (conflit.type === 'compte') return { optionId: 'additionner' };
    return { optionId: (f || conflit.options.find((o) => o.recommandee) || conflit.options[0]).id };
  }, { delaiMs: 90000 });
  t.diagnostic(`ÉTAPES pour l'utilisateur : ${res.journal.length} décision(s) en ${res.tours} tour(s) : ${JSON.stringify(res.journal.map((j) => [j.poste, j.table, j.optionId, j.statut]))}`);

  await t.test('toutes les décisions proposées sont applicables (HTTP 200) et il n\'en reste aucune', () => {
    assert.ok(!res.incomplet, 'des conflits restent après 6 tours');
    for (const j of res.journal) assert.strictEqual(j.statut, 200, `${j.table} ${j.optionId} : ${JSON.stringify(j.corps).slice(0, 300)}`);
  });

  const r = await convergenceRobuste({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 300000 });
  t.diagnostic(`durée de la mise en convergence : ${Math.round((Date.now() - debut) / 1000)} s`);
  await t.test('convergence finale des deux postes et du cloud', () => {
    assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}`);
  });

  t.diagnostic(`stock du produit INSTALL-1 : A=${JSON.stringify(A.lire('SELECT quantite_disponible q FROM stock WHERE produit_id = ?', p.id))} B=${JSON.stringify(B.lire('SELECT quantite_disponible q FROM stock WHERE produit_id = ?', p.id))} cloud=${JSON.stringify(await cloudSql(c, 'SELECT quantite_disponible::int q FROM stock WHERE produit_id = $1', [p.id]))} mouvements A=${JSON.stringify(A.lire('SELECT type_mouvement t, changement_quantite q, stock_final f FROM mouvements_stock WHERE produit_id = ?', p.id))}`);
  await t.test('le poste B voit le produit, le stock et le client du poste A', {}, () => {
    assert.strictEqual(Number(B.lire('SELECT COUNT(*) n FROM produits WHERE reference = ?', 'INSTALL-1')[0].n), 1);
    assert.strictEqual(Number(B.lire('SELECT quantite_disponible q FROM stock WHERE produit_id = ?', p.id)[0]?.q), 40);
    assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM clients WHERE nom = 'Client historique'")[0].n), 1);
  });

  await t.test('pas de doublon des données de base (ADMIN, boutique principale, caisse, admin)', async () => {
    const q = async (sql) => Number((await cloudSql(c, sql))[0].n);
    const vus = {
      adminRoles: await q("SELECT COUNT(*)::int n FROM user_roles WHERE nom = 'admin' OR nom = 'ADMIN'"),
      boutiques: await q('SELECT COUNT(*)::int n FROM boutiques'),
      caisses: await q('SELECT COUNT(*)::int n FROM cash_registers'),
      utilisateurs: await q('SELECT COUNT(*)::int n FROM utilisateurs'),
    };
    t.diagnostic(`données de base dans le cloud : ${JSON.stringify(vus)}`);
    assert.strictEqual(vus.adminRoles, 1, 'rôle ADMIN en double');
    assert.strictEqual(vus.utilisateurs, 1, 'utilisateur admin en double');
    assert.ok(vus.boutiques >= 1 && vus.caisses >= 1);
  });

  await t.test('rien à décider une fois l\'installation terminée', async () => {
    for (const st of [A, B]) {
      const d = await decisions(st);
      assert.strictEqual(d.totalConflits, 0, `conflits restants sur ${st.nom}`);
    }
  });
});
