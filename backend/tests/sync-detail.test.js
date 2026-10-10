/**
 * Tests de l'explication des erreurs de synchronisation et de la description des éléments.
 * Exécution : node --test tests/sync-detail.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { classifyError, describeRecord, columnsFromConstraint } = require('../src/services/sync-detail');

test('doublon sur le stock boutique (message PostgreSQL réel du client)', () => {
  const r = classifyError('duplicate key value violates unique constraint "stock_boutiques_boutique_id_produit_id_key"', 'stock_boutiques');
  assert.strictEqual(r.code, 'doublon');
  assert.match(r.explication, /la même boutique et le même produit/);
  assert.match(r.action, /automatiquement/); // résolu par la fusion automatique
});

test('doublon côté réception (message SQLite)', () => {
  const r = classifyError('Raw query failed. Code: `2067`. Message: `UNIQUE constraint failed: stock_boutiques.boutique_id, stock_boutiques.produit_id`', 'stock_boutiques');
  assert.strictEqual(r.code, 'doublon');
  assert.match(r.explication, /la même boutique et le même produit/);
});

test('doublon sur une autre table : pas de promesse de correction automatique', () => {
  const r = classifyError('duplicate key value violates unique constraint "clients_email_key"', 'clients');
  assert.strictEqual(r.code, 'doublon');
  assert.match(r.explication, /le même e-mail/);
  assert.doesNotMatch(r.action, /automatiquement/);
});

test('clé étrangère, réseau, schéma, donnée invalide, inconnue, et vide = en attente', () => {
  assert.strictEqual(classifyError('insert or update on table "ventes" violates foreign key constraint "x"', 'ventes').code, 'dependance');
  assert.strictEqual(classifyError('Connection terminated unexpectedly', 'ventes').code, 'reseau');
  assert.strictEqual(classifyError('column "statut" of relation "ventes" does not exist', 'ventes').code, 'schema');
  assert.strictEqual(classifyError('null value in column "nom" violates not-null constraint', 'produits').code, 'donnee');
  assert.strictEqual(classifyError('quelque chose d\'imprévu', 'ventes').code, 'inconnue');
  assert.strictEqual(classifyError('', 'ventes').code, 'attente');
});

test('colonnes déduites d\'un nom de contrainte', () => {
  assert.deepStrictEqual(columnsFromConstraint('stock_boutiques_boutique_id_produit_id_key', 'stock_boutiques'), ['boutique_id', 'produit_id']);
  assert.deepStrictEqual(columnsFromConstraint('stock_produit_id_key', 'stock'), ['produit_id']);
});

// Faux client local : renvoie un nom selon la table interrogée
const fakePrisma = {
  $queryRawUnsafe: async (sql, id) => {
    if (sql.includes('"produits"')) return id === 3 ? [{ nom: 'LAMPADAIRE SOLAIRE RSK 120' }] : [];
    if (sql.includes('"boutiques"')) return id === 1 ? [{ nom: 'SMART ENERGY SARL' }] : [];
    if (sql.includes('"clients"')) return id === 7 ? [{ nom: 'FOTSARA' }] : [];
    return [];
  },
};

test('description lisible d\'une ligne de stock boutique', async () => {
  const d = await describeRecord(fakePrisma, 'stock_boutiques', { boutique_id: 1, produit_id: 3, quantite_disponible: 52 }, 150000001);
  assert.strictEqual(d, 'LAMPADAIRE SOLAIRE RSK 120 — boutique SMART ENERGY SARL — quantité 52');
});

test('description d\'une vente (payload camelCase accepté) et repli quand le nom est introuvable', async () => {
  const v = await describeRecord(fakePrisma, 'ventes', { numeroVente: 'VTE-1', montantTotal: 50000, clientId: 7 }, 12);
  assert.strictEqual(v, 'VTE-1 — 50000 FCFA — client FOTSARA');
  const s = await describeRecord(fakePrisma, 'stock', { produit_id: 999, quantite_disponible: 5 }, 1);
  assert.strictEqual(s, 'Produit n° 999 — quantité 5');
});

test('doublons NON fusionnés automatiquement : explication dédiée, jamais de promesse de correction automatique', () => {
  const compte = classifyError('duplicate key value violates unique constraint "comptes_clients_client_id_key"', 'comptes_clients');
  assert.strictEqual(compte.code, 'doublon');
  assert.match(compte.titre, /Deux comptes pour le même client/);
  assert.match(compte.explication, /additionnés/);
  assert.doesNotMatch(compte.action, /automatiquement/);
  assert.match(compte.action, /Décisions à prendre/);

  const produit = classifyError('duplicate key value violates unique constraint "produits_reference_key"', 'produits');
  assert.match(produit.titre, /même référence/);
  assert.match(produit.action, /même|différente/);

  const vente = classifyError('duplicate key value violates unique constraint "ventes_numero_vente_key"', 'ventes');
  assert.match(vente.titre, /Même numéro de vente/);
  assert.doesNotMatch(vente.action, /automatiquement/);
});

test('doublons fusionnés automatiquement : villes, zones, affectations, stock', () => {
  for (const [table, c] of [['villes', 'villes_nom_key'], ['zones', 'zones_ville_id_nom_key'], ['user_boutique_assignments', 'user_boutique_assignments_utilisateur_id_boutique_id_key'], ['stock', 'stock_produit_id_key']]) {
    const r = classifyError(`duplicate key value violates unique constraint "${c}"`, table);
    assert.match(r.action, /automatiquement/, table);
  }
});
