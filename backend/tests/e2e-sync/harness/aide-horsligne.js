/**
 * Aides pour les scénarios « hors ligne / crash / reprise » (étiquette de base cloud : « horsligne »).
 * Ne modifie aucun fichier existant du harnais.
 */
const assert = require('node:assert');
const path = require('node:path');
const admin = require('./cloud-admin');
const requete = (...a) => admin.requete(...a);
const { pause } = require('./station');
const oracle = require('./oracle');

/** Module à passer dans `preload` d'un poste sans cloud (voir aide-sans-cloud.js) */
const PRELOAD_SANS_CLOUD = path.join(__dirname, 'aide-sans-cloud.js');

/** Adresse de cloud qui refuse la connexion tout de suite (port 9, hôte local) : poste « hors ligne » */
const URL_INJOIGNABLE = 'postgresql://hors:ligne@127.0.0.1:9/neondb?sslmode=disable';

/** Exécute `fn(i)` pour i de 0 à n-1 avec au plus `lot` appels simultanés ; lève au premier échec */
async function enParallele(n, lot, fn) {
  const resultats = new Array(n);
  let suivant = 0;
  async function travailleur() {
    while (true) {
      const i = suivant++;
      if (i >= n) return;
      resultats[i] = await fn(i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(lot, n) }, travailleur));
  return resultats;
}

function exiger(r, attendus = [200, 201], contexte = '') {
  if (!attendus.includes(r.statut)) throw new Error(`${contexte} → HTTP ${r.statut} : ${JSON.stringify(r.corps).slice(0, 400)}`);
  return r.corps.data;
}

/** Erreurs d'API rencontrées pendant les créations (HTTP 4xx/5xx, délais) : constat à rapporter, pas une erreur du test */
const erreursApi = [];

async function avecReprises(station, methode, chemin, corps, { essais = 3, acceptes = [200, 201], contexte = '' } = {}) {
  let dernier;
  for (let k = 1; k <= essais; k++) {
    try {
      const r = await station.api(methode, chemin, corps, { delaiMs: 90000 });
      if (acceptes.includes(r.statut) || r.statut === 409) return r;
      dernier = `HTTP ${r.statut} ${JSON.stringify(r.corps).slice(0, 160)}`;
    } catch (e) { dernier = e.message; }
    erreursApi.push(`${station.nom} ${contexte} (essai ${k}) : ${dernier}`);
    await pause(2000);
  }
  return null;
}

/** Crée n produits (avec un stock initial) sur un poste. Rend les identifiants des produits qui existent (lus en base). */
async function creerProduits(station, n, prefixe, { stock = 200, prix = 1500, lot = 1 } = {}) {
  await enParallele(n, lot, async (i) => {
    const ref = `${prefixe}-${String(i + 1).padStart(4, '0')}`;
    const r = await avecReprises(station, 'POST', '/products', { reference: ref, nom: `Produit ${ref}`, prixUnitaire: prix, prixAchat: 1000, seuilStockMinimum: 1 }, { acceptes: [201], contexte: `création ${ref}` });
    if (!r || stock <= 0) return;
    const id = station.lire('SELECT id FROM produits WHERE reference = ?', ref)[0];
    if (id) await avecReprises(station, 'POST', '/inventory/adjust', { produitId: Number(id.id), changementQuantite: stock, notes: 'stock initial' }, { contexte: `stock ${ref}` });
  });
  return station.lire('SELECT id FROM produits WHERE reference LIKE ? ORDER BY id', `${prefixe}-%`).map((l) => Number(l.id));
}

/** Crée n ventes d'une unité (sans reprise : une reprise pourrait doubler la vente). Rend les identifiants de ventes créées. */
async function creerVentes(station, produitIds, n, { lot = 1 } = {}) {
  const avant = new Set(station.lire('SELECT id FROM ventes').map((l) => Number(l.id)));
  await enParallele(n, lot, async (i) => {
    const pid = produitIds[i % produitIds.length];
    const prix = 1500;
    await avecReprises(station, 'POST', '/sales', { modePaiement: 'comptant', montantPaye: prix, details: [{ produitId: pid, quantite: 1, prixUnitaire: prix, prixAffiche: prix }] }, { essais: 1, contexte: `vente ${i}` });
  });
  return station.lire('SELECT id FROM ventes ORDER BY id').map((l) => Number(l.id)).filter((id) => !avant.has(id));
}

/** Ajustements de stock (mouvements) sur des produits existants */
async function ajusterStocks(station, produitIds, delta = 3, { lot = 1 } = {}) {
  await enParallele(produitIds.length, lot, async (i) => { await avecReprises(station, 'POST', '/inventory/adjust', { produitId: produitIds[i], changementQuantite: delta, notes: 'ajustement' }, { contexte: 'ajustement' }); });
}

async function nombreCloud(url, table, ou = '') {
  return Number((await requete(url, `SELECT COUNT(*) n FROM "${table}" ${ou}`))[0].n);
}

/** Lignes du cloud qui désignent le même objet métier sous deux identifiants (doublons réels) */
async function doublonsCloud(url) {
  const r = [];
  for (const [table, col] of [['produits', 'reference'], ['ventes', 'numero_vente'], ['clients', 'telephone']]) {
    const d = await requete(url, `SELECT "${col}" v, COUNT(*) n FROM "${table}" WHERE "${col}" IS NOT NULL AND "${col}" <> '' GROUP BY "${col}" HAVING COUNT(*) > 1`);
    for (const x of d) r.push(`${table}.${col}=${x.v} ×${x.n}`);
  }
  // un même stock (produit, boutique) en double
  const s = await requete(url, 'SELECT produit_id, boutique_id, COUNT(*) n FROM stock_boutiques GROUP BY 1,2 HAVING COUNT(*) > 1');
  for (const x of s) r.push(`stock_boutiques(produit=${x.produit_id},boutique=${x.boutique_id}) ×${x.n}`);
  const s2 = await requete(url, 'SELECT produit_id, COUNT(*) n FROM stock GROUP BY 1 HAVING COUNT(*) > 1');
  for (const x of s2) r.push(`stock(produit=${x.produit_id}) ×${x.n}`);
  return r;
}

/** Identifiants d'une table SQLite locale */
function idsLocaux(station, table, ou = '') {
  return station.lire(`SELECT id FROM "${table}" ${ou}`).map((l) => Number(l.id));
}

async function idsCloudDe(url, table, ou = '') {
  return (await requete(url, `SELECT id FROM "${table}" ${ou}`)).map((l) => Number(l.id));
}

/** Attend qu'une condition asynchrone devienne vraie (sans lever) */
async function attendre(condition, { delaiMs = 120000, pauseMs = 3000 } = {}) {
  const debut = Date.now();
  let derniere;
  while (Date.now() - debut < delaiMs) {
    try { derniere = await condition(); if (derniere) return { ok: true, valeur: derniere, dureeMs: Date.now() - debut }; } catch (e) { derniere = e.message; }
    await pause(pauseMs);
  }
  return { ok: false, valeur: derniere, dureeMs: Date.now() - debut };
}


const { DatabaseSync } = require('node:sqlite');

/** Écriture directe dans la base SQLite d'un poste EN MARCHE (test seulement : simule un état particulier) */
function ecrireLocal(station, sql, ...params) {
  const db = new DatabaseSync(station.fichierDb);
  try {
    db.exec('PRAGMA busy_timeout = 15000');
    return db.prepare(sql).run(...params);
  } finally { db.close(); }
}

/** Identifiant de la boutique principale du cloud de test */
async function boutiqueCloud(url) {
  return Number((await requete(url, 'SELECT id FROM boutiques ORDER BY id LIMIT 1'))[0].id);
}

/**
 * Insère directement dans le cloud un produit, avec la date de modification voulue (expression SQL, ex.
 * "NOW() - INTERVAL '30 days'"). Les déclencheurs de date du cloud ne s'appliquent qu'aux UPDATE : une insertion garde
 * la date fournie. avecStock : ajoute aussi les lignes stock et stock_boutiques (même id), de date `stockDateMod`.
 */
async function insererProduitCloud(url, { id, reference, nom = null, dateMod = 'NOW()', avecStock = false, quantite = 5, stockDateMod = 'NULL' }) {
  await requete(url, `INSERT INTO produits (id, reference, nom, prix_unitaire, date_creation, date_modification) VALUES ($1, $2, $3, 1200, NOW(), ${dateMod})`, [id, reference, nom || reference]);
  if (avecStock) {
    const b = await boutiqueCloud(url);
    await requete(url, `INSERT INTO stock (id, produit_id, quantite_disponible, quantite_reservee, derniere_maj, date_modification) VALUES ($1, $1, $2, 0, NOW(), ${stockDateMod})`, [id, quantite]);
    await requete(url, `INSERT INTO stock_boutiques (id, boutique_id, produit_id, quantite_disponible, quantite_reservee, derniere_maj, date_modification) VALUES ($1, $2, $1, $3, 0, NOW(), ${stockDateMod})`, [id, b, quantite]);
  }
}

async function ligneCloud(url, table, id) {
  return (await requete(url, `SELECT * FROM "${table}" WHERE id = $1`, [id]))[0] || null;
}

/**
 * Convergence qui isole le DÉFAUT « écriture locale jamais envoyée » (journal perdu : « database is locked » avalé par
 * logOperation, ou opération restée en échec) du reste des différences.
 *   - perdus : lignes présentes sur un poste, absentes du cloud, sans AUCUNE opération « synced » dans son journal ;
 *   - autres : toute autre différence (valeur, ligne absente d'un poste, ligne du cloud non reçue...) → strictement exigées nulles.
 * Rend { ok (autres vide), perdus, autres, dureeMs }.
 */
async function convergenceTolerante({ stations, cloudUrl, delaiMs = 400000, tables = null, specs = oracle.SPECS_PAR_DEFAUT }) {
  const debut = Date.now();
  let perdus = [];
  let autres = [];
  while (Date.now() - debut < delaiMs) {
    await Promise.all(stations.map((s) => s.synchroniserJusquaCalme({ delaiMs: Math.max(20000, delaiMs - (Date.now() - debut)) })));
    const cloud = await oracle.etatCloud(cloudUrl, specs, { tables });
    perdus = []; autres = [];
    for (const s of stations) {
      for (const d of oracle.comparer(oracle.etatPoste(s, specs, { tables }), cloud, s.nom, 'cloud')) {
        const dd = { poste: s.nom, ...d };
        if (d.type === 'absent' && d.manquant === 'cloud') {
          const n = Number(s.lire("SELECT COUNT(*) n FROM operation_log WHERE table_name = ? AND record_id = ? AND status = 'synced'", d.table, d.id)[0].n);
          if (n === 0) { perdus.push(dd); continue; }
        }
        autres.push(dd);
      }
    }
    if (autres.length === 0) return { ok: true, perdus, autres, dureeMs: Date.now() - debut };
    await pause(2500);
  }
  return { ok: false, perdus, autres, dureeMs: Date.now() - debut };
}


/** Sous-test « à corriger » : aucune écriture locale ne doit rester sans envoi (voir convergenceTolerante) */
async function signalerPerdus(t, r) {
  if (!r.perdus || r.perdus.length === 0) return;
  const parTable = {};
  for (const p of r.perdus) parTable[`${p.poste}:${p.table}`] = (parTable[`${p.poste}:${p.table}`] || 0) + 1;
  console.log(`   ÉCRITURES LOCALES JAMAIS ENVOYÉES : ${r.perdus.length} (${JSON.stringify(parTable)})`);
  await t.test('aucune écriture locale perdue avant envoi (journal complet)', {
    todo: 'DÉFAUT CONNU : logOperation() avale les erreurs « database is locked » (sync-service.js, catch de logOperation) ; la route des ventes journalise après la réponse (sales.js:1263 setImmediate) en concurrence avec ses propres écritures : une ligne existe en local, sans opération dans le journal, et n\'est jamais envoyée (le contrôle d\'écart la signale mais ne la renvoie pas hors tables de stock)',
  }, () => { assert.strictEqual(r.perdus.length, 0, `${r.perdus.length} ligne(s) jamais envoyée(s) : ${r.perdus.slice(0, 8).map((p) => `${p.poste}/${p.table}#${p.id}`).join(', ')}`); });
}


/**
 * État du STOCK d'un poste, pour comprendre un écart : quantité, base de référence (sync_stock_base), opérations de
 * stock par statut et dernières lignes de journal utiles.
 */
function decrireStock(st) {
  const SEP = String.fromCharCode(10);
  const j = (sql) => { try { return JSON.stringify(st.lire(sql)); } catch (e) { return 'ERR ' + e.message; } };
  const lignes = st.journal(12000).split(SEP).filter((x) => /stock|laissée|protég|Rattrapage|pull|Pull/i.test(x) && !/AUDIT|Request completed|AUTH|mouvements_stock/.test(x));
  return [
    `   [${st.nom}] stock=${j('SELECT id, quantite_disponible q FROM stock')} base=${j("SELECT record_id id, quantite q FROM sync_stock_base WHERE table_name = 'stock'")}`,
    `   [${st.nom}] ops stock=${j("SELECT operation_type o, status s, substr(error_message,1,80) e FROM operation_log WHERE table_name = 'stock' ORDER BY id")}`,
    `   [${st.nom}] journal :` + SEP + lignes.slice(-12).map((x) => '      ' + x.slice(0, 160)).join(SEP),
  ].join(SEP);
}

/** Écarts non expliqués du contrôle d'écart d'un poste (rafraîchi) */
async function ecartsInexpliques(station) {
  const r = await station.api('GET', '/sync/drift?refresh=1', undefined, { delaiMs: 120000 });
  const rap = r.corps && r.corps.data && r.corps.data.rapport;
  return { statut: r.statut, rapport: rap, inexpliques: rap ? rap.resume.inexpliques : null, ecarts: rap ? rap.ecarts.filter((e) => !e.connue) : [] };
}

function resumeEcarts(ecarts) {
  return ecarts.map((e) => `${e.table}/${e.sens}/${e.cause}×${e.nombre}`).join(', ') || 'aucun';
}

module.exports = { decrireStock, signalerPerdus, convergenceTolerante, erreursApi, avecReprises, ecrireLocal, boutiqueCloud, insererProduitCloud, ligneCloud, PRELOAD_SANS_CLOUD, URL_INJOIGNABLE, enParallele, exiger, creerProduits, creerVentes, ajusterStocks, nombreCloud, doublonsCloud, idsLocaux, idsCloudDe, attendre, ecartsInexpliques, resumeEcarts };
