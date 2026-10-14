/**
 * Postes HORS LIGNE qui modifient les MÊMES fiches (scénario 2) et cloud injoignable à cause d'un mauvais mot de passe
 * (scénario 9).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/30-fiches-communes.test.js
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

/** Deux postes établis, une fiche produit et une fiche client communes, puis les deux passent hors ligne */
async function preparerFichesCommunes(c) {
  const { A, B } = c.postes;
  const [pid] = await aide.creerProduits(A, 1, 'COM', { stock: 50 });
  const cli = aide.exiger(await A.api('POST', '/customers', { nom: 'Commun', prenom: 'Client', telephone: '699111222' }), [201], 'client commun');
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 240000 });
  assert.ok(r.ok, `mise en place sans convergence : ${decrire(r.autres)}`);
  await mettreHorsLigne(A);
  await mettreHorsLigne(B);
  return { pid, cid: cli.id };
}

/** Modifications hors ligne d'un poste sur les fiches communes */
async function modifierFiches(poste, { pid, cid }, { nom, prix, adresse, description, stock }) {
  const corpsProduit = {};
  if (nom !== undefined) corpsProduit.nom = nom;
  if (prix !== undefined) corpsProduit.prixUnitaire = prix;
  if (description !== undefined) corpsProduit.description = description;
  if (Object.keys(corpsProduit).length) aide.exiger(await poste.api('PUT', `/products/${pid}`, corpsProduit), [200, 201], `PUT produit ${poste.nom}`);
  if (adresse !== undefined) aide.exiger(await poste.api('PUT', `/customers/${cid}`, { adresse }), [200, 201], `PUT client ${poste.nom}`);
  if (stock !== undefined) aide.exiger(await poste.api('POST', '/inventory/adjust', { produitId: pid, changementQuantite: stock, notes: `hors ligne ${poste.nom}` }), [200, 201], `stock ${poste.nom}`);
}

async function reliersUnApresLautre(ordre, c) {
  for (const p of ordre) {
    await relier(p, c);
    const calme = await p.synchroniserJusquaCalme({ delaiMs: 180000 });
    assert.ok(calme.calme, `${p.nom} n'a pas fini d'envoyer : ${JSON.stringify(calme)}`);
  }
}

async function valeursFinales(c, { pid, cid }) {
  const lire = (p) => ({
    nom: p.lire('SELECT nom FROM produits WHERE id = ?', pid)[0].nom,
    prix: Number(p.lire('SELECT prix_unitaire v FROM produits WHERE id = ?', pid)[0].v),
    description: p.lire('SELECT description FROM produits WHERE id = ?', pid)[0].description,
    adresse: p.lire('SELECT adresse FROM clients WHERE id = ?', cid)[0].adresse,
    stock: Number(p.lire('SELECT quantite_disponible v FROM stock WHERE produit_id = ?', pid)[0].v),
  });
  const p = (await requete(c.cloudUrl, 'SELECT nom, prix_unitaire, description FROM produits WHERE id = $1', [pid]))[0];
  const cl = (await requete(c.cloudUrl, 'SELECT adresse FROM clients WHERE id = $1', [cid]))[0];
  const s = (await requete(c.cloudUrl, 'SELECT quantite_disponible FROM stock WHERE produit_id = $1', [pid]))[0];
  const cloud = { nom: p.nom, prix: Number(p.prix_unitaire), description: p.description, adresse: cl.adresse, stock: Number(s.quantite_disponible) };
  return { A: lire(c.postes.A), B: lire(c.postes.B), cloud };
}

test("2. deux postes hors ligne modifient les mêmes fiches, reliés dans l'ordre chronologique : convergence, rien de perdu", { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const fiches = await preparerFichesCommunes(c);

  // A modifie en premier, B ensuite (dates distinctes)
  await modifierFiches(A, fiches, { nom: 'Commun-par-A', prix: 2000, adresse: 'Adresse A' });
  const [soloA] = await aide.creerProduits(A, 1, 'SEULA', { stock: 5 });
  await pause(1500);
  await modifierFiches(B, fiches, { nom: 'Commun-par-B', prix: 3000, adresse: 'Adresse B' });
  const [soloB] = await aide.creerProduits(B, 1, 'SEULB', { stock: 5 });

  await reliersUnApresLautre([A, B], c);
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 400000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);

  const v = await valeursFinales(c, fiches);
  console.log(`   valeurs finales : ${JSON.stringify(v)}`);
  assert.deepStrictEqual(v.A, v.cloud, 'A = cloud');
  assert.deepStrictEqual(v.B, v.cloud, 'B = cloud');
  assert.strictEqual(v.cloud.nom, 'Commun-par-B', "la modification la plus récente (B) l'emporte");
  assert.strictEqual(v.cloud.prix, 3000);
  assert.strictEqual(v.cloud.adresse, 'Adresse B');
  for (const p of [A, B]) {
    assert.strictEqual(aide.idsLocaux(p, 'produits', `WHERE id IN (${soloA}, ${soloB})`).length, 2, `${p.nom} a les deux produits créés hors ligne`);
  }
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon');
});

test("2b. mêmes fiches, reliés dans l'ORDRE INVERSE de la chronologie (le plus ancien pousse en dernier)", { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const fiches = await preparerFichesCommunes(c);

  // chronologie : A modifie en premier, B (plus récent) ensuite ; mais A est relié EN DERNIER
  await modifierFiches(A, fiches, { nom: 'Commun-par-A', prix: 2000, adresse: 'Adresse A', description: 'Description posée par A', stock: 10 });
  await pause(1500);
  await modifierFiches(B, fiches, { nom: 'Commun-par-B', prix: 3000, adresse: 'Adresse B', stock: 5 });

  await reliersUnApresLautre([B, A], c);
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 400000 });
  if (!r.ok) console.log('   ÉTAT DES POSTES (stock) :' + String.fromCharCode(10) + [A, B].map((p) => aide.decrireStock(p)).join(String.fromCharCode(10)));
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  const v = await valeursFinales(c, fiches);
  console.log(`   valeurs finales : ${JSON.stringify(v)}`);

  // strict : tout le monde finit avec la même valeur et aucune ligne n'est perdue
  assert.deepStrictEqual(v.A, v.cloud, 'A = cloud');
  assert.deepStrictEqual(v.B, v.cloud, 'B = cloud');
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), [], 'aucun doublon');

  await t.test("la modification la plus RÉCENTE (B) l'emporte même si elle est poussée avant l'autre", () => {
    assert.strictEqual(v.cloud.nom, 'Commun-par-B');
    assert.strictEqual(v.cloud.prix, 3000);
    assert.strictEqual(v.cloud.adresse, 'Adresse B');
  });
  await t.test('les champs modifiés par des postes différents sont tous conservés (description posée par A, prix par B)', () => {
    assert.strictEqual(v.cloud.description, 'Description posée par A');
    assert.strictEqual(v.cloud.prix, 3000);
  });
  await t.test('le stock cumule les mouvements des deux postes (50 + 10 + 5 = 65)', () => {
    assert.strictEqual(v.cloud.stock, 65);
  });
});

test('9. mot de passe cloud invalide puis corrigé : poste utilisable en local, rien de perdu, bascule en hybride', { skip, timeout: 1500000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'horsligne', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const mauvaise = c.cloud.url.replace(/(\/\/[^:]+:)[^@]+@/, '$1MAUVAIS-MOT-DE-PASSE@');
  assert.notStrictEqual(mauvaise, c.cloud.url, 'la substitution du mot de passe a eu lieu');

  await B.arreter();
  B.cloudUrl = mauvaise;
  await B.demarrer();
  await pause(8000);
  const st = await B.statutSync();
  console.log(`   B (mauvais mot de passe) : mode=${st.mode} cloudAvailable=${st.cloudAvailable} erreur=${JSON.stringify(st.lastError).slice(0, 160)}`);
  assert.strictEqual(st.cloudAvailable, false, "le cloud n'est pas joignable");
  assert.notStrictEqual(st.mode, 'hybrid');

  // utilisable en local
  const produits = await aide.creerProduits(B, 8, 'MDP');
  await aide.creerVentes(B, produits, 3);
  await pause(10000); // plusieurs cycles de synchro à vide
  assert.ok(B.proc, 'le serveur de B est toujours en marche');
  assert.strictEqual((await B.api('GET', '/products?limit=5')).statut, 200, "l'API de B répond");
  assert.ok(B.enAttente() >= 20, `les écritures restent en attente (${B.enAttente()})`);
  assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM operation_log WHERE status = 'failed'")[0].n), 0, "aucune opération marquée « refusée » à cause de l'authentification");

  // mot de passe corrigé
  await relier(B, c);
  const r0 = await aide.attendre(async () => (await B.statutSync()).mode === 'hybrid', { delaiMs: 90000, pauseMs: 2000 });
  assert.ok(r0.ok, 'B bascule en mode hybride après correction');
  const r = await aide.convergenceTolerante({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 400000 });
  assert.ok(r.ok, `pas de convergence : ${decrire(r.autres)}`);
  await aide.signalerPerdus(t, r);
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'produits', `WHERE reference LIKE 'MDP-%'`), produits.length);
  assert.strictEqual(await aide.nombreCloud(c.cloudUrl, 'ventes'), B.lire('SELECT COUNT(*) n FROM ventes')[0].n === undefined ? 0 : Number(B.lire('SELECT COUNT(*) n FROM ventes')[0].n));
  assert.deepStrictEqual(await aide.doublonsCloud(c.cloudUrl), []);
});
