/**
 * Aides pour les scénarios « métier » (ventes, comptes, caisse, approvisionnement, contrôle d'écart).
 * Ne modifie aucun fichier existant du harnais : elles s'appuient sur Station, cloud-admin et l'oracle.
 */
const { requete } = require('./cloud-admin');
const { etatPoste, etatCloud, comparer, decrire, normaliser } = require('./oracle');

const num = (v) => (v === null || v === undefined ? null : Number(v));
const arrondi = (v) => Math.round(Number(v) * 100) / 100;

/** Appel d'API qui exige un succès (200/201) et rend le champ data */
async function exiger(poste, methode, chemin, corps, attendus = [200, 201]) {
  const r = await poste.api(methode, chemin, corps);
  if (!attendus.includes(r.statut)) {
    throw new Error(`${poste.nom} ${methode} ${chemin} → ${r.statut} ${JSON.stringify(r.corps).slice(0, 400)}`);
  }
  return r.corps.data !== undefined ? r.corps.data : r.corps;
}

async function creerProduit(poste, { reference, nom, prix = 1500, achat = 1000, service = false }) {
  const d = await exiger(poste, 'POST', '/products', { reference, nom, prixUnitaire: prix, prixAchat: achat, seuilStockMinimum: 1, estService: service });
  return d.id;
}

/** Fixe un stock de départ par un mouvement tracé (boutique précise) */
async function approvisionner(poste, produitId, boutiqueId, quantite, typeMouvement = 'ajustement') {
  return exiger(poste, 'POST', '/inventory/movements', { produitId, boutiqueId, typeMouvement, changementQuantite: quantite, notes: 'départ test' });
}

/** Vente : lignes [{produitId, quantite, prix}] ; rend la vente créée */
async function vendre(poste, { boutiqueId, clientId = null, lignes, montantPaye, resteVersSolde = false }) {
  const total = lignes.reduce((t, l) => t + l.quantite * l.prix, 0);
  const corps = {
    clientId, boutiqueId, modePaiement: 'comptant', resteVersSolde,
    montantPaye: montantPaye === undefined ? total : montantPaye,
    details: lignes.map((l) => ({ produitId: l.produitId, quantite: l.quantite, prixUnitaire: l.prix, prixAffiche: l.prix, remiseAppliquee: 0 })),
  };
  const r = await poste.api('POST', '/sales', corps);
  if (![200, 201].includes(r.statut)) throw new Error(`${poste.nom} vente refusée ${r.statut} ${JSON.stringify(r.corps).slice(0, 400)}`);
  return { ...(r.corps.data || {}), total };
}

/** Rejoue une opération réseau vers le cloud quand la liaison du PC de test coupe (erreurs de connexion seulement) */
async function avecReprise(fn, essais = 5) {
  let derniere;
  for (let i = 0; i < essais; i++) {
    try { return await fn(); } catch (e) {
      derniere = e;
      const m = `${e && e.message} ${e && e.code} ${(e && e.errors || []).map((x) => x.code).join(',')}`;
      if (!/ETIMEDOUT|ECONN|terminated|TLS|socket|timeout|ENOTFOUND|EAI_AGAIN|EPIPE|unable to open|locked|fetch failed/i.test(m)) throw e;
      await new Promise((r) => setTimeout(r, 4000 * (i + 1)));
    }
  }
  throw derniere;
}

const lireCloud = (c, sql, params = []) => avecReprise(() => requete(c.cloudUrl, sql, params));

/** Valeur d'une ligne de stock boutique sur un poste (ou null) */
function stockPoste(poste, produitId, boutiqueId) {
  const r = poste.lire('SELECT quantite_disponible q FROM stock_boutiques WHERE produit_id = ? AND boutique_id = ?', produitId, boutiqueId);
  return r.length ? Number(r[0].q) : null;
}
async function stockCloud(c, produitId, boutiqueId) {
  const r = await lireCloud(c, 'SELECT quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [produitId, boutiqueId]);
  return r.length ? Number(r[0].q) : null;
}

/** Même requête sur tous les postes ET le cloud ; rend { A:[...], B:[...], cloud:[...] } (lignes normalisées) */
async function partout(c, postes, sql, params = []) {
  const sortie = {};
  for (const p of postes) sortie[p.nom] = p.lire(sql.replace(/\$\d+/g, '?'), ...params);
  sortie.cloud = await lireCloud(c, sql, params);
  const norm = (rows) => rows.map((r) => Object.fromEntries(Object.entries(r).map(([k, v]) => [k, normaliser(v)])));
  for (const k of Object.keys(sortie)) sortie[k] = norm(sortie[k]);
  return sortie;
}

/** Vérifie que le résultat d'une requête est identique sur tous les postes et le cloud ; rend la valeur commune */
function identiques(assert, resultats, quoi) {
  const ref = JSON.stringify(resultats.cloud);
  for (const [nom, rows] of Object.entries(resultats)) {
    assert.strictEqual(JSON.stringify(rows), ref, `${quoi} : ${nom} diffère du cloud → ${nom}=${JSON.stringify(rows)} cloud=${ref}`);
  }
  return resultats.cloud;
}

/**
 * Compte client/fournisseur : solde, dernière écriture (par date puis id) et somme signée des écritures.
 * Signe : achat* = -1 pour un client (dette) ; paiement/depot = +1.
 */
function controleCompte(poste, table, typeCompte, compteId) {
  const compte = poste.lire(`SELECT solde_actuel s FROM ${table} WHERE id = ?`, compteId)[0];
  const tx = poste.lire('SELECT id, type_transaction t, type_transaction_detail d, montant m, solde_apres sa FROM transactions_comptes WHERE type_compte = ? AND compte_id = ? ORDER BY date_transaction, id', typeCompte, compteId);
  return { solde: compte ? Number(compte.s) : null, dernier: tx.length ? Number(tx[tx.length - 1].sa) : null, nb: tx.length, tx };
}

/** Comptage de toutes les lignes de toutes les tables « métier » d'un poste (hors suivi interne de synchro) */
function comptagesPoste(poste) {
  const tables = poste.lire("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '\\_%' ESCAPE '\\'").map((t) => t.name);
  const sortie = {};
  for (const t of tables) {
    if (/^(sync_|_prisma|decision_log)/.test(t) || t === 'deleted_records') continue;
    sortie[t] = Number(poste.lire(`SELECT COUNT(*) n FROM "${t}"`)[0].n);
  }
  return sortie;
}

async function comptagesCloud(c, tables) {
  const sortie = {};
  for (const t of tables) {
    try { sortie[t] = Number((await lireCloud(c, `SELECT COUNT(*) n FROM "${t}"`))[0].n); } catch (_) { /* table absente du cloud */ }
  }
  return sortie;
}

function differencesObjets(avant, apres) {
  const d = [];
  for (const k of new Set([...Object.keys(avant), ...Object.keys(apres)])) if (avant[k] !== apres[k]) d.push(`${k}: ${avant[k]} → ${apres[k]}`);
  return d;
}

module.exports = { avecReprise, exiger, creerProduit, approvisionner, vendre, lireCloud, stockPoste, stockCloud, partout, identiques, controleCompte, comptagesPoste, comptagesCloud, differencesObjets, arrondi, num, etatPoste, etatCloud, comparer, decrire };
