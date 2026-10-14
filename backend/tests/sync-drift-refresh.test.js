/**
 * Contrôle d'écart : une demande de rafraîchissement ne renvoie pas le résultat d'un contrôle commencé AVANT.
 *
 * Défaut corrigé : GET /sync/drift?refresh=1 renvoyait l'ancien rapport quand un contrôle était déjà en cours, donc un
 * rapport qui ne tenait pas compte de ce que l'utilisateur venait de corriger.
 *
 * Exécution :  node --test tests/sync-drift-refresh.test.js
 */
const test = require('node:test');
const assert = require('node:assert');

process.env.CLOUD_DB_URL = 'postgresql://fake';
const service = require('../src/services/sync-service');

const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

/** Prépare le service avec un faux cloud et un calcul d'écart contrôlé : chaque appel prend `duree` ms et renvoie le rapport n° N */
function preparer({ duree = 150 } = {}) {
  const appels = [];
  service.cloudUrl = 'postgresql://fake';
  service.localPrisma = {};
  service.isCloudAvailable = true;
  service.cloudPool = { connect: async () => ({ release() {} }) };
  service.driftReport = { numero: 0, resume: { inexpliques: 0, anciens: 0 }, seuilAncienHeures: 24 };
  service._driftEnCours = false;
  service._recupererManquants = async () => 0;
  service._calculerEcart = async () => {
    const numero = appels.length + 1;
    appels.push(numero);
    await attendre(duree);
    return { numero, resume: { inexpliques: 0, anciens: 0 }, seuilAncienHeures: 24 };
  };
  return appels;
}

const silencieux = async (fn) => {
  const log = console.log, warn = console.warn;
  console.log = console.warn = () => {};
  try { return await fn(); } finally { console.log = log; console.warn = warn; }
};

test('appel périodique pendant un contrôle en cours : on garde le dernier rapport, sans attendre ni s\'empiler', async () => {
  const appels = preparer({ duree: 150 });
  await silencieux(async () => {
    const enCours = service.checkDrift();
    await attendre(20); // le contrôle est en cours
    const t0 = Date.now();
    const periodique = await service.checkDrift();
    assert.ok(Date.now() - t0 < 100, 'retour immédiat');
    assert.strictEqual(periodique.numero, 0, 'dernier rapport connu (celui d\'avant)');
    await enCours;
  });
  assert.deepStrictEqual(appels, [1], 'un seul contrôle lancé');
});

test('rafraîchissement explicite pendant un contrôle en cours : on attend sa fin, puis un NOUVEAU contrôle est fait', async () => {
  const appels = preparer({ duree: 150 });
  const rapport = await silencieux(async () => {
    const enCours = service.checkDrift(); // commencé avant la demande de l'utilisateur
    await attendre(20);
    const frais = await service.checkDrift({ attendre: true });
    await enCours;
    return frais;
  });
  assert.deepStrictEqual(appels, [1, 2], 'le contrôle en cours puis un nouveau');
  assert.strictEqual(rapport.numero, 2, 'le rapport rendu est celui du NOUVEAU contrôle, pas du contrôle commencé avant');
});

test('rafraîchissement explicite sans contrôle en cours : un contrôle est fait tout de suite', async () => {
  const appels = preparer({ duree: 10 });
  const rapport = await silencieux(() => service.checkDrift({ attendre: true }));
  assert.deepStrictEqual(appels, [1]);
  assert.strictEqual(rapport.numero, 1);
});

test('cloud injoignable : le dernier rapport est rendu, sans attente', async () => {
  const appels = preparer();
  service.isCloudAvailable = false;
  const rapport = await silencieux(() => service.checkDrift({ attendre: true }));
  assert.strictEqual(rapport.numero, 0);
  assert.deepStrictEqual(appels, []);
});
