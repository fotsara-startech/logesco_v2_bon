/**
 * Tests du règlement d'une vente (avance, dette, monnaie).
 * Exécution : node --test tests/sale-settlement.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { computeSaleSettlement } = require('../src/services/sale-settlement');

const s = (p) => computeSaleSettlement({ hasClient: true, ...p });

test('client sans dette ni avance, paiement exact', () => {
  const r = s({ soldeAvant: 0, montantVenteTotal: 10000, montantVerse: 10000 });
  assert.strictEqual(r.soldeApres, 0);
  assert.strictEqual(r.mode, 'comptant');
  assert.strictEqual(r.monnaieARendre, 0);
  assert.strictEqual(r.especesConservees, 10000);
});

test('monnaie rendue : la caisse ne garde que le montant de la vente', () => {
  const r = s({ soldeAvant: 0, montantVenteTotal: 1500, montantVerse: 6500 });
  assert.strictEqual(r.monnaieARendre, 5000);
  assert.strictEqual(r.especesConservees, 1500);
  assert.strictEqual(r.soldeApres, 0);
});

test('pas de monnaie : le reste est AJOUTÉ au solde du client', () => {
  const r = s({ soldeAvant: 0, montantVenteTotal: 9000, montantVerse: 10000, resteVersSolde: true });
  assert.strictEqual(r.ajouteAuSolde, 1000);
  assert.strictEqual(r.monnaieARendre, 0);
  assert.strictEqual(r.especesConservees, 10000);
  assert.strictEqual(r.soldeApres, 1000);
});

test('vente anonyme : l\'option "ajouter au solde" est ignorée, la monnaie est rendue', () => {
  const r = computeSaleSettlement({ hasClient: false, soldeAvant: 0, montantVenteTotal: 9000, montantVerse: 10000, resteVersSolde: true });
  assert.strictEqual(r.ajouteAuSolde, 0);
  assert.strictEqual(r.monnaieARendre, 1000);
  assert.strictEqual(r.soldeApres, 0);
});

test('BUG CORRIGÉ : une avance existante n\'est plus effacée par une vente payée comptant', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 20000, montantVerse: 20000 });
  assert.strictEqual(r.avanceUtilisee, 0);
  assert.strictEqual(r.soldeApres, 30000);
  assert.strictEqual(r.mode, 'comptant');
});

test('avance qui couvre toute la vente (aucun espèce)', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 20000, montantVerse: 0 });
  assert.strictEqual(r.avanceUtilisee, 20000);
  assert.strictEqual(r.especesConservees, 0);
  assert.strictEqual(r.soldeApres, 10000);
  assert.strictEqual(r.mode, 'comptant');
  assert.strictEqual(r.montantPayePourCetteVente, 20000);
});

test('avance + complément en espèces', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 50000, montantVerse: 20000 });
  assert.strictEqual(r.avanceUtilisee, 30000);
  assert.strictEqual(r.soldeApres, 0);
  assert.strictEqual(r.mode, 'comptant');
  assert.strictEqual(r.montantRestant, 0);
});

test('avance insuffisante et espèces insuffisantes : le reste devient dette', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 50000, montantVerse: 10000 });
  assert.strictEqual(r.avanceUtilisee, 30000);
  assert.strictEqual(r.montantRestant, 10000);
  assert.strictEqual(r.mode, 'credit');
  assert.strictEqual(r.soldeApres, -10000);
});

test('excédent avec avance existante, monnaie rendue : avance préservée', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 20000, montantVerse: 25000 });
  assert.strictEqual(r.monnaieARendre, 5000);
  assert.strictEqual(r.soldeApres, 30000);
});

test('excédent avec avance existante, ajouté au solde', () => {
  const r = s({ soldeAvant: 30000, montantVenteTotal: 20000, montantVerse: 25000, resteVersSolde: true });
  assert.strictEqual(r.soldeApres, 35000);
});

test('dette existante, paiement partiel (comportement historique inchangé)', () => {
  const r = s({ soldeAvant: -10000, montantVenteTotal: 20000, montantVerse: 15000 });
  assert.strictEqual(r.montantTotalAPayer, 30000);
  assert.strictEqual(r.soldeApres, -15000);
  assert.strictEqual(r.mode, 'credit');
  assert.strictEqual(r.montantRestant, 15000);
});

test('dette existante soldée avec excédent rendu (comportement historique)', () => {
  const r = s({ soldeAvant: -10000, montantVenteTotal: 20000, montantVerse: 40000 });
  assert.strictEqual(r.monnaieARendre, 10000);
  assert.strictEqual(r.soldeApres, 0);
  assert.strictEqual(r.mode, 'comptant');
});

test('dette existante soldée, excédent ajouté au solde', () => {
  const r = s({ soldeAvant: -10000, montantVenteTotal: 20000, montantVerse: 40000, resteVersSolde: true });
  assert.strictEqual(r.soldeApres, 10000);
  assert.strictEqual(r.ajouteAuSolde, 10000);
});

test('dette existante : paiement exact de la vente seulement (ancienne dette conservée)', () => {
  const r = s({ soldeAvant: -10000, montantVenteTotal: 20000, montantVerse: 20000 });
  assert.strictEqual(r.soldeApres, -10000);
  assert.strictEqual(r.mode, 'credit');
  assert.strictEqual(r.montantPayePourCetteVente, 20000);
});

test('achat à crédit pur', () => {
  const r = s({ soldeAvant: 0, montantVenteTotal: 20000, montantVerse: 0 });
  assert.strictEqual(r.soldeApres, -20000);
  assert.strictEqual(r.mode, 'credit');
  assert.strictEqual(r.avanceUtilisee, 0);
});

test('invariant : solde après = solde avant + espèces conservées − vente, sur une grille', () => {
  for (const solde of [-30000, -5000, 0, 7000, 50000]) {
    for (const vente of [1000, 20000, 60000]) {
      for (const verse of [0, 500, 10000, 20000, 80000, 200000]) {
        for (const reste of [false, true]) {
          const r = s({ soldeAvant: solde, montantVenteTotal: vente, montantVerse: verse, resteVersSolde: reste });
          const attendu = solde + r.especesConservees - vente;
          assert.ok(Math.abs(r.soldeApres - attendu) < 1e-9, JSON.stringify({ solde, vente, verse, reste }));
          assert.ok(r.monnaieARendre >= 0 && r.ajouteAuSolde >= 0 && r.avanceUtilisee >= 0);
          assert.ok(r.avanceUtilisee <= Math.max(0, solde) + 1e-9, 'l\'avance utilisée ne dépasse jamais l\'avance disponible');
        }
      }
    }
  }
});
