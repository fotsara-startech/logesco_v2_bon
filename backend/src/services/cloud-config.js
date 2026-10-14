/**
 * Configuration de la connexion au cloud (base Neon) depuis l'application, sans modifier le .env à la main.
 *
 * Principes de sécurité :
 *  - le mot de passe n'est JAMAIS renvoyé ni écrit dans un journal : toute réponse ne porte que l'hôte, la base et
 *    l'utilisateur ;
 *  - l'URL est validée STRICTEMENT avant d'être écrite dans le .env : un retour à la ligne, un guillemet ou une espace
 *    permettrait d'injecter d'autres variables dans le fichier de configuration ;
 *  - l'URL est testée (connexion réelle, délai borné) avant d'être enregistrée ;
 *  - l'URL n'est PAS appliquée à chaud : les hooks de journalisation des écritures locales ne s'installent qu'au
 *    démarrage du serveur, si CLOUD_DB_URL existe. L'enregistrer puis redémarrer le serveur est le seul chemin sûr
 *    (l'appliquer à chaud laisserait des écritures locales sans journal, donc jamais envoyées).
 */

const fs = require('fs');
const path = require('path');

const CLE = 'CLOUD_DB_URL';

/** Tables dont la présence prouve que la base a reçu le schéma LOGESCO */
const TABLES_SCHEMA = ['produits', 'ventes', 'clients', 'user_roles', 'boutiques'];

/**
 * Valide une URL de connexion PostgreSQL et en extrait ce qui peut être montré (jamais le mot de passe).
 * @returns {{ok:boolean, erreur?:string, info?:{hote:string, base:string, utilisateur:string}}}
 */
function valider(url) {
  if (typeof url !== 'string') return { ok: false, erreur: "Collez le lien de connexion de la base Neon." };
  const brut = url.trim();
  if (!brut) return { ok: false, erreur: "Collez le lien de connexion de la base Neon." };
  // Aucun caractère de contrôle, espace ni guillemet : ils permettraient d'injecter d'autres lignes dans le .env
  if (/[\s"'`\\]/.test(brut)) {
    return { ok: false, erreur: "Le lien contient des espaces, des guillemets ou un retour à la ligne : recopiez-le tel que Neon l'affiche (une seule ligne)." };
  }
  if (!/^postgres(ql)?:\/\//i.test(brut)) {
    return { ok: false, erreur: "Le lien doit commencer par postgresql:// (copiez « Connection string » dans la console Neon)." };
  }
  let u;
  try {
    u = new URL(brut);
  } catch (_) {
    return { ok: false, erreur: "Le lien n'est pas valide : vérifiez qu'il est complet." };
  }
  if (!u.hostname) return { ok: false, erreur: "Le lien ne contient pas l'adresse du serveur." };
  if (!u.username) return { ok: false, erreur: "Le lien ne contient pas le nom d'utilisateur." };
  if (!u.password) return { ok: false, erreur: "Le lien ne contient pas le mot de passe." };
  const base = decodeURIComponent((u.pathname || '').replace(/^\//, ''));
  if (!base) return { ok: false, erreur: "Le lien ne contient pas le nom de la base de données (à la fin, après l'adresse)." };
  return { ok: true, info: { hote: u.hostname, base, utilisateur: decodeURIComponent(u.username) } };
}

/** Message clair, en français, pour une erreur de connexion (jamais le mot de passe) */
function expliquerErreur(e) {
  const m = String((e && (e.code || e.message)) || '');
  if (/ENOTFOUND|EAI_AGAIN/i.test(m)) return "L'adresse du serveur est introuvable : vérifiez le lien et la connexion internet de cet ordinateur.";
  if (/ETIMEDOUT|timeout|timed out/i.test(m)) return "Le serveur Neon ne répond pas à temps : vérifiez la connexion internet, puis réessayez.";
  if (/ECONNREFUSED/i.test(m)) return "Connexion refusée par le serveur : vérifiez le lien.";
  if (/password authentication failed|28P01/i.test(m)) return "Le mot de passe ou le nom d'utilisateur est refusé : recopiez le lien depuis la console Neon (le mot de passe a peut-être été changé).";
  if (/does not exist|3D000/i.test(m)) return "Cette base de données n'existe pas : vérifiez le nom à la fin du lien.";
  if (/SSL|certificate/i.test(m)) return "La connexion sécurisée a échoué : vérifiez le lien (il doit contenir sslmode=require).";
  return "Connexion impossible : vérifiez le lien et la connexion internet.";
}

/**
 * Teste réellement la connexion (délai borné) et regarde si la base a le schéma LOGESCO.
 * @param {string} url
 * @param {{creerClient?:Function, delaiMs?:number}} [options]  creerClient : pour les tests
 * @returns {Promise<{ok:boolean, message:string, info?:Object, schemaPret?:boolean, tablesManquantes?:string[], donnees?:Object}>}
 */
async function tester(url, { creerClient = null, delaiMs = 12000 } = {}) {
  const v = valider(url);
  if (!v.ok) return { ok: false, message: v.erreur };
  const fabrique = creerClient || ((chaine) => {
    const { Client } = require('pg');
    return new Client({ connectionString: chaine, ssl: { rejectUnauthorized: false }, connectionTimeoutMillis: delaiMs });
  });
  const client = fabrique(url.trim());
  try {
    await client.connect();
    const t = await client.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = ANY($1::text[])",
      [TABLES_SCHEMA]
    );
    const presentes = new Set(t.rows.map((r) => r.table_name));
    const manquantes = TABLES_SCHEMA.filter((x) => !presentes.has(x));
    const schemaPret = manquantes.length === 0;
    let donnees = null;
    if (schemaPret) {
      // Le cloud contient-il déjà des données ? (information pour la personne : ce poste enverra ou non son historique)
      const q = async (table) => Number((await client.query(`SELECT COUNT(*)::int AS n FROM "${table}"`)).rows[0].n);
      donnees = { produits: await q('produits'), clients: await q('clients'), ventes: await q('ventes') };
    }
    return {
      ok: true,
      message: schemaPret
        ? 'Connexion réussie.'
        : "Connexion réussie, mais la base ne contient pas encore les tables de LOGESCO : elles doivent d'abord y être installées.",
      info: v.info, schemaPret, tablesManquantes: manquantes, donnees,
    };
  } catch (e) {
    return { ok: false, message: expliquerErreur(e), info: v.info };
  } finally {
    try { await client.end(); } catch (_) { /* connexion déjà fermée */ }
  }
}

/** Fichier .env que le serveur lit au démarrage (même logique que server.js et server-pkg-entry.js) */
function cheminEnv() {
  if (process.env.LOGESCO_ENV_FILE) return process.env.LOGESCO_ENV_FILE; // tests
  const dossier = process.env.LOGESCO_DATA_DIR || path.join(__dirname, '..', '..');
  return path.join(dossier, '.env');
}

/** Lit la valeur de CLOUD_DB_URL dans le fichier (ou null) */
function lireDansFichier(fichier = cheminEnv()) {
  try {
    for (const ligne of fs.readFileSync(fichier, 'utf8').split(/\r?\n/)) {
      const t = ligne.trim();
      if (!t || t.startsWith('#')) continue;
      const i = t.indexOf('=');
      if (i <= 0 || t.slice(0, i).trim() !== CLE) continue;
      let val = t.slice(i + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) val = val.slice(1, -1);
      return val || null;
    }
  } catch (_) { /* fichier absent */ }
  return null;
}

/**
 * Enregistre l'URL dans le .env : remplace la ligne existante ou l'ajoute, sans toucher aux autres variables.
 * Écriture atomique (fichier temporaire puis renommage) avec une copie de sécurité de l'ancien fichier.
 */
function enregistrer(url, fichier = cheminEnv()) {
  const v = valider(url);
  if (!v.ok) throw new Error(v.erreur);
  const valeur = url.trim();
  let lignes = [];
  try { lignes = fs.readFileSync(fichier, 'utf8').split(/\r?\n/); } catch (_) { /* nouveau fichier */ }
  while (lignes.length && lignes[lignes.length - 1] === '') lignes.pop();

  let remplace = false;
  lignes = lignes.map((l) => {
    const t = l.trim();
    const i = t.indexOf('=');
    if (t && !t.startsWith('#') && i > 0 && t.slice(0, i).trim() === CLE) { remplace = true; return `${CLE}="${valeur}"`; }
    return l;
  });
  if (!remplace) lignes.push(`${CLE}="${valeur}"`);

  fs.mkdirSync(path.dirname(fichier), { recursive: true });
  try { if (fs.existsSync(fichier)) fs.copyFileSync(fichier, fichier + '.avant-cloud'); } catch (_) { /* copie facultative */ }
  const temporaire = `${fichier}.${process.pid}.tmp`;
  fs.writeFileSync(temporaire, lignes.join('\n') + '\n', { encoding: 'utf8', mode: 0o600 });
  fs.renameSync(temporaire, fichier);
  return v.info;
}

/**
 * État de la configuration, sans jamais exposer le mot de passe.
 *  - active : l'URL avec laquelle le serveur tourne en ce moment (null = 100 % local) ;
 *  - enregistree : l'URL du fichier ; si elle diffère de l'active, un redémarrage est nécessaire.
 */
function lireConfiguration(fichier = cheminEnv()) {
  const active = process.env[CLE] || null;
  const enregistree = lireDansFichier(fichier);
  const info = (u) => { const v = u ? valider(u) : null; return v && v.ok ? v.info : null; };
  return {
    active: !!active,
    infoActive: info(active),
    enregistree: !!enregistree,
    infoEnregistree: info(enregistree),
    redemarrageNecessaire: (enregistree || null) !== (active || null),
  };
}

module.exports = { CLE, TABLES_SCHEMA, valider, expliquerErreur, tester, cheminEnv, lireDansFichier, enregistrer, lireConfiguration };
