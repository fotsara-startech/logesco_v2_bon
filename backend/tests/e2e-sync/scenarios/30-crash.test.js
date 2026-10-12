/**
 * COUPURES DE COURANT (SIGKILL) pendant l'envoi et pendant la réception, puis reprise.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/30-crash.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
require('../harness/aide-reseau');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { pause } = require('../harness/station');
const { requete } = require('../harness/cloud-admin');
const aide = require('../harness/aide-horsligne');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

const nbSynced = (p) => Number(p.lire("SELECT COUNT(*) n FROM operation_log WHERE status = 'synced'")[0].n);

/**
 * Démarre le poste puis le tue (SIGKILL) dès que `mesure()` a progressé de `progresMin` sans être terminé.
 * @returns {{atteint:boolean, progres:number}} atteint=false : le poste a fini (ou n'a pas progressé) avant la coupure
 */
async function demarrerEtCouper(poste, { mesure, progresMin, termine, delaiMs = 120000 }) {
  const avant = mesure();
  const demarrage = poste.demarrer().catch(() => {});
  const debut = Date.now();
  let atteint = false;
  while (Date.now() - debut < delaiMs) {
    if (poste.proc) {
      try {
        if (mesure() - avant >= progresMin && !termine()) { atteint = true; break; }
        if (termine()) break;
      } catch (_) { /* base occupée : on relit */ }
    }
    await pause(60);
  }
  await poste.arreter({ brutal: true });
  await demarrage;
  return { atteint, progres: mesure() - avant };
}

test('3. coupure de courant PENDANT un envoi massif (x3) : aucune opération perdue, aucun doublon, convergence', { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  // B accumule hors ligne
  await B.arreter();
  B.cloudUrl = aide.URL_INJOIGNABLE;
  await B.demarrer();
  const produitsB = await aide.creerProduits(B, 45, 'CRB');
  const ventesB = await aide.creerVentes(B, produitsB, 10);
  const total = B.enAttente();
  console.log(`   B : ${total} opérations en attente avant la reliaison ; ${produitsB.length} produits, ${ventesB.length} ventes ; erreurs API : ${aide.erreursApi.length}`);
  assert.ok(total >= 100, `au moins 100 opérations en attente (${total})`);
  // A travaille en ligne pendant ce temps
  const produitsA = await aide.creerProduits(A, 10, 'CRA');

  // 3 coupures successives, chacune en pleine reliaison
  B.cloudUrl = c.cloud.url;
  let coupures = 0;
  await B.arreter();
  for (let i = 1; i <= 3; i++) {
    const r = await demarrerEtCouper(B, { mesure: () => nbSynced(B), progresMin: 8, termine: () => B.enAttente() <= 5 });
    if (r.atteint) coupures++;
    console.log(`   coupure ${i} : ${r.atteint ? 'en plein envoi' : "hors envoi (le poste a fini ou n'a pas progressé)"} ; +${r.progres} envoyées ; il reste ${B.enAttente()} en attente`);
    assert.strictEqual(B.lire('PRAGMA integrity_check')[0].integrity_check, 'ok', `base SQLite de B intègre après la coupure ${i}`);
  }
  assert.ok(coupures >= 2, `au moins 2 coupures ont bien eu lieu en plein envoi (${coupures}) — sinon le test ne prouve rien`);
  // le cloud ne doit déjà contenir aucun doublon
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon dans le cloud après les coupures');

  await B.demarrer();
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 600000 });
  console.log(`   convergence finale en ${Math.round(r.dureeMs / 1000)} s`);
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);

  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits'), produitsB.length + produitsA.length, 'autant de produits que créés (B + A), ni plus ni moins');
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'ventes'), ventesB.length, 'autant de ventes que créées');
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon dans le cloud');
  const idsCloud = new Set(await aide.idsCloudDe(c.cloudUrl, 'produits'));
  for (const id of [...produitsB, ...produitsA]) assert.ok(idsCloud.has(id), `produit ${id} perdu`);
  const idsV = new Set(await aide.idsCloudDe(c.cloudUrl, 'ventes'));
  for (const id of ventesB) assert.ok(idsV.has(id), `vente ${id} perdue`);
  assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM operation_log WHERE status IN ('pending','failed')")[0].n), 0, 'journal de B vide');
  assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM operation_log WHERE status = 'failed'")[0].n), 0, 'aucune opération refusée');
  const e = await aide.ecartsInexpliques(B);
  assert.strictEqual(e.inexpliques, r.perdus.length, `écart inexpliqué (hors lignes jamais journalisées) : ${aide.resumeEcarts(e.ecarts)}`);
});

test("3b. coupure de courant PENDANT la réception d'un gros lot (x3) : rien de perdu ni de double, curseur cohérent", { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  await A.arreter();
  // 800 produits poussés directement dans le cloud (identifiants hors de toute plage de poste réelle)
  await requete(c.cloudUrl, `INSERT INTO produits (id, reference, nom, prix_unitaire, date_creation, date_modification)
    SELECT 2000000000 + g, 'RCV-' || g, 'Produit reçu ' || g, 1000 + g, NOW(), NOW() FROM generate_series(1, 800) g`);
  const n = () => Number(A.lire("SELECT COUNT(*) n FROM produits WHERE reference LIKE 'RCV-%'")[0].n);
  let coupures = 0;
  for (let i = 1; i <= 3; i++) {
    const r = await demarrerEtCouper(A, { mesure: n, progresMin: 40, termine: () => n() >= 800 });
    if (r.atteint) coupures++;
    console.log(`   coupure ${i} : ${r.atteint ? 'en pleine réception' : 'hors réception'} ; ${n()}/800 reçus`);
    assert.strictEqual(A.lire('PRAGMA integrity_check')[0].integrity_check, 'ok', `base de A intègre après la coupure ${i}`);
  }
  await A.demarrer();
  const ok = await aide.attendre(async () => n() === 800, { delaiMs: 180000 });
  assert.ok(ok.ok, `A doit recevoir les 800 produits (${n()}/800), journal :\n${A.journal(15)}`);
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 300000, tables: ['produits'] });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  assert.strictEqual(Number(A.lire('SELECT COUNT(*) n FROM produits')[0].n), 800);
  assert.strictEqual(Number(A.lire('SELECT COUNT(*) n FROM sync_pull_retry')[0].n), 0, 'rien en file de reprise');
  if (coupures < 2) console.log(`   (limite du test : seulement ${coupures} coupure(s) en pleine réception)`);
});

test('3c. écritures simultanées sur un poste en ligne : aucune écriture perdue, aucune erreur', {
  skip,
  timeout: 900000,
  todo: 'DÉFAUT CONNU : 4 écritures simultanées sur un poste relié au cloud provoquent « database is locked » / « Socket timeout » (HTTP 500) et des erreurs de journalisation avalées (sync-service.js logOperation, catch sans relance) : une ligne peut exister en local sans jamais être envoyée',
}, async (t) => {
  // DÉFAUT CONNU : voir `todo`. Reproduction : 4 POST /products simultanés sur un poste en ligne (cycles de synchro de 3 s
  // dans le harnais ; 30 s en exploitation, donc moins fréquent mais possible avec plusieurs caisses).
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const erreurs = [];
  await aide.enParallele(24, 4, async (i) => {
    const ref = `CON-${String(i).padStart(3, '0')}`;
    const r = await A.api('POST', '/products', { reference: ref, nom: ref, prixUnitaire: 1000, prixAchat: 500, seuilStockMinimum: 1 });
    if (r.statut !== 201) erreurs.push(`${ref} → HTTP ${r.statut}`);
  });
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000, tables: ['produits', 'stock'] });
  const locaux = Number(A.lire("SELECT COUNT(*) n FROM produits WHERE reference LIKE 'CON-%'")[0].n);
  const cloud = await aide.nombreCloud(c.cloudUrl, 'produits', `WHERE reference LIKE 'CON-%'`);
  const e = await aide.ecartsInexpliques(A);
  console.log(`   erreurs HTTP : ${erreurs.length} ; produits locaux ${locaux}, cloud ${cloud} ; écarts : ${aide.resumeEcarts(e.ecarts)}`);
  assert.strictEqual(erreurs.length, 0, `erreurs d'API : ${erreurs.slice(0, 5).join(' ; ')}`);
  assert.strictEqual(cloud, locaux, 'tout ce qui existe en local est dans le cloud');
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
});
