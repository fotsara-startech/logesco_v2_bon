/**
 * Aides pour les scénarios « le même saisi sur plusieurs postes » (fichiers 10-*.test.js).
 * Nouveau fichier : ne modifie aucun élément existant du harnais.
 */
const assert = require('node:assert');
const { pause } = require('./station');
const { requete } = require('./cloud-admin');

/** Poste dont la synchronisation automatique est coupée (cycle toutes les 15 min) : on décide quand il synchronise */
const MANUEL = { SYNC_INTERVAL_MS: '900000' };

/** Définitions de postes en mode manuel : nouvelleCampagne({ postes: manuels('A', 'B') }) */
const manuels = (...noms) => noms.map((nom) => ({ nom, env: MANUEL }));

const ok = (r, attendu = [200, 201]) => {
  assert.ok(attendu.includes(r.statut), `HTTP ${r.statut} : ${JSON.stringify(r.corps).slice(0, 400)}`);
  return r.corps.data;
};

async function creerProduit(st, { reference, nom, prix = 1000, achat = 500, ...reste }) {
  return ok(await st.api('POST', '/products', { reference, nom, prixUnitaire: prix, prixAchat: achat, seuilStockMinimum: 1, ...reste }));
}

async function ajusterStock(st, produitId, delta) {
  return ok(await st.api('POST', '/inventory/adjust', { produitId, changementQuantite: delta, notes: 'e2e' }));
}

/** Vente comptant (ou à crédit) de `quantite` unités ; renvoie la réponse brute */
function vendre(st, { produitId, quantite, prix = 1000, clientId = null, credit = false }) {
  return st.api('POST', '/sales', {
    clientId,
    modePaiement: credit ? 'credit' : 'comptant',
    montantPaye: credit ? 0 : prix * quantite,
    details: [{ produitId, quantite, prixUnitaire: prix, prixAffiche: prix }],
  });
}

/** Synchronise « un moment » sans exiger le calme (des envois refusés sont attendus) */
async function syncBref(st, delaiMs = 25000) {
  return st.synchroniserJusquaCalme({ delaiMs, pauseMs: 1000 });
}

/** Cas à décider vus par un poste (GET /decisions) */
async function decisions(st) {
  const r = await st.api('GET', '/decisions');
  assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 300));
  return r.corps.data;
}

/**
 * Cherche des conflits sur les postes donnés, jusqu'à en voir (le refus du cloud n'apparaît qu'après un cycle).
 * @returns {Promise<Array<{poste, conflit}>>}
 */
async function attendreConflits(stations, { delaiMs = 60000, table = null, minimum = 1 } = {}) {
  const debut = Date.now();
  let trouves = [];
  while (Date.now() - debut < delaiMs) {
    trouves = [];
    for (const st of stations) {
      try { await st.synchroniser(); } catch (_) { /* poste occupé */ }
      const d = await decisions(st);
      for (const conflit of d.conflits || []) if (!table || conflit.table === table) trouves.push({ poste: st, conflit });
    }
    if (trouves.length >= minimum) return trouves;
    await pause(2000);
  }
  return trouves;
}

/**
 * Applique la décision demandée sur un conflit ; `choix(conflit)` rend { optionId, valeur? } ou null pour passer.
 * @returns {Promise<Array<{table, key, optionId, statut}>>}
 */
async function trancher(st, conflits, choix) {
  const faits = [];
  for (const conflit of conflits) {
    const c = choix(conflit);
    if (!c) continue;
    const r = await st.api('POST', '/decisions/apply', { caseKey: conflit.key, optionId: c.optionId, valeur: c.valeur }, { delaiMs: 90000 });
    faits.push({ table: conflit.table, key: conflit.key, optionId: c.optionId, statut: r.statut, corps: r.corps });
  }
  return faits;
}

/**
 * Boucle « synchroniser → lister les conflits → trancher » jusqu'à ce qu'il n'y en ait plus.
 * `choix(conflit, poste)` : voir trancher(). Rend le journal des décisions prises (étapes comptées).
 */
async function resoudreTout(stations, choix, { tourMax = 6, delaiMs = 45000 } = {}) {
  const journal = [];
  for (let tour = 1; tour <= tourMax; tour++) {
    const vus = await attendreConflits(stations, { delaiMs: tour === 1 ? delaiMs : 15000 });
    if (vus.length === 0) return { journal, tours: tour - 1 };
    for (const st of stations) {
      const siens = vus.filter((v) => v.poste === st).map((v) => v.conflit);
      const faits = await trancher(st, siens, (c) => choix(c, st));
      for (const f of faits) journal.push({ tour, poste: st.nom, ...f });
    }
  }
  return { journal, tours: tourMax, incomplet: true };
}

/** attendreConvergence qui réessaie quand la liaison réseau vers le cloud de test casse (ETIMEDOUT, ECONNRESET...) */
async function convergenceRobuste(args, essais = 5) {
  const { attendreConvergence } = require('./oracle');
  let derniere;
  for (let i = 0; i < essais; i++) {
    try { return await attendreConvergence(args); } catch (e) {
      derniere = e;
      if (!/ETIMEDOUT|ECONNRESET|ENOTFOUND|EAI_AGAIN|timeout|terminated/i.test(`${e.code} ${e.message}`)) throw e;
      await pause(10000);
    }
  }
  throw derniere;
}

const cloudSql = (c, sql, params) => requete(c.cloudUrl, sql, params);
const num = (v) => Number(v);

module.exports = { convergenceRobuste, MANUEL, manuels, ok, creerProduit, ajusterStock, vendre, syncBref, decisions, attendreConflits, trancher, resoudreTout, cloudSql, num };
