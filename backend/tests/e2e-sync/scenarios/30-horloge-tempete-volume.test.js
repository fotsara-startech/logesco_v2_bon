/**
 * Dérive d'horloge (7), tempête de redémarrages (8), volume (10).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/30-horloge-tempete-volume.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
require('../harness/aide-reseau');
const { execFileSync } = require('node:child_process');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { pause } = require('../harness/station');
const { requete } = require('../harness/cloud-admin');
const aide = require('../harness/aide-horsligne');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

/** Mémoire résidente (Mo) d'un processus, via tasklist (Windows) ou ps */
function rssMo(pid) {
  try {
    if (process.platform === 'win32') {
      const sortie = execFileSync('tasklist', ['/FI', `PID eq ${pid}`, '/NH', '/FO', 'CSV'], { encoding: 'utf8' });
      const champs = sortie.trim().split('","');
      const brut = (champs[champs.length - 1] || '').replace(/[^0-9]/g, '');
      return brut ? Math.round(Number(brut) / 1024) : null; // tasklist donne des Ko
    }
    return Math.round(Number(execFileSync('ps', ['-o', 'rss=', '-p', String(pid)], { encoding: 'utf8' }).trim()) / 1024);
  } catch (_) { return null; }
}

async function etablirCurseurs(c) {
  const { A, B } = c.postes;
  await aide.creerProduits(A, 1, 'BASE');
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
  assert.ok(r.ok, `mise en place sans convergence : ${decrire(r.autres)}`);
}

test("7. dérive d'horloge : un poste à l'horloge AVANCÉE ne doit pas faire « sauter » les mises à jour suivantes", { skip, timeout: 1200000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  await etablirCurseurs(c);
  const [base] = A.lire("SELECT id FROM produits WHERE reference = 'BASE-0001'").map((l) => Number(l.id));

  // un poste dont l'horloge avance d'un jour (et un autre de 2 h) pousse un produit : sa date de modification est dans le futur
  await aide.insererProduitCloud(c.cloudUrl, { id: 2000000201, reference: 'FUTUR-1J', dateMod: "NOW() + INTERVAL '1 day'" });
  await aide.insererProduitCloud(c.cloudUrl, { id: 2000000202, reference: 'FUTUR-2H', dateMod: "NOW() + INTERVAL '2 hours'" });
  // et un autre, à l'horloge en retard de 2 h / 1 jour
  await aide.insererProduitCloud(c.cloudUrl, { id: 2000000203, reference: 'PASSE-2H', dateMod: "NOW() - INTERVAL '2 hours'" });
  await aide.insererProduitCloud(c.cloudUrl, { id: 2000000204, reference: 'PASSE-1J', dateMod: "NOW() - INTERVAL '1 day'" });

  // les lignes à date future sont reçues par le curseur ; les lignes à date passée par le rattrapage (≤ ~2 min)
  const arrivees = await aide.attendre(async () => [A, B].every((p) => Number(p.lire("SELECT COUNT(*) n FROM produits WHERE id BETWEEN 2000000201 AND 2000000204")[0].n) === 4), { delaiMs: 200000, pauseMs: 4000 });
  const manque = [A, B].map((p) => `${p.nom}: ${Number(p.lire('SELECT COUNT(*) n FROM produits WHERE id BETWEEN 2000000201 AND 2000000204')[0].n)}/4`);
  assert.ok(arrivees.ok, `lignes à date décalée jamais reçues : ${manque.join(' ; ')}`);
  const curseur = A.lire("SELECT last_modified_at FROM sync_pull_state WHERE table_name = 'produits'")[0].last_modified_at;
  console.log(`   curseur de réception des produits de A : ${curseur} (maintenant : ${new Date().toISOString()})`);

  // une mise à jour NORMALE ensuite (B modifie un autre produit) doit arriver sur A
  const maj = await B.api('PUT', `/products/${base}`, { prixUnitaire: 4321 });
  assert.ok([200, 201].includes(maj.statut), JSON.stringify(maj.corps).slice(0, 200));

  await t.test("la mise à jour faite après une ligne à date future est reçue par l'autre poste (≤ 3 min)", async () => {
    const recu = await aide.attendre(async () => Number(A.lire('SELECT prix_unitaire v FROM produits WHERE id = ?', base)[0].v) === 4321, { delaiMs: 180000, pauseMs: 4000 });
    assert.ok(recu.ok, `A n'a jamais reçu la mise à jour (prix local ${A.lire('SELECT prix_unitaire v FROM produits WHERE id = ?', base)[0].v}, cloud 4321) ; curseur ${curseur}`);
  });
});

test('8. tempête de redémarrages : 5 redémarrages propres consécutifs pendant que des écritures arrivent, aucune perte', { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const idsA = [];
  const idsB = [];
  for (let i = 1; i <= 5; i++) {
    // A écrit pendant que B redémarre
    const [, ecritA] = await Promise.all([
      B.redemarrer(),
      aide.creerProduits(A, 4, `TEA${i}`, { stock: 20 }),
    ]);
    idsA.push(...ecritA);
    // B écrit dès qu'il est revenu
    idsB.push(...await aide.creerProduits(B, 2, `TEB${i}`, { stock: 20 }));
    console.log(`   tour ${i} : A ${ecritA.length} produits, B en attente ${B.enAttente()}`);
  }
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 400000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  const total = idsA.length + idsB.length;
  assert.ok(idsA.length >= 15 && idsB.length >= 8, `écritures effectuées (${idsA.length} + ${idsB.length}) ; erreurs API : ${aide.erreursApi.slice(0, 3).join(' | ')}`);
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits'), total, 'tous les produits sont dans le cloud, ni plus ni moins');
  for (const p of [A, B]) assert.strictEqual(aide.idsLocaux(p, 'produits').length, total, `${p.nom} a tous les produits`);
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon');
  assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM operation_log WHERE status = 'failed'")[0].n), 0, 'aucune opération refusée');
  const e = await aide.ecartsInexpliques(B);
  assert.strictEqual(e.inexpliques, r.perdus.length, `écart inexpliqué (hors lignes jamais journalisées) : ${aide.resumeEcarts(e.ecarts)}`);
});

test('10. volume : 300 produits + 100 ventes hors ligne, puis envoi massif (durée, mémoire, convergence)', { skip, timeout: 2700000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  await B.arreter();
  B.cloudUrl = aide.URL_INJOIGNABLE;
  await B.demarrer();
  const t0 = Date.now();
  const produits = await aide.creerProduits(B, 120, 'VOL');
  const ventes = await aide.creerVentes(B, produits, 40);
  const attente = B.enAttente();
  console.log(`   hors ligne : ${produits.length} produits + ${ventes.length} ventes en ${Math.round((Date.now() - t0) / 1000)} s ; ${attente} opérations en attente ; erreurs API : ${aide.erreursApi.length} ${aide.erreursApi.slice(0, 2).join(' | ')}`);
  assert.ok(produits.length >= 110, `production de 300 produits hors ligne (${produits.length})`);

  // reliaison + suivi de la mémoire et de la vitesse d'envoi
  await B.arreter();
  B.cloudUrl = c.cloud.url;
  const debut = Date.now();
  const demarrage = B.demarrer({ delaiMs: 600000 });
  let picB = 0;
  let picA = 0;
  const echantillons = [];
  const suivi = (async () => {
    while (true) {
      await pause(5000);
      if (B.proc) picB = Math.max(picB, rssMo(B.proc.pid) || 0);
      if (A.proc) picA = Math.max(picA, rssMo(A.proc.pid) || 0);
      let reste = null;
      try { reste = B.enAttente(); } catch (_) { /* base occupée */ }
      echantillons.push([Math.round((Date.now() - debut) / 1000), reste]);
      if ((reste !== null && reste <= 2) || Date.now() - debut > 1500000) return;
    }
  })();
  await demarrage;
  await suivi;
  const dureeEnvoi = Math.round((Date.now() - debut) / 1000);
  console.log(`   envoi massif : ${dureeEnvoi} s pour ${attente} opérations (${(attente / Math.max(dureeEnvoi, 1)).toFixed(1)} op/s) ; mémoire max B ${picB} Mo, A ${picA} Mo`);
  console.log(`   courbe (s, reste) : ${echantillons.filter((_, i) => i % 6 === 0).map((e) => e.join(':')).join(' ')}`);

  const bloquees = B.lire("SELECT status, substr(error_message,1,110) e, COUNT(*) n FROM operation_log WHERE status IN ('pending','failed') GROUP BY 1,2 ORDER BY n DESC LIMIT 6");
  console.log('   opérations restées bloquées : ' + JSON.stringify(bloquees));
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 600000 });
  console.log(`   convergence complète (envoi + réception par A) ${Math.round((Date.now() - debut) / 1000)} s après la reliaison`);
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits'), produits.length - r.perdus.filter((p) => p.table === 'produits').length, 'tous les produits sont dans le cloud');
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'ventes'), ventes.length - r.perdus.filter((p) => p.table === 'ventes').length, 'toutes les ventes sont dans le cloud');
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon');
  assert.ok(picB === 0 || picB < 800, `mémoire de B raisonnable (${picB} Mo)`);
  assert.ok(dureeEnvoi < 1500, `envoi en moins de 25 min (${dureeEnvoi} s)`);
});
