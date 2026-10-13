/**
 * Une modification ordinaire ne réactive pas un produit désactivé dans le cloud ; une réactivation explicite le peut.
 *
 * Cas réel : A désactive un produit, B (qui ne le sait pas encore) modifie son prix et renvoie la ligne entière avec
 * est_actif = vrai : le produit ressuscitait partout.
 *
 * Exécution :  node --test tests/produit-actif-collant.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

process.env.CLOUD_DB_URL = 'postgresql://fake';
const service = require('../src/services/sync-service');

function fauxClient() {
  const requetes = [];
  return { requetes, query: async (sql, params) => { requetes.push({ sql, params }); return { rowCount: 1, rows: [] }; } };
}
const sqlDe = async (table, operation, data) => {
  const c = fauxClient();
  await service._applyToCloudBrut(c, table, operation, data);
  return c.requetes[0];
};

test('UPDATE produit ordinaire : est_actif ne peut pas repasser de faux à vrai', async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, nom: 'X', prixUnitaire: 1111, estActif: true });
  assert.match(r.sql, /"est_actif" = COALESCE\("est_actif", TRUE\) AND \$\d+/);
});

test('UPDATE avec réactivation explicite : est_actif est affecté tel quel', async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, nom: 'X', estActif: true, __reactivation: true });
  assert.doesNotMatch(r.sql, /COALESCE/);
  assert.match(r.sql, /"est_actif" = \$\d+/);
  assert.ok(!/__reactivation/.test(r.sql), 'la marque ne part jamais vers le cloud');
});

test('UPDATE qui désactive : passe toujours (vrai AND faux = faux)', async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, estActif: false });
  assert.match(r.sql, /COALESCE\("est_actif", TRUE\) AND \$1/);
  assert.strictEqual(r.params[0], false);
});

test('INSERT (rejeu) d\'un produit existant : même règle dans le ON CONFLICT', async () => {
  const r = await sqlDe('produits', 'INSERT', { id: 1, nom: 'X', estActif: true });
  assert.match(r.sql, /"est_actif" = COALESCE\("produits"\."est_actif", TRUE\) AND EXCLUDED\."est_actif"/);
});

test('autres tables : inchangées', async () => {
  const r = await sqlDe('clients', 'UPDATE', { id: 1, nom: 'Dupont', estActif: true });
  assert.doesNotMatch(r.sql, /COALESCE/);
});
