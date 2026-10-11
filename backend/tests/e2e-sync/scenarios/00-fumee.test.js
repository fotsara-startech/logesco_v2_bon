/**
 * Scénario « fumée » : deux postes réels et un cloud de test.
 * Valide le harnais lui-même et sert de modèle aux autres scénarios.
 *
 * Exécution (la variable contient l'URL de la base Neon de développement, jamais écrite dans un fichier) :
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/00-fumee.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

test('deux postes : une création sur A arrive sur B, une modification sur B revient sur A', { skip, timeout: 600000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'fumee', postes: ['A', 'B'] });
  t.after(() => c.terminer());
  const { A, B } = c.postes;

  assert.notStrictEqual(A.identite().installation_id, B.identite().installation_id, 'chaque poste a sa propre identité');

  // création sur A
  const cree = await A.api('POST', '/products', { reference: 'FUMEE-1', nom: 'Produit fumée', prixUnitaire: 1500, prixAchat: 1000, seuilStockMinimum: 1 });
  assert.strictEqual(cree.statut, 201, JSON.stringify(cree.corps).slice(0, 300));
  const id = cree.corps.data.id;

  let r = await attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl });
  assert.ok(r.ok, `pas de convergence après création : ${decrire(r.differences)}`);
  const surB = B.lire('SELECT nom, prix_unitaire FROM produits WHERE id = ?', id);
  assert.deepStrictEqual(surB.map((x) => [x.nom, Number(x.prix_unitaire)]), [['Produit fumée', 1500]], 'le produit est arrivé sur B');

  // modification sur B
  const maj = await B.api('PUT', `/products/${id}`, { prixUnitaire: 1800 });
  assert.ok([200, 201].includes(maj.statut), JSON.stringify(maj.corps).slice(0, 300));

  r = await attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl });
  assert.ok(r.ok, `pas de convergence après modification : ${decrire(r.differences)}`);
  assert.strictEqual(Number(A.lire('SELECT prix_unitaire FROM produits WHERE id = ?', id)[0].prix_unitaire), 1800, 'la modification de B est revenue sur A');
});
