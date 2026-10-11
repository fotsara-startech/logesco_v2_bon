/**
 * Assistant de campagne : crée une base cloud jetable + N postes simulés, et nettoie tout à la fin.
 *
 *   const c = await nouvelleCampagne({ etiquette: 'multi', postes: ['A', 'B'] });
 *   const { A, B } = c.postes;
 *   ... scénario ...
 *   await c.terminer();           // arrête les postes, supprime la base cloud de test
 *
 * Chaque appel crée SA PROPRE base cloud : deux scénarios ne se polluent jamais.
 */
const fs = require('node:fs');
const { DatabaseSync } = require('node:sqlite');
const { Station, pause } = require('./station');
const admin = require('./cloud-admin');

/** Données de base créées au premier démarrage d'un poste (graine) */
const TABLES_GRAINE = ['user_roles', 'utilisateurs', 'boutiques', 'cash_registers', 'parametres_entreprise', 'user_boutique_assignments'];

/**
 * Copie des lignes d'une table SQLite d'un poste vers le cloud de test, identifiants conservés.
 * Reproduit l'état d'un client établi : le cloud possède déjà les données de base de son premier poste.
 */
async function copierVersCloud(station, urlCloud, tables = TABLES_GRAINE) {
  for (const table of tables) {
    let lignes;
    try { lignes = station.lire(`SELECT * FROM "${table}"`); } catch (_) { continue; }
    if (!lignes.length) continue;
    const types = await admin.requete(urlCloud, "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1", [table]);
    const typeDe = new Map(types.map((t) => [t.column_name, t.data_type]));
    for (const l of lignes) {
      const cols = Object.keys(l).filter((c) => typeDe.has(c));
      const vals = cols.map((c) => {
        const v = l[c];
        if (v === null || v === undefined) return null;
        const t = typeDe.get(c);
        if (t === 'boolean') return Boolean(Number(v));
        if (t.startsWith('timestamp')) {
          const d = typeof v === 'number' || typeof v === 'bigint' ? new Date(Number(v)) : new Date(String(v).includes('T') ? v : `${String(v).replace(' ', 'T')}Z`);
          return Number.isNaN(d.getTime()) ? null : d;
        }
        if (typeof v === 'bigint') return Number(v);
        return v;
      });
      await admin.requete(
        urlCloud,
        `INSERT INTO "${table}" (${cols.map((c) => `"${c}"`).join(', ')}) VALUES (${cols.map((_, i) => `$${i + 1}`).join(', ')}) ON CONFLICT DO NOTHING`,
        vals
      );
    }
  }
}

/** Prépare la base d'un poste copié : il garde les données mais devra réserver SA propre identité et tout recevoir du cloud */
function preparerCopie(fichierSource, fichierCible) {
  fs.mkdirSync(require('node:path').dirname(fichierCible), { recursive: true });
  fs.copyFileSync(fichierSource, fichierCible);
  const db = new DatabaseSync(fichierCible);
  try {
    for (const t of ['sync_identity', 'sync_pull_state', 'sync_pull_retry', 'operation_log', 'sync_drift_state', 'sync_drift_ignored']) {
      try { db.exec(`DELETE FROM "${t}"`); } catch (_) { /* table absente */ }
    }
  } finally { db.close(); }
}

/** Cycles de synchronisation rapides pour les tests (valeurs d'exploitation : 30 s, 2 min, 3 h) */
const ENV_RAPIDE = {
  SYNC_INTERVAL_MS: '3000',
  SYNC_DRIFT_FIRST_DELAY_MS: '20000',
  SYNC_DRIFT_INTERVAL_MS: '60000',
};

/** Les tests de bout en bout exigent l'URL de la base Neon de développement ET le module node:sqlite */
function peutLancer() {
  if (!process.env.SYNC_TEST_NEON_URL) return { ok: false, raison: 'SYNC_TEST_NEON_URL absent (URL de la base Neon de développement)' };
  try { require('node:sqlite'); } catch (_) { return { ok: false, raison: 'node:sqlite indisponible (lancer avec --experimental-sqlite)' }; }
  return { ok: true };
}

/**
 * @param {{etiquette:string, postes:Array<string|{nom:string, env?:Object, preload?:string[], cloud?:boolean|string}>,
 *          pooler?:boolean, demarrer?:boolean}} options
 *   pooler   : les postes se connectent par l'adresse « pooler » de Neon (comme en exploitation). Défaut : true.
 *   demarrer : démarrer les postes tout de suite. Défaut : true.
 *   cloud (par poste) : false = poste 100 % local ; une chaîne = URL cloud alternative (ex. passage par un proxy de pannes).
 *   baseline : état de départ.
 *     'clone' (défaut)  : le premier poste démarre et crée ses données de base ; elles sont copiées dans le cloud ; les
 *                         autres postes partent d'une copie de sa base (comme des postes restaurés d'une sauvegarde),
 *                         chacun réservant sa propre identité. Pas de bruit de démarrage : on teste le scénario.
 *     'independant'     : chaque poste est une installation neuve qui crée SES PROPRES données de base (rôle ADMIN,
 *                         boutique, caisse...) sur un cloud vide. Reproduit l'installation d'un nouveau poste.
 */
async function nouvelleCampagne({ etiquette, postes, pooler = true, demarrer = true, baseline = 'clone' }) {
  const cloud = await admin.creerBaseDeTest({ etiquette });
  const urlPostes = pooler ? cloud.url : cloud.urlDirecte;
  const stations = {};
  const liste = [];
  for (const p of postes) {
    const def = typeof p === 'string' ? { nom: p } : p;
    const cloudUrl = def.cloud === false ? null : (typeof def.cloud === 'string' ? def.cloud : urlPostes);
    const st = new Station({ nom: def.nom, cloudUrl, env: { ...ENV_RAPIDE, ...(def.env || {}) }, preload: def.preload || [] });
    stations[def.nom] = st;
    liste.push(st);
  }
  const campagne = {
    cloud,
    postes: stations,
    liste,
    /** URL de la base cloud pour les requêtes directes de vérification */
    get cloudUrl() { return cloud.urlDirecte; },
    async demarrerTous() { for (const s of liste) if (!s.proc) await s.demarrer(); },
    async terminer() {
      for (const s of liste) { try { await s.arreter(); } catch (_) { /* déjà arrêté */ } }
      for (const s of liste) s.nettoyer();
      try { await admin.supprimerBaseDeTest(cloud.nom); } catch (e) { console.warn(`Suppression de ${cloud.nom} impossible : ${e.message}`); }
    },
  };
  if (demarrer) {
    try {
      if (baseline === 'clone' && liste.length > 1) {
        const [premier, ...autres] = liste;
        // 1. le premier poste démarre seul, crée ses données de base, puis s'arrête
        await premier.demarrer();
        await pause(1500);
        await premier.arreter();
        // 2. le cloud reçoit ces données de base (client établi) ; les autres postes en reçoivent une copie
        await copierVersCloud(premier, cloud.urlDirecte);
        for (const s of autres) preparerCopie(premier.fichierDb, s.fichierDb);
        // 3. tous démarrent, l'un après l'autre : chacun réserve son identifiant auprès du cloud sans course
        await premier.demarrer();
        for (const s of autres) await s.demarrer();
      } else {
        await campagne.demarrerTous();
      }
    } catch (e) { await campagne.terminer(); throw e; }
  }
  return campagne;
}

module.exports = { nouvelleCampagne, peutLancer, copierVersCloud, ENV_RAPIDE, TABLES_GRAINE };
