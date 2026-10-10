/**
 * Centre de décisions : détection des cas ambigus de stock et options chiffrées.
 * Reprend les situations réelles d'un client (produits « service » avec stock, livraison saisie sur
 * deux postes, écart avec le dernier mouvement).
 * Exécution : node --test tests/decision-center.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { buildStockCases, resoudreCible } = require('../src/services/decision-center');

const prod = (id, nom, estService = false) => ({ id, nom, reference: `R${id}`, estService });
const stock = (produit, quantite, boutiqueId = 1) => ({ produitId: produit.id, boutiqueId, quantite, produit, boutiqueNom: 'SMART ENERGY SARL' });
let seq = 1;
const mvt = (produitId, type, qte, initial, final, date, extra = {}) => ({
  id: seq++, produitId, boutiqueId: 1, typeMouvement: type, changementQuantite: qte, stockInitial: initial, stockFinal: final, dateMouvement: new Date(date), referenceId: null, typeReference: null, ...extra,
});
const ligne = (venteId, produitId, quantite, date = '2026-09-28T06:20:00Z') => ({ venteId, numeroVente: `VTE-${venteId}`, dateVente: new Date(date), boutiqueId: 1, produitId, quantite });
const un = (cas, produitId) => cas.find((c) => c.produit.id === produitId);
const option = (c, id) => c.options.find((o) => o.id === id);

test('produit « service » avec stock et ventes sans mouvement (cas du lustre : 98 reçus, 8 vendus)', () => {
  const lustre = prod(104, 'LUSTRE MODÈLE D6328 P', true);
  const cas = buildStockCases({
    stocks: [stock(lustre, 98)],
    mouvements: [mvt(104, 'achat', 98, 0, 98, '2026-09-19T08:00:00Z')],
    lignesVente: [ligne(1, 104, 3), ligne(2, 104, 3), ligne(3, 104, 2)],
  });
  const c = un(cas, 104);
  assert.deepStrictEqual(c.raisons.map((r) => r.code), ['vente_sans_mouvement']);
  assert.match(c.raisons[0].titre, /8 unité\(s\) vendue\(s\) sans sortie de stock/);
  assert.strictEqual(option(c, 'apres_ventes').cible, 90);
  assert.strictEqual(option(c, 'apres_ventes').recommandee, true);
  assert.strictEqual(option(c, 'apres_ventes').consequence, 'Stock 98 → 90 (-8)');
  assert.strictEqual(option(c, 'apres_ventes').marquePhysique, true, 'déduire les ventes = produit physique');
  assert.strictEqual(option(c, 'service_zero').cible, 0);
  assert.strictEqual(option(c, 'service_zero').marquePhysique, false, 'vrai service : il reste un service');
  assert.deepStrictEqual(c.ventes.map((v) => v.quantite), [3, 3, 2]);
});

test('une vente qui a son mouvement de stock n\'est pas comptée', () => {
  const p = prod(1, 'Poteau 5 Mètres', true);
  const cas = buildStockCases({
    stocks: [stock(p, 9)],
    mouvements: [mvt(1, 'vente', -1, 10, 9, '2026-06-17T19:00:00Z', { referenceId: 5, typeReference: 'vente' })],
    lignesVente: [ligne(5, 1, 1)],
  });
  const c = un(cas, 1);
  assert.deepStrictEqual(c.raisons.map((r) => r.code), ['service_avec_stock'], 'seulement : service avec stock');
  assert.strictEqual(c.ventes.length, 0);
  assert.ok(option(c, 'garder') && option(c, 'service_zero'));
});

test('produit physique dont des ventes n\'ont pas de mouvement : pas d\'options « service »', () => {
  const p = prod(11, 'LAMPE');
  const cas = buildStockCases({
    stocks: [stock(p, 20)],
    mouvements: [mvt(11, 'achat', 22, 0, 22, '2026-06-01T10:00:00Z')],
    lignesVente: [ligne(7, 11, 2)],
  });
  const c = un(cas, 11);
  assert.match(c.raisons[0].titre, /2 unité\(s\) vendue\(s\) sans mouvement de stock/);
  assert.ok(!option(c, 'service_zero'));
  assert.strictEqual(option(c, 'apres_ventes').marquePhysique, false);
  assert.strictEqual(option(c, 'apres_ventes').cible, 18);
});

test('réception en double : même quantité, même stock de départ, chaîne rompue (2 postes)', () => {
  const p = prod(3, 'LAMPADAIRE SOLAIRE RSK 120');
  const cas = buildStockCases({
    stocks: [stock(p, 104)],
    mouvements: [
      mvt(3, 'achat', 52, 0, 52, '2026-10-02T14:02:00Z'),
      mvt(3, 'achat', 52, 0, 52, '2026-10-03T06:55:00Z'), // 2e poste : repart de 0 sans connaître la 1re
    ],
    lignesVente: [],
  });
  const c = un(cas, 3);
  // stock 104 alors que le dernier mouvement dit 52 : l'écart d'historique est une 2e raison réelle
  assert.deepStrictEqual(c.raisons.map((r) => r.code), ['reception_en_double', 'ecart_historique']);
  assert.strictEqual(c.doublons.length, 1);
  assert.strictEqual(option(c, 'sans_doublon').cible, 52);
  // « utiliser le dernier mouvement » mène à la même quantité : regroupé, et mentionné
  assert.ok(!option(c, 'dernier_mouvement'));
  assert.match(option(c, 'sans_doublon').description, /Équivaut aussi à : utiliser le dernier mouvement/);
  assert.strictEqual(option(c, 'garder').cible, 104, 'ce peut être deux vraies livraisons : on laisse le choix');
});

test('réception en double contredite par le stock (106 < 108) : l\'option n\'est pas proposée', () => {
  const p = prod(57, "BOULES D'EXTENSION");
  const cas = buildStockCases({
    stocks: [stock(p, 106)],
    mouvements: [mvt(57, 'achat', 108, 0, 108, '2026-06-11T10:41:00Z'), mvt(57, 'achat', 108, 0, 108, '2026-06-11T10:42:00Z')],
    lignesVente: [],
  });
  const c = un(cas, 57);
  assert.ok(c.raisons.some((r) => r.code === 'reception_en_double'));
  assert.ok(!option(c, 'sans_doublon'), 'retirer 108 d\'un stock de 106 n\'a pas de sens');
});

test('réapprovisionnement légitime (tout vendu puis recommandé) : pas pris pour un doublon', () => {
  const p = prod(40, 'RAIL');
  const cas = buildStockCases({
    stocks: [stock(p, 100)],
    mouvements: [
      mvt(40, 'achat', 100, 0, 100, '2026-06-01T10:00:00Z'),
      mvt(40, 'vente', -100, 100, 0, '2026-06-10T10:00:00Z', { referenceId: 1, typeReference: 'vente' }),
      mvt(40, 'achat', 100, 0, 100, '2026-07-01T10:00:00Z'), // la chaîne se tient : stock_initial = stock_final précédent
    ],
    lignesVente: [ligne(1, 40, 100)],
  });
  assert.strictEqual(un(cas, 40), undefined);
});

test('écart entre le stock affiché et le dernier mouvement', () => {
  const p = prod(14, 'LAMPE MURALE');
  const cas = buildStockCases({
    stocks: [stock(p, 0)],
    mouvements: [mvt(14, 'achat', 6, 0, 6, '2026-06-01T10:00:00Z')],
    lignesVente: [],
  });
  const c = un(cas, 14);
  assert.deepStrictEqual(c.raisons.map((r) => r.code), ['ecart_historique']);
  assert.strictEqual(c.priorite, 3);
  assert.strictEqual(option(c, 'dernier_mouvement').cible, 6);
  assert.strictEqual(option(c, 'dernier_mouvement').consequence, 'Stock 0 → 6 (+6)');
});

test('stock cohérent : aucun cas', () => {
  const p = prod(20, 'CÂBLE');
  const cas = buildStockCases({ stocks: [stock(p, 10)], mouvements: [mvt(20, 'achat', 10, 0, 10, '2026-06-01T10:00:00Z')], lignesVente: [] });
  assert.strictEqual(cas.length, 0);
});

test('cas déjà décidés : ventes, mouvements et écarts traités ne reviennent pas', () => {
  const lustre = prod(104, 'LUSTRE', true);
  const data = {
    stocks: [stock(lustre, 90)],
    mouvements: [mvt(104, 'achat', 98, 0, 98, '2026-09-19T08:00:00Z'), mvt(104, 'correction', -8, 98, 90, '2026-10-12T08:00:00Z')],
    lignesVente: [ligne(1, 104, 3), ligne(2, 104, 5)],
  };
  // sans journal : les ventes réapparaissent (et le produit est toujours marqué service)
  assert.strictEqual(un(buildStockCases(data), 104).ventes.length, 2);
  // avec le journal : ventes traitées
  data.traites = { ventes: new Set([1, 2]), mouvements: new Set(), ecarts: new Set() };
  const apres = un(buildStockCases(data), 104);
  assert.strictEqual(apres.ventes.length, 0);
  assert.ok(!apres.raisons.some((r) => r.code === 'vente_sans_mouvement'));
});

test('un écart laissé tel quel ne revient pas tant que la situation ne change pas', () => {
  const p = prod(14, 'LAMPE MURALE');
  const data = { stocks: [stock(p, 0)], mouvements: [mvt(14, 'achat', 6, 0, 6, '2026-06-01T10:00:00Z')], lignesVente: [] };
  const signature = un(buildStockCases(data), 14).ecartSignature;
  data.traites = { ventes: new Set(), mouvements: new Set(), ecarts: new Set([signature]) };
  assert.strictEqual(un(buildStockCases(data), 14), undefined);
  // le stock change : la signature n'est plus la même, le cas redevient visible
  data.stocks = [stock(p, 2)];
  assert.ok(un(buildStockCases(data), 14));
});

test('les cas sont triés : service/ventes d\'abord, puis doublons, puis écarts', () => {
  const a = prod(1, 'A'); const b = prod(2, 'B'); const c = prod(3, 'C', true);
  const cas = buildStockCases({
    stocks: [stock(a, 0), stock(b, 104), stock(c, 5)],
    mouvements: [
      mvt(1, 'achat', 6, 0, 6, '2026-06-01T10:00:00Z'),
      mvt(2, 'achat', 52, 0, 52, '2026-10-02T10:00:00Z'), mvt(2, 'achat', 52, 0, 52, '2026-10-03T10:00:00Z'),
    ],
    lignesVente: [],
  });
  assert.deepStrictEqual(cas.map((x) => x.produit.id), [3, 2, 1]);
});

test('quantité saisie : entier positif ou nul seulement', () => {
  const c = { options: [{ id: 'garder', cible: 5 }] };
  assert.strictEqual(resoudreCible(c, 'garder'), 5);
  assert.strictEqual(resoudreCible(c, 'manuel', 12), 12);
  assert.strictEqual(resoudreCible(c, 'manuel', 0), 0);
  assert.strictEqual(resoudreCible(c, 'manuel', -1), null);
  assert.strictEqual(resoudreCible(c, 'manuel', 2.5), null);
  assert.strictEqual(resoudreCible(c, 'manuel', 'abc'), null);
  assert.strictEqual(resoudreCible(c, 'inconnue'), null);
});
