/**
 * Garde-fous « produit service » : messages affichés à l'utilisateur.
 * Exécution : node --test tests/service-guard.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { messageProduitService } = require('../src/utils/service-guard');

test('message pour un seul produit : accord au singulier et marche à suivre', () => {
  const m = messageProduitService('DISJONCTEUR COMPACT 250A');
  assert.match(m, /Le produit « DISJONCTEUR COMPACT 250A » est marqué « service »/);
  assert.match(m, /son stock n'est pas géré/);
  assert.match(m, /décochez « service »/);
});

test('message pour plusieurs produits : accord au pluriel', () => {
  const m = messageProduitService(['A', 'B']);
  assert.match(m, /Les produits « A », « B » sont marqués « service »/);
  assert.match(m, /leur stock n'est pas géré/);
});

test('message sans nom : reste lisible', () => {
  assert.match(messageProduitService(null), /Le produit « sélectionné » est marqué « service »/);
});
