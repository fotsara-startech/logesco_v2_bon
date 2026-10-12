/**
 * Liaison GELÉE (★5 « trou noir » de 3 min), poste démarré SANS accès au cloud (★6), latence asymétrique (8).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/23-gel-demarrage-asymetrie.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
// network-faults en premier : il rend les requêtes directes au cloud tolérantes aux micro-coupures de la machine de test
const { avecReprise, BancPannes, statutsOperations, doublonsNaturels, tempsCpuPoste, mesurerApiLocale, lignesReseau, surveillerOperations, pause } = require('../harness/network-faults');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const { requete } = require('../harness/cloud-admin');
const { creerProduits, compterCloud } = require('../harness/charge-reseau');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

const enNombres = (k, v) => (typeof v === 'bigint' ? Number(v) : v);

// ★ 5. « Trou noir » : plus aucun octet pendant 3 minutes
test('★5 trou noir de 3 min : le poste reste réactif en local, le cycle ne reste pas bloqué, reprise propre', { skip, timeout: 3600000 }, async (t) => {
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: [{ nom: 'A', ...banc.optionsPoste() }, 'B'] }));
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const surveillance = surveillerOperations(A);

  // état de départ synchronisé, puis une charge d'écritures en attente au moment du gel
  await creerProduits(A, 10, 'GEL0');
  let r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 400000 }));
  assert.ok(r.ok, `départ non convergent : ${decrire(r.differences)}`);
  await creerProduits(A, 30, 'GEL1');

  const cpu0 = tempsCpuPoste(A);
  const t0 = Date.now();
  banc.trouNoir(180000);
  const echantillons = [];
  const triggers = [];
  let n = 0;
  while (Date.now() - t0 < 185000) {
    const api = await mesurerApiLocale(A, { appels: 3 });
    const ecr0 = Date.now();
    n++;
    const w = await A.api('POST', '/products', { reference: `GEL2-${n}`, nom: `Pendant le gel ${n}`, prixUnitaire: 1000, prixAchat: 500, seuilStockMinimum: 1 }, { delaiMs: 30000 });
    const st = await A.statutSync().catch(() => null);
    echantillons.push({ s: Math.round((Date.now() - t0) / 1000), apiMax: api.max, ecritureMs: Date.now() - ecr0, ecritureStatut: w.statut, mode: st && st.mode, dispo: st && st.cloudAvailable });
    // un clic sur « Synchroniser » pendant le gel : combien de temps l'appel reste-t-il suspendu ?
    if (n % 3 === 1) {
      const d0 = Date.now();
      let issue = 'repondu';
      try { await A.api('POST', '/sync/trigger', {}, { delaiMs: 25000 }); } catch (_) { issue = 'sans réponse après 25 s'; }
      triggers.push({ s: Math.round((d0 - t0) / 1000), ms: Date.now() - d0, issue });
    }
    await pause(8000);
  }
  const cpu = (tempsCpuPoste(A) ?? 0) - (cpu0 ?? 0);
  const journal = lignesReseau(A, 1500);
  const bloque = journal.filter((l) => /bloqué depuis/.test(l));
  const apiMax = Math.max(...echantillons.map((e) => e.apiMax));
  console.log(`[trou noir] CPU de A pendant 3 min ${cpu.toFixed(1)} s ; API locale max ${apiMax} ms ; écritures ${echantillons.filter((e) => e.ecritureStatut === 201).length}/${echantillons.length} ; ` +
    `modes vus ${[...new Set(echantillons.map((e) => `${e.mode}/${e.dispo}`))].join(',')} ; clics « synchroniser » : ${JSON.stringify(triggers)} ; ` +
    `garde-fou 5 min déclenché : ${bloque.length > 0} ; banc : ${JSON.stringify(banc.stats)}\n   journal : ${journal.slice(-6).join(' // ')}`);

  banc.normal();
  const t1 = Date.now();
  r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 900000 }));
  const rap = await surveillance.arreter();
  console.log(`[trou noir] reprise → convergence ${Math.round((Date.now() - t1) / 1000)} s ; max failed ${rap.max.failed}`);

  assert.ok(apiMax < 3000, `les appels API locaux restent rapides pendant le gel (max ${apiMax} ms)`);
  assert.ok(echantillons.every((e) => e.ecritureStatut === 201), 'les écritures locales réussissent pendant le gel');
  assert.ok(cpu < 60, `pas de boucle à 100 % de processeur pendant le gel (CPU ${cpu.toFixed(1)} s en ~185 s)`);
  assert.ok(r.ok, `pas de convergence après le gel : ${decrire(r.differences)}\n${lignesReseau(A).slice(-15).join('\n')}`);
  assert.strictEqual(rap.max.failed, 0, `un gel de liaison a été classé « failed » : ${rap.messages.join(' | ')}`);
  assert.strictEqual(statutsOperations(A).pending || 0, 0);
  const doublons = await doublonsNaturels(A, c.cloudUrl);
  assert.deepStrictEqual(doublons.cloud, {});
  assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), 40 + n);
});

// ★ 6. Poste démarré SANS accès au cloud, puis réseau rétabli
test('★6 poste démarré sans cloud : travail local, identité réservée au retour, aucune opération perdue', { skip, timeout: 3600000 }, async (t) => {
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  banc.coupureTotale(Infinity); // B démarre dans une coupure totale
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: ['A', { nom: 'B', ...banc.optionsPoste() }] }));
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  const surveillance = surveillerOperations(B);

  const identiteAvant = B.identite();
  const statutAvant = await B.statutSync();
  // B (copie de la base de A, sans identité) travaille hors ligne
  const idsB = await creerProduits(B, 6, 'HL-B', { stock: 10 });
  const idsA = await creerProduits(A, 6, 'HL-A', { stock: 10 });
  await pause(20000);
  const statutPendant = await B.statutSync();
  const attenteB = statutsOperations(B);
  console.log(`[démarrage sans cloud] identité de B au démarrage : ${JSON.stringify(identiteAvant, enNombres)} ; mode : ${statutAvant.mode} ; ` +
    `ids créés hors ligne par B : ${idsB.join(',')} ; ids de A : ${idsA.join(',')} ; après 20 s : mode ${statutPendant.mode}, en attente ${JSON.stringify(attenteB)}, erreur : ${statutPendant.lastError && statutPendant.lastError.message}`);

  banc.normal();
  const t1 = Date.now();
  const r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 900000 }));
  const rap = await surveillance.arreter();
  const identiteApres = B.identite();
  const statutApres = await B.statutSync();
  console.log(`[démarrage sans cloud] retour réseau → convergence ${Math.round((Date.now() - t1) / 1000)} s ; identité de B : ${JSON.stringify(identiteApres, enNombres)} ; mode : ${statutApres.mode} ; max failed ${rap.max.failed}`);

  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}\n${lignesReseau(B).slice(-15).join('\n')}`);
  assert.ok(identiteApres && identiteApres.installation_id, 'B a réservé son identité de poste au retour du réseau');
  assert.notStrictEqual(identiteApres.installation_id, A.identite().installation_id, 'identités distinctes');
  assert.strictEqual(statutApres.mode, 'hybrid', 'B est passé en mode hybride');
  const pb = new Set(idsB); const pa = new Set(idsA);
  assert.ok(![...pb].some((i) => pa.has(i)), `identifiants des produits créés hors ligne par B en collision avec A : ${[...pb].filter((i) => pa.has(i))}`);
  assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), 12, 'aucun produit perdu ni écrasé');
  assert.strictEqual(Number(B.lire("SELECT COUNT(*) n FROM produits WHERE reference LIKE 'HL-%'")[0].n), 12);
  assert.strictEqual(rap.max.failed, 0, rap.messages.join(' | '));
  assert.deepStrictEqual((await doublonsNaturels(B, c.cloudUrl)).cloud, {});
});

// 8. Latence asymétrique : A rapide, B très lent, mêmes données modifiées des deux côtés
test('8 latence asymétrique (A direct, B à 3 s) : modifications croisées des mêmes produits', { skip, timeout: 3600000 }, async (t) => {
  const banc = await BancPannes.demarrer();
  t.after(() => banc.arreter());
  const c = await avecReprise(() => nouvelleCampagne({ etiquette: 'reseau', postes: ['A', { nom: 'B', ...banc.optionsPoste() }] }));
  t.after(() => c.terminer());
  const { A, B } = c.postes;
  banc.regler({ latenceMs: 3000, jitterMs: 600 });
  const sA = surveillerOperations(A); const sB = surveillerOperations(B);

  const ids = await creerProduits(A, 8, 'ASY');
  let r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 1200000 }));
  assert.ok(r.ok, `départ non convergent : ${decrire(r.differences)}`);

  // modifications croisées des MÊMES produits, plus des créations de chaque côté
  const t0 = Date.now();
  for (const id of ids) {
    const a = await A.api('PUT', `/products/${id}`, { prixUnitaire: 2000 });
    const b = await B.api('PUT', `/products/${id}`, { prixUnitaire: 3000 });
    assert.ok([200, 201].includes(a.statut) && [200, 201].includes(b.statut), `${a.statut}/${b.statut}`);
  }
  await creerProduits(A, 4, 'ASY-A');
  await creerProduits(B, 4, 'ASY-B');
  r = await avecReprise(() => attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl, delaiMs: 3000000 }));
  const rapA = await sA.arreter(); const rapB = await sB.arreter();
  const prixA = A.lire('SELECT id, prix_unitaire FROM produits WHERE reference LIKE ? ORDER BY id', 'ASY-0%').map((x) => Number(x.prix_unitaire));
  console.log(`[asymétrie] convergence ${Math.round((Date.now() - t0) / 1000)} s ; prix finals sur A : ${prixA.join(',')} ; max failed A ${rapA.max.failed} / B ${rapB.max.failed}`);

  assert.ok(r.ok, `pas de convergence : ${decrire(r.differences)}\n${lignesReseau(B).slice(-12).join('\n')}`);
  assert.strictEqual(rapA.max.failed + rapB.max.failed, 0, `${rapA.messages.concat(rapB.messages).join(' | ')}`);
  assert.strictEqual(await compterCloud(c.cloudUrl, 'produits'), 16);
  assert.deepStrictEqual((await doublonsNaturels(A, c.cloudUrl)).cloud, {});
  assert.ok(prixA.every((p) => p === 2000 || p === 3000), 'chaque prix final est l\'une des deux valeurs écrites');
  assert.ok(new Set(prixA).size >= 1);
});
