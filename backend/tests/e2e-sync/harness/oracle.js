/**
 * Oracle de convergence : compare l'état des données de plusieurs postes ET du cloud.
 *
 * Après un moment de calme (plus d'envoi en attente), tous les postes et le cloud doivent contenir les mêmes lignes
 * (mêmes identifiants) avec les mêmes valeurs sur les colonnes qui comptent. Toute différence est un défaut de
 * synchronisation (ligne perdue, ligne en double, valeur périmée, solde ou stock faux).
 *
 * Les colonnes de dates sont volontairement exclues : leur représentation diffère entre SQLite et PostgreSQL.
 */
const { requete } = require('./cloud-admin');

/** Colonnes comparées par table (celles qui n'existent pas d'un côté sont ignorées) */
const SPECS_PAR_DEFAUT = {
  user_roles: ['nom', 'is_admin'],
  boutiques: ['nom', 'est_principale', 'is_active'],
  categories: ['nom'],
  produits: ['reference', 'nom', 'prix_unitaire', 'prix_achat', 'est_actif', 'est_service', 'seuil_stock_minimum', 'categorie_id'],
  clients: ['nom', 'prenom', 'telephone'],
  fournisseurs: ['nom', 'telephone'],
  stock_boutiques: ['boutique_id', 'produit_id', 'quantite_disponible'],
  stock: ['produit_id', 'quantite_disponible'],
  mouvements_stock: ['produit_id', 'boutique_id', 'type_mouvement', 'changement_quantite', 'stock_initial', 'stock_final'],
  comptes_clients: ['client_id', 'solde_actuel'],
  transactions_comptes: ['compte_id', 'type_transaction', 'montant', 'solde_apres'],
  ventes: ['numero_vente', 'client_id', 'boutique_id', 'montant_total', 'montant_paye', 'montant_restant', 'statut'],
  details_ventes: ['vente_id', 'produit_id', 'quantite', 'prix_unitaire', 'prix_total'],
  cash_registers: ['nom', 'solde_actuel', 'boutique_id'],
  cash_sessions: ['caisse_id', 'solde_ouverture', 'solde_fermeture', 'is_active'],
  cash_movements: ['caisse_id', 'type', 'montant'],
  commandes_approvisionnement: ['numero_commande', 'fournisseur_id', 'statut', 'montant_total'],
  financial_movements: ['reference', 'montant', 'statut'],
  transferts_stock: ['reference', 'source_boutique_id', 'dest_boutique_id', 'produit_id', 'quantite'],
};

/** Valeur comparable : nombres arrondis, booléens ramenés à 0/1, vide ramené à null */
function normaliser(v) {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v === 'boolean') return v ? 1 : 0;
  if (typeof v === 'bigint') return Number(v);
  if (typeof v === 'number') return Math.round(v * 100) / 100;
  if (typeof v === 'string' && /^-?\d+(\.\d+)?$/.test(v.trim())) return Math.round(Number(v) * 100) / 100;
  return String(v);
}

function enMap(lignes, colonnes) {
  const m = new Map();
  for (const l of lignes) {
    const o = {};
    for (const c of colonnes) o[c] = normaliser(l[c]);
    m.set(Number(l.id), o);
  }
  return m;
}

/** État d'un poste (lecture directe de sa base SQLite) */
function etatPoste(station, specs = SPECS_PAR_DEFAUT, { tables = null } = {}) {
  const etat = {};
  for (const [table, colonnes] of Object.entries(specs)) {
    if (tables && !tables.includes(table)) continue;
    let presentes;
    try { presentes = station.lire(`PRAGMA table_info("${table}")`).map((c) => c.name); } catch (_) { continue; }
    if (presentes.length === 0) continue;
    const cols = colonnes.filter((c) => presentes.includes(c));
    etat[table] = { cols, lignes: enMap(station.lire(`SELECT id${cols.length ? ', ' + cols.map((c) => `"${c}"`).join(', ') : ''} FROM "${table}"`), cols) };
  }
  return etat;
}

/** État du cloud de test (requêtes directes) */
async function etatCloud(urlBase, specs = SPECS_PAR_DEFAUT, { tables = null } = {}) {
  const etat = {};
  for (const [table, colonnes] of Object.entries(specs)) {
    if (tables && !tables.includes(table)) continue;
    const presentes = (await requete(urlBase, "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1", [table])).map((r) => r.column_name);
    if (presentes.length === 0) continue;
    const cols = colonnes.filter((c) => presentes.includes(c));
    const lignes = await requete(urlBase, `SELECT id${cols.length ? ', ' + cols.map((c) => `"${c}"`).join(', ') : ''} FROM "${table}"`);
    etat[table] = { cols, lignes: enMap(lignes, cols) };
  }
  return etat;
}

/**
 * Différences entre deux états.
 * @returns {Array<{table:string,id:number,type:'absent'|'valeur',manquant?:string,colonne?:string,a?:any,b?:any}>}
 */
function comparer(etatA, etatB, nomA = 'A', nomB = 'B') {
  const diffs = [];
  for (const table of new Set([...Object.keys(etatA), ...Object.keys(etatB)])) {
    const a = etatA[table];
    const b = etatB[table];
    if (!a || !b) continue; // table absente d'un côté : rien à comparer
    const cols = a.cols.filter((c) => b.cols.includes(c));
    for (const id of new Set([...a.lignes.keys(), ...b.lignes.keys()])) {
      const la = a.lignes.get(id);
      const lb = b.lignes.get(id);
      if (!la) { diffs.push({ table, id, type: 'absent', manquant: nomA, present: nomB }); continue; }
      if (!lb) { diffs.push({ table, id, type: 'absent', manquant: nomB, present: nomA }); continue; }
      for (const c of cols) if (la[c] !== lb[c]) diffs.push({ table, id, type: 'valeur', colonne: c, [nomA]: la[c], [nomB]: lb[c] });
    }
  }
  return diffs;
}

/** Texte lisible des premières différences */
function decrire(diffs, max = 25) {
  if (!diffs.length) return 'aucune différence';
  const l = diffs.slice(0, max).map((d) => (d.type === 'absent'
    ? `  ${d.table}#${d.id} : absent de ${d.manquant} (présent dans ${d.present})`
    : `  ${d.table}#${d.id}.${d.colonne} : ${JSON.stringify(Object.fromEntries(Object.entries(d).filter(([k]) => !['table', 'id', 'type', 'colonne'].includes(k))))}`));
  return `${diffs.length} différence(s) :\n${l.join('\n')}${diffs.length > max ? `\n  … et ${diffs.length - max} autre(s)` : ''}`;
}

/**
 * Synchronise tous les postes jusqu'au calme puis compare chaque poste au cloud.
 * Rend { ok, differences, tours, dureeMs, rapports } ; ne lève jamais : à l'appelant d'asserter.
 *
 * @param {{stations:Array, cloudUrl:string, specs?:Object, tables?:string[]|null, delaiMs?:number}} p
 */
async function attendreConvergence({ stations, cloudUrl, specs = SPECS_PAR_DEFAUT, tables = null, delaiMs = 180000 }) {
  const debut = Date.now();
  let differences = [];
  let tours = 0;
  let rapports = [];
  while (Date.now() - debut < delaiMs) {
    tours++;
    rapports = await Promise.all(stations.map((s) => s.synchroniserJusquaCalme({ delaiMs: Math.max(20000, delaiMs - (Date.now() - debut)) })));
    const cloud = await etatCloud(cloudUrl, specs, { tables });
    differences = [];
    for (const s of stations) {
      for (const d of comparer(etatPoste(s, specs, { tables }), cloud, s.nom, 'cloud')) differences.push({ poste: s.nom, ...d });
    }
    if (differences.length === 0) return { ok: true, differences, tours, dureeMs: Date.now() - debut, rapports };
    await new Promise((r) => setTimeout(r, 2500));
  }
  return { ok: false, differences, tours, dureeMs: Date.now() - debut, rapports };
}

module.exports = { SPECS_PAR_DEFAUT, normaliser, etatPoste, etatCloud, comparer, decrire, attendreConvergence };
