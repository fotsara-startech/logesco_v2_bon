/**
 * Poste simulé pour les tests de synchronisation de bout en bout.
 *
 * Chaque poste est un VRAI serveur LOGESCO (node src/server.js) avec sa propre base SQLite, son propre port, sa
 * propre identité de poste, relié à la base cloud de TEST. Rien n'est simulé côté application : routes, hooks Prisma,
 * service de synchronisation, journal des envois, file de reprise, contrôle d'écart.
 *
 * Les postes partent d'une base au schéma vide (modèle créé une fois), comme une installation neuve : chacun fait donc
 * son propre premier démarrage (graine des rôles, boutique principale, réservation de sa plage d'identifiants).
 */
const { spawn, execFileSync } = require('node:child_process');
const fs = require('node:fs');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');

const BACKEND = path.resolve(__dirname, '..', '..', '..');
const SERVER = path.join(BACKEND, 'src', 'server.js');

let modeleSqlite = null;
const crypto = require('node:crypto');

function portLibre() {
  return new Promise((resolve, reject) => {
    const s = net.createServer();
    s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => resolve(p)); });
    s.on('error', reject);
  });
}

const pause = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Base SQLite au schéma vide, créée une seule fois PAR VERSION DU SCHÉMA et partagée entre tous les processus de test
 * (dossier temporaire du système) : la première exécution la construit (~30 s), les suivantes la copient.
 */
function creerModeleSqlite() {
  if (modeleSqlite && fs.existsSync(modeleSqlite)) return modeleSqlite;
  const schema = path.join(BACKEND, 'prisma', 'schema.prisma');
  const empreinte = crypto.createHash('sha1').update(fs.readFileSync(schema)).digest('hex').slice(0, 12);
  const dossier = path.join(os.tmpdir(), 'logesco-e2e-modeles');
  fs.mkdirSync(dossier, { recursive: true });
  const final = path.join(dossier, `modele-${empreinte}.db`);
  if (!fs.existsSync(final)) {
    // Construit sous un nom unique puis renommé : un autre processus ne voit jamais un modèle à moitié écrit
    const temporaire = path.join(dossier, `construction-${process.pid}-${Date.now()}.db`);
    execFileSync(process.execPath, [path.join(BACKEND, 'node_modules', 'prisma', 'build', 'index.js'), 'db', 'push', '--accept-data-loss', '--skip-generate', `--schema=${schema}`], {
      cwd: BACKEND,
      env: { ...process.env, DATABASE_URL: `file:${temporaire.split(path.sep).join('/')}` },
      stdio: 'pipe',
      timeout: 180000,
    });
    try { fs.renameSync(temporaire, final); } catch (_) { try { fs.rmSync(temporaire, { force: true }); } catch (__) { /* déjà créé par un autre */ } }
  }
  modeleSqlite = final;
  return final;
}

class Station {
  /**
   * @param {{nom:string, cloudUrl:string|null, env?:Object, preload?:string[], port?:number}} options
   *   cloudUrl : URL de la base cloud de test (null = poste 100 % local)
   *   env      : variables d'environnement supplémentaires (ex. pour un proxy de pannes)
   *   preload  : modules à précharger (node -r) — injection de pannes réseau
   */
  constructor({ nom, cloudUrl, env = {}, preload = [], port = null }) {
    this.nom = nom;
    this.cloudUrl = cloudUrl;
    this.extraEnv = env;
    this.preload = preload;
    this.port = port;
    this.dossier = fs.mkdtempSync(path.join(os.tmpdir(), `logesco-${nom}-`));
    this.fichierDb = path.join(this.dossier, 'database', 'logesco.db');
    this.sortie = [];
    this.proc = null;
    this.token = 'test-token'; // accepté hors production : utilisateur 1
  }

  get url() { return `http://127.0.0.1:${this.port}`; }

  /** Démarre le serveur et attend qu'il réponde */
  async demarrer({ delaiMs = 90000 } = {}) {
    if (this.proc) throw new Error(`${this.nom} déjà démarré`);
    if (!this.port) this.port = await portLibre();
    if (!fs.existsSync(this.fichierDb)) {
      fs.mkdirSync(path.dirname(this.fichierDb), { recursive: true });
      fs.copyFileSync(creerModeleSqlite(), this.fichierDb);
    }
    const env = {
      ...process.env,
      NODE_ENV: 'development',
      DEPLOYMENT_TYPE: 'local',
      PORT: String(this.port),
      DATABASE_URL: `file:${this.fichierDb.replace(/\\/g, '/')}`,
      LOGESCO_DATA_DIR: this.dossier,
      JWT_SECRET: 'secret-de-test',
      CORS_ORIGIN: '*',
      LOG_LEVEL: 'error',
      ...this.extraEnv,
    };
    // Garde-fou : un poste de test ne se relie JAMAIS qu'à une base cloud jetable « synctest_* ».
    // Seule exception : l'URL volontairement INJOIGNABLE des scénarios « hors ligne » (127.0.0.1, port 9 : rien n'y
    // écoute), qui ne peut atteindre aucune base.
    const injoignable = /^postgres(ql)?:\/\/[^@]*@127\.0\.0\.1:9\//.test(this.cloudUrl || '');
    if (this.cloudUrl && !injoignable && !/\/synctest_[a-z0-9_]+(\?|$)/.test(this.cloudUrl)) {
      throw new Error(`${this.nom} : refus de démarrer, l'URL cloud n'est pas celle d'une base de test jetable (synctest_*)`);
    }
    // Poste sans cloud : on met CLOUD_DB_URL à une chaîne VIDE plutôt que de la supprimer. Le serveur charge
    // backend/.env (dotenv), qui NE remplace PAS une variable déjà définie : la supprimer laissait le .env réinjecter
    // l'URL de la base de développement (incident : des réservations de poste ont ainsi été créées dans neondb).
    env.CLOUD_DB_URL = this.cloudUrl || '';
    // l'URL d'administration ne doit jamais atteindre le serveur testé
    delete env.SYNC_TEST_NEON_URL;

    const args = [...this.preload.flatMap((m) => ['-r', m]), SERVER];
    this.proc = spawn(process.execPath, args, { cwd: BACKEND, env, stdio: ['ignore', 'pipe', 'pipe'] });
    const garder = (b) => { this.sortie.push(b.toString()); if (this.sortie.length > 4000) this.sortie.splice(0, 1000); };
    this.proc.stdout.on('data', garder);
    this.proc.stderr.on('data', garder);
    this.arret = new Promise((resolve) => this.proc.on('exit', (code, signal) => { this.proc = null; resolve({ code, signal }); }));

    const debut = Date.now();
    while (Date.now() - debut < delaiMs) {
      if (!this.proc) throw new Error(`${this.nom} s'est arrêté au démarrage :\n${this.journal(40)}`);
      try {
        const r = await fetch(`${this.url}/health`, { signal: AbortSignal.timeout(2000) });
        if (r.ok) return this;
      } catch (_) { /* pas encore prêt */ }
      await pause(500);
    }
    throw new Error(`${this.nom} ne répond pas après ${delaiMs} ms :\n${this.journal(40)}`);
  }

  /** Arrêt propre (ou brutal : simule une coupure de courant en pleine synchronisation) */
  async arreter({ brutal = false } = {}) {
    if (!this.proc) return;
    const p = this.proc;
    p.kill(brutal ? 'SIGKILL' : 'SIGTERM');
    await Promise.race([this.arret, pause(8000)]);
    if (this.proc) { try { p.kill('SIGKILL'); } catch (_) {} await Promise.race([this.arret, pause(3000)]); }
  }

  async redemarrer(options = {}) {
    await this.arreter(options);
    return this.demarrer();
  }

  /** Dernières lignes de journal du serveur */
  journal(n = 60) {
    return this.sortie.join('').split('\n').slice(-n).join('\n');
  }

  /** Appel d'API du poste (JSON). Renvoie { statut, corps } sans jamais lever sur un statut HTTP d'erreur. */
  async api(methode, chemin, corps, { delaiMs = 60000 } = {}) {
    const appel = () => fetch(`${this.url}/api/v1${chemin}`, {
      method: methode,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${this.token}` },
      body: corps === undefined ? undefined : JSON.stringify(corps),
      signal: AbortSignal.timeout(delaiMs),
    });
    // Une erreur réseau locale doit dire QUEL poste, QUEL appel, quel code, et si le processus tourne encore
    const expliquer = (e) => {
      const code = e && e.cause && (e.cause.code || e.cause.message);
      // Processus arrêté : les dernières lignes de son journal disent pourquoi (plantage, arrêt volontaire...)
      const fin = this.proc ? '' : ' ; dernières lignes du journal :' + String.fromCharCode(10) + this.journal(14).split(String.fromCharCode(10)).map((l) => '    ' + l.slice(0, 200)).join(String.fromCharCode(10));
      const err = new Error(`${this.nom} ${methode} ${chemin} : ${e.message} (${code}) ; processus ${this.proc ? 'vivant' : 'ARRÊTÉ'}${fin}`);
      err.cause = e;
      return err;
    };
    let r;
    try {
      r = await appel();
    } catch (e) {
      // Connexion réutilisée que le serveur a déjà fermée (inactivité > 5 s) : « fetch failed » avant tout envoi.
      // On réessaie une fois, sauf pour un POST (une vente ne doit jamais être rejouée par le banc).
      const code = e && e.cause && e.cause.code;
      if (methode === 'POST' || !['UND_ERR_SOCKET', 'ECONNRESET', 'EPIPE'].includes(code)) throw expliquer(e);
      try { r = await appel(); } catch (e2) { throw expliquer(e2); }
    }
    let json = null;
    const texte = await r.text();
    try { json = JSON.parse(texte); } catch (_) { json = { texte }; }
    return { statut: r.status, corps: json };
  }

  /** Lance un cycle de synchronisation et rend le statut */
  async synchroniser() {
    const r = await this.api('POST', '/sync/trigger', {}, { delaiMs: 150000 });
    return r;
  }

  async statutSync() {
    return (await this.api('GET', '/sync/status')).corps.data;
  }

  /**
   * Synchronise jusqu'à ce que le poste soit « calme » : plus aucune opération en attente ni refusée.
   * Un cycle déjà en cours ignore les déclenchements manuels : on relance donc en boucle jusqu'au résultat.
   * @returns {Promise<{calme:boolean, enAttente:number, refusees:number, dureeMs:number}>}
   */
  async synchroniserJusquaCalme({ delaiMs = 120000, pauseMs = 1500 } = {}) {
    const debut = Date.now();
    let dernier = { enAttente: -1, refusees: 0 };
    while (Date.now() - debut < delaiMs) {
      try { await this.synchroniser(); } catch (_) { /* poste lent ou coupé : on réessaie */ }
      dernier = {
        enAttente: this.enAttente(),
        refusees: Number(this.lire("SELECT COUNT(*) n FROM operation_log WHERE status = 'failed'")[0].n),
      };
      if (dernier.enAttente === 0) return { calme: true, ...dernier, dureeMs: Date.now() - debut };
      await pause(pauseMs);
    }
    return { calme: false, ...dernier, dureeMs: Date.now() - debut };
  }

  /** Lecture directe de la base SQLite du poste (assertions) */
  lire(sql, ...params) {
    const db = new DatabaseSync(this.fichierDb, { readOnly: true });
    try {
      db.exec('PRAGMA busy_timeout = 5000');
      return db.prepare(sql).all(...params);
    } finally { db.close(); }
  }

  /** Nombre d'opérations en attente d'envoi (pending + failed) */
  enAttente() {
    return Number(this.lire("SELECT COUNT(*) n FROM operation_log WHERE status IN ('pending','failed')")[0].n);
  }

  identite() {
    return this.lire('SELECT installation_id, block_start FROM sync_identity')[0] || null;
  }

  /** Supprime les fichiers du poste */
  nettoyer() {
    try { fs.rmSync(this.dossier, { recursive: true, force: true }); } catch (_) { /* fichier encore ouvert */ }
  }
}

module.exports = { Station, pause, portLibre, creerModeleSqlite, BACKEND };
