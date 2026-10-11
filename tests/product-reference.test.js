/**
 * Référence automatique des produits : le suffixe de poste évite la collision entre deux postes non synchronisés.
 * Cas réel : PRD20260097 donné au « Système d'alarme » sur le poste principal et à un lustre sur un autre poste.
 *
 * Exécution :  node --test tests/product-reference.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const express = require('express');
const installation = require('../src/utils/installation');
const { prochaineReferenceProduit } = require('../src/utils/product-reference');
const { createProductRouter } = require('../src/routes/products');

test('poste 1 (historique) : format d\'origine, sans suffixe', () => {
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: ['PRD20260001', 'PRD20260097'], suffixe: '' }), 'PRD20260098');
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: [], suffixe: '' }), 'PRD20260001');
});

test('autres postes : l\'identifiant de poste est ajouté', () => {
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: ['PRD20260097'], suffixe: '-P15' }), 'PRD20260098-P15');
});

test('deux postes qui ont le même état local ne produisent JAMAIS la même référence (le défaut d\'origine)', () => {
  const memeEtat = ['PRD20260096'];
  const poste1 = prochaineReferenceProduit({ annee: 2026, references: memeEtat, suffixe: '' });
  const poste10 = prochaineReferenceProduit({ annee: 2026, references: memeEtat, suffixe: '-P10' });
  const poste15 = prochaineReferenceProduit({ annee: 2026, references: memeEtat, suffixe: '-P15' });
  assert.strictEqual(new Set([poste1, poste10, poste15]).size, 3, `${poste1} / ${poste10} / ${poste15}`);
});

test('la séquence continue au plus grand numéro connu, tous postes confondus', () => {
  const refs = ['PRD20260001', 'PRD20260099-P15', 'PRD20260040-P10'];
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: refs, suffixe: '-P17' }), 'PRD20260100-P17');
});

test('une référence saisie à la main qui occupe déjà le numéro est évitée', () => {
  assert.strictEqual(
    prochaineReferenceProduit({ annee: 2026, references: ['PRD20260005', 'PRD20260006-P15'], suffixe: '-P15' }),
    'PRD20260007-P15'
  );
  // la même référence existe déjà telle quelle : on passe au numéro suivant
  assert.notStrictEqual(prochaineReferenceProduit({ annee: 2026, references: ['PRD20260001'], suffixe: '' }), 'PRD20260001');
});

test('références d\'une autre année, ou d\'un autre format : ignorées', () => {
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: ['PRD20259999', 'ABC-1', 'LUSTRE'], suffixe: '' }), 'PRD20260001');
});

test('au-delà de 9999 produits la séquence ne se casse pas (tri numérique, pas alphabétique)', () => {
  assert.strictEqual(prochaineReferenceProduit({ annee: 2026, references: ['PRD20269999', 'PRD202610000'], suffixe: '' }), 'PRD202610001');
});

test('la référence reste dans la limite de saisie de l\'application (20 caractères) même pour le plus grand poste', () => {
  const ref = prochaineReferenceProduit({ annee: 2026, references: ['PRD20269998'], suffixe: '-P214' });
  assert.ok(ref.length <= 20, `${ref} (${ref.length})`);
  assert.match(ref, /^[A-Za-z0-9\-_]+$/, 'caractères acceptés par le formulaire et par la validation du serveur');
});

test('route GET /products/generate-reference : utilise le poste de cette installation', async () => {
  const produits = [{ reference: `PRD${new Date().getFullYear()}0042` }, { reference: 'AUTRE' }];
  const models = { prisma: { produit: { findMany: async () => produits.filter((p) => p.reference.startsWith(`PRD${new Date().getFullYear()}`)) } } };
  const app = express();
  app.use('/p', createProductRouter(models));
  const srv = app.listen(0);
  try {
    const url = `http://127.0.0.1:${srv.address().port}/p/generate-reference`;
    const annee = new Date().getFullYear();

    installation.setInstallationId(null);
    assert.strictEqual((await (await fetch(url)).json()).data.reference, `PRD${annee}0043`, 'poste sans identifiant : format historique');

    installation.setInstallationId(1);
    assert.strictEqual((await (await fetch(url)).json()).data.reference, `PRD${annee}0043`, 'poste 1 : format historique');

    installation.setInstallationId(17);
    assert.strictEqual((await (await fetch(url)).json()).data.reference, `PRD${annee}0043-P17`, 'poste 17 : suffixe de poste');
  } finally {
    installation.setInstallationId(null);
    srv.close();
  }
});
