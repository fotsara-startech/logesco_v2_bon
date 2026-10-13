/**
 * Le middleware de synchro ne doit pas transformer une DÉSACTIVATION de produit en suppression dans le cloud.
 *
 * Cas réel : DELETE /products/:id sur un produit déjà utilisé répond par le produit désactivé (donc avec des données) ;
 * le middleware y voyait une suppression, l'envoyait au cloud (qui effaçait produit + stock) et annulait la mise à jour.
 *
 * Exécution :  node --test tests/sync-middleware-delete.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

process.env.CLOUD_DB_URL = 'postgresql://fake';
const syncService = require('../src/services/sync-service');
const syncMiddleware = require('../src/middleware/sync-middleware');

function appeler(methode, chemin, corps) {
  const envoyes = [];
  const origine = syncService.enqueue;
  syncService.enqueue = async (table, operation, data) => { envoyes.push([table, operation, data.id]); };
  const res = { json() {} };
  const req = { method: methode, path: chemin };
  syncMiddleware(null)(req, res, () => {});
  res.json(corps);
  syncService.enqueue = origine;
  return envoyes;
}

test('DELETE /products qui désactive le produit : le middleware n\'envoie rien (la route journalise l\'UPDATE)', () => {
  const envoyes = appeler('DELETE', '/api/v1/products/42', { success: true, data: { id: 42, estActif: false } });
  assert.deepStrictEqual(envoyes, []);
});

test('DELETE /products définitif (réponse sans données) : rien non plus, la route journalise le DELETE', () => {
  const envoyes = appeler('DELETE', '/api/v1/products/42', { success: true, data: null });
  assert.deepStrictEqual(envoyes, []);
});

test('PUT /products : toujours journalisé comme une mise à jour', () => {
  const envoyes = appeler('PUT', '/api/v1/products/42', { success: true, data: { id: 42, nom: 'X', estActif: true } });
  assert.deepStrictEqual(envoyes, [['produits', 'UPDATE', 42]]);
});
