/**
 * Une modification ordinaire ne réactive pas un produit désactivé dans le cloud ; une réactivation explicite le peut.
 *
 * Cas réel : A désactive un produit, B (qui ne le sait pas encore) modifie son prix et renvoie la ligne avec
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

/** Requête d'écriture envoyée (la création de la colonne d'édition n'est pas celle qu'on veut lire) */
const sqlDe = async (table, operation, data) => {
  const c = fauxClient();
  await service._applyToCloudBrut(c, table, operation, data);
  return c.requetes.find((r) => /^\s*(UPDATE|INSERT)/.test(r.sql));
};

test("UPDATE produit ordinaire : est_actif n'est PAS envoyé (un produit désactivé ailleurs reste désactivé)", async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, nom: 'X', prixUnitaire: 1111, estActif: true });
  assert.ok(!/est_actif/.test(r.sql), "la colonne est_actif n'apparaît pas dans la mise à jour");
  assert.match(r.sql, /"prix_unitaire"/);
});

test('UPDATE avec réactivation explicite : est_actif est envoyé', async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, nom: 'X', estActif: true, __reactivation: true });
  assert.match(r.sql, /"est_actif"/);
  assert.ok(!/__reactivation/.test(r.sql), 'la marque ne part jamais vers le cloud');
});

test('UPDATE qui désactive : toujours envoyé', async () => {
  const r = await sqlDe('produits', 'UPDATE', { id: 1, estActif: false });
  assert.match(r.sql, /"est_actif"/);
  assert.ok(r.params.includes(0), 'valeur 0 (faux) envoyée');
});

test("INSERT (rejeu) d'un produit existant : même règle dans le ON CONFLICT", async () => {
  const r = await sqlDe('produits', 'INSERT', { id: 1, nom: 'X', estActif: true });
  assert.match(r.sql, /"est_actif" = COALESCE\("produits"\."est_actif", TRUE\) AND EXCLUDED\."est_actif"/);
});

test('autres tables (non fusionnables) : inchangées', async () => {
  const r = await sqlDe('user_roles', 'UPDATE', { id: 1, nom: 'Admin', estActif: true });
  assert.doesNotMatch(r.sql, /COALESCE|derniere_edition/);
});
