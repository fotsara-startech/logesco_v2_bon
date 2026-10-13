/**
 * Administration du cloud de TEST pour la campagne de tests de synchronisation.
 *
 * Principe : l'URL d'une base Neon de développement est fournie par la variable d'environnement
 * SYNC_TEST_NEON_URL (jamais écrite dans un fichier). Les tests ne touchent JAMAIS cette base : ils créent une base
 * jetable « synctest_<horodatage> » dont le schéma est une copie de celui de la base de développement (tables,
 * colonnes, déclencheurs de date de modification), la vident, travaillent dedans, puis la suppriment.
 *
 * Garde-fous :
 *  - on ne supprime que les bases dont le nom commence par « synctest_ » ;
 *  - on ne se connecte jamais en écriture à la base d'origine.
 */
const { Pool } = require('pg');

const PREFIXE = 'synctest_';

function urlAdmin() {
  const url = process.env.SYNC_TEST_NEON_URL;
  if (!url) {
    throw new Error("SYNC_TEST_NEON_URL absent : fournissez l'URL de la base Neon de développement dans cette variable d'environnement.");
  }
  return url;
}

/** URL directe (sans « -pooler ») : les ordres d'administration (CREATE DATABASE) passent mieux sans PgBouncer */
function versDirect(url) {
  return url.replace('-pooler.', '.');
}

/** Même serveur, autre base de données */
function urlPourBase(url, base) {
  const u = new URL(url);
  u.pathname = `/${base}`;
  return u.toString();
}

function nouveauPool(url, extra = {}) {
  return new Pool({ connectionString: url, ssl: { rejectUnauthorized: false }, max: 2, connectionTimeoutMillis: 30000, ...extra });
}

/**
 * Coupure réseau passagère (délai dépassé, connexion réinitialisée, DNS) : on réessaie avec une attente croissante.
 * Sans cela, une coupure de quelques secondes faisait échouer un scénario entier, sans rapport avec la synchronisation.
 * Les opérations passées ici sont idempotentes (lecture, TRUNCATE, DROP IF EXISTS, création tolérant « existe déjà »).
 */
const ERREURS_RESEAU = /ETIMEDOUT|ECONNRESET|ECONNREFUSED|ENOTFOUND|EAI_AGAIN|EPIPE|timeout exceeded when trying to connect|Connection terminated|connection timeout/i;
function estErreurReseau(e) {
  if (!e) return false;
  const morceaux = [e.code, e.message, ...(Array.isArray(e.errors) ? e.errors.flatMap((x) => [x && x.code, x && x.message]) : [])];
  return ERREURS_RESEAU.test(morceaux.filter(Boolean).join(' '));
}
async function reessayerReseau(fn, { essais = 6 } = {}) {
  let derniere;
  for (let i = 1; i <= essais; i++) {
    try { return await fn(); } catch (e) {
      derniere = e;
      if (!estErreurReseau(e) || i === essais) throw e;
      await new Promise((r) => setTimeout(r, 1500 * i + Math.random() * 1000));
    }
  }
  throw derniere;
}

async function avecAdmin(fn) {
  // On se connecte à la base « postgres » : la copie par modèle exige que la base source n'ait AUCUNE connexion,
  // y compris la nôtre.
  return reessayerReseau(async () => {
    const pool = nouveauPool(urlPourBase(versDirect(urlAdmin()), 'postgres'), { max: 1 });
    // un pool en erreur (connexion coupée) ne doit pas faire tomber le processus de test
    pool.on('error', () => {});
    try { return await fn(pool); } finally { await pool.end().catch(() => {}); }
  });
}

/**
 * Crée une base jetable à partir du schéma de la base de développement, vidée de ses données.
 * @returns {Promise<{nom:string, url:string, urlDirecte:string}>}
 */
async function creerBaseDeTest({ etiquette = 'x', nom } = {}) {
  // etiquette : identifie le propriétaire (un agent, un fichier de tests) : « synctest_<etiquette>_<horodatage> »
  if (!/^[a-z0-9]{1,12}$/.test(etiquette)) throw new Error(`Étiquette invalide (minuscules/chiffres, 12 max) : ${etiquette}`);
  nom = nom || `${PREFIXE}${etiquette}_${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;
  if (!nom.startsWith(PREFIXE)) throw new Error(`Nom de base de test invalide : ${nom}`);
  const admin = urlAdmin();
  const baseOrigine = new URL(admin).pathname.replace(/^\//, '');

  await avecAdmin(async (pool) => {
    // La copie par modèle exige qu'aucune autre connexion n'utilise la base d'origine : on réessaie un instant
    let derniere;
    // Plusieurs créations simultanées (agents en parallèle) se bloquent mutuellement sur la base modèle : on réessaie
    // avec une pause aléatoire.
    for (let i = 0; i < 20; i++) {
      // Les connexions du pooler restent ouvertes un moment après usage. On ferme UNIQUEMENT celles qui sont inactives
      // (jamais une session active, par exemple celle d'une application de développement en cours d'utilisation).
      await pool.query(
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1 AND state = 'idle' AND pid <> pg_backend_pid()",
        [baseOrigine]
      );
      try {
        await pool.query(`CREATE DATABASE "${nom}" TEMPLATE "${baseOrigine}"`);
        return;
      } catch (e) {
        // « existe déjà » : un essai précédent a abouti malgré une coupure avant la réponse
        if (e.code === '42P04') return;
        derniere = e;
        if (!/being accessed by other users|source database/i.test(e.message)) break;
        await new Promise((r) => setTimeout(r, 2000 + Math.random() * 6000));
      }
    }
    throw derniere;
  });

  const urlDirecte = urlPourBase(versDirect(admin), nom);
  const url = urlPourBase(admin, nom);
  await viderDonnees(urlDirecte);
  return { nom, url, urlDirecte };
}

/** Vide toutes les tables du schéma public (le schéma est conservé) */
async function viderDonnees(urlBase) {
  return reessayerReseau(async () => {
    const pool = nouveauPool(urlBase, { max: 1 });
    pool.on('error', () => {});
    try {
      const t = await pool.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public'");
      if (t.rows.length) {
        const liste = t.rows.map((r) => `"public"."${r.tablename}"`).join(', ');
        await pool.query(`TRUNCATE ${liste} RESTART IDENTITY CASCADE`);
      }
      return t.rows.length;
    } finally { await pool.end().catch(() => {}); }
  });
}

/** Supprime une base de test (refuse toute base qui n'a pas le préfixe de test) */
async function supprimerBaseDeTest(nom) {
  if (!nom || !nom.startsWith(PREFIXE)) throw new Error(`Refus de supprimer « ${nom} » : ce n'est pas une base de test`);
  await avecAdmin(async (pool) => {
    await pool.query('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1 AND pid <> pg_backend_pid()', [nom]);
    await pool.query(`DROP DATABASE IF EXISTS "${nom}"`);
  });
}

/**
 * Supprime les bases de test oubliées d'UNE étiquette (campagne interrompue).
 * L'étiquette est obligatoire : sans elle on supprimerait les bases des autres exécutions en cours.
 */
async function nettoyerBasesOubliees(etiquette) {
  if (!etiquette) throw new Error('Étiquette obligatoire : refus de supprimer les bases de test des autres exécutions');
  return avecAdmin(async (pool) => {
    const r = await pool.query('SELECT datname FROM pg_database WHERE datname LIKE $1', [`synctest\\_${etiquette}\\_%`]);
    for (const { datname } of r.rows) {
      await pool.query('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1 AND pid <> pg_backend_pid()', [datname]);
      await pool.query(`DROP DATABASE IF EXISTS "${datname}"`);
    }
    return r.rows.map((x) => x.datname);
  });
}

/** Requête directe sur une base de test (vérifications des tests) */
async function requete(urlBase, sql, params = []) {
  return reessayerReseau(async () => {
    const pool = nouveauPool(urlBase, { max: 1 });
    pool.on('error', () => {});
    try { return (await pool.query(sql, params)).rows; } finally { await pool.end().catch(() => {}); }
  });
}

module.exports = { PREFIXE, creerBaseDeTest, supprimerBaseDeTest, nettoyerBasesOubliees, viderDonnees, requete, reessayerReseau, estErreurReseau, versDirect, urlPourBase, nouveauPool };
