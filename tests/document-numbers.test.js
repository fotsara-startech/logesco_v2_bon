/**
 * Numéros de documents : le suffixe de poste évite que deux postes génèrent le même numéro
 * (clés uniques côté Neon : un doublon n'est jamais synchronisé).
 * Exécution : node --test tests/document-numbers.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const installation = require('../src/utils/installation');
const FinancialMovementService = require('../src/services/financial-movement');

const Service = FinancialMovementService.FinancialMovementService || FinancialMovementService;

test('mouvement financier : suffixe de poste sur les postes autres que le premier', () => {
  const s = new Service(null);
  installation.setInstallationId(15);
  assert.match(s.generateReference(), /^MF-\d{8}-\d{4}-P15$/);
  installation.setInstallationId(2);
  assert.match(s.generateReference(), /^MF-\d{8}-\d{4}-P2$/);
});

test('mouvement financier : le poste 1 garde le format historique', () => {
  const s = new Service(null);
  installation.setInstallationId(1);
  assert.match(s.generateReference(), /^MF-\d{8}-\d{4}$/);
  installation.setInstallationId(null);
  assert.match(s.generateReference(), /^MF-\d{8}-\d{4}$/);
});

test('deux postes ne produisent jamais la même référence, même avec le même tirage aléatoire', () => {
  const realRandom = Math.random;
  Math.random = () => 0.5; // même tirage sur les deux postes
  try {
    const s = new Service(null);
    installation.setInstallationId(14);
    const a = s.generateReference();
    installation.setInstallationId(15);
    const b = s.generateReference();
    assert.notStrictEqual(a, b);
  } finally {
    Math.random = realRandom;
    installation.setInstallationId(null);
  }
});
