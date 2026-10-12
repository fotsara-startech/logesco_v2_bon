/**
 * Banc d'injection de pannes réseau entre un poste LOGESCO et le cloud Neon.
 *
 * PRINCIPE
 *   poste (node -r preload-reseau.js)  --TCP-->  BancPannes (127.0.0.1:<port libre>)  --TCP-->  Neon:5432
 *
 *   Le module préchargé `harness/preload-reseau.js` redirige toute connexion TCP sortante vers le port 5432 vers le
 *   banc (réécriture dans `net.Socket.prototype.connect`). Le banc relaie les octets BRUTS : le TLS reste de bout en
 *   bout entre le poste et Neon, donc le SNI (nom d'hôte Neon, nécessaire au routage) et la liaison de canal SCRAM
 *   (channel_binding=require) restent ceux de la production. Le banc ne voit que du chiffré.
 *
 *   Le banc vit DANS LE PROCESSUS DU TEST : on le règle à chaud pendant que le poste tourne.
 *
 * UTILISATION
 *   const banc = await BancPannes.demarrer({ urlNeon: process.env.SYNC_TEST_NEON_URL });   // seul l'hôte est lu
 *   const c = await nouvelleCampagne({ etiquette: 'reseau', postes: [{ nom: 'A', ...banc.optionsPoste() }, 'B'] });
 *   t.after(() => banc.arreter());
 *   banc.regler({ latenceMs: 1000 });                 // aller-retour ≈ 1 s
 *   banc.regler({ debitOctetsParSec: 20000 });        // plafond de débit (chaque sens)
 *   banc.regler({ coupureConnexion: 0.3 });           // 30 % des connexions sont coupées en cours de route
 *   banc.regler({ coupureRequete: 0.05 });            // 5 % des requêtes émises sont coupées au milieu
 *   banc.trouNoir(180000);                            // connexions acceptées, plus aucun octet pendant 3 min
 *   banc.coupureTotale(90000);                        // connexions existantes tuées, nouvelles refusées pendant 90 s
 *   banc.alternance({ marcheMs: [2000, 5000], arretMs: [2000, 5000] });   // marche/arrêt rapide
 *   banc.normal();                                    // retour à un réseau parfait
 *
 * LIMITES (voir aussi le rapport)
 *   - La latence s'applique aux OCTETS de données (pas à l'établissement TCP, accepté immédiatement par le noyau). Le
 *     TLS et l'authentification SCRAM faisant plusieurs allers-retours, la connexion paie bien plusieurs fois la latence.
 *   - Un refus est émis par une réinitialisation (RST) immédiate après l'accept, pas par un vrai ECONNREFUSED : côté
 *     poste on voit ECONNRESET / « Connection terminated unexpectedly ».
 *   - Seules les connexions vers le port 5432 sont déviées. Les requêtes directes du test (vérifications, oracle) ne
 *     passent PAS par le banc, volontairement.
 *   - Pas de perte/réordonnancement de paquets TCP (le noyau le masquerait de toute façon) : on modélise ses effets
 *     (latence, débit, gel, coupure).
 */
const net = require('node:net');
const path = require('node:path');


// Les requêtes de vérification du test vont DIRECT au cloud (sans banc). Sur une machine dont la liaison Neon est
// elle-même médiocre, une requête isolée échoue de temps en temps : on la rejoue (6 essais) plutôt que de faire échouer
// tout le scénario. Doit être chargé AVANT harness/oracle.js (qui récupère `requete` à son chargement).
{
  const admin = require('./cloud-admin');
  if (!admin.requete.__avecReprise) {
    const originale = admin.requete;
    const rejouable = async (...args) => {
      let derniere;
      for (let i = 0; i < 6; i++) {
        try { return await originale(...args); } catch (e) {
          derniere = e;
          if (!/timeout|terminated|ETIMEDOUT|ENOTFOUND|ECONN|EAI_AGAIN|AggregateError|disconnected|TLS|socket|EPIPE|reset/i.test(`${e.code} ${e.name} ${e.message}`)) throw e;
          await new Promise((r) => setTimeout(r, 3000 * (i + 1)));
        }
      }
      throw derniere;
    };
    rejouable.__avecReprise = true;
    admin.requete = rejouable;
  }
}

const PRELOAD = path.join(__dirname, 'preload-reseau.js');

const alea = (min, max) => min + Math.random() * (max - min);
const entier = (min, max) => Math.floor(alea(min, max + 1));
const pause = (ms) => new Promise((r) => setTimeout(r, ms));

function hoteDe(url) {
  return new URL(url).hostname;
}

function tuer(socket) {
  if (!socket || socket.destroyed) return;
  try { if (typeof socket.resetAndDestroy === 'function') socket.resetAndDestroy(); else socket.destroy(); } catch (_) { try { socket.destroy(); } catch (__) { /* déjà détruit */ } }
}

/** Un sens de circulation (client→Neon ou Neon→client) : file d'attente ordonnée avec latence, débit et gel */
class Voie {
  constructor(banc, conn, source, dest, sens) {
    this.banc = banc;
    this.conn = conn;
    this.source = source;
    this.dest = dest;
    this.sens = sens; // 'montant' (poste → Neon) | 'descendant'
    this.file = [];
    this.dernierDu = 0;
    this.libreTx = 0;
    this.minuteur = null;
  }

  pousser(buf) {
    const b = this.banc.etat;
    const maintenant = Date.now();
    // découpe en tranches si le débit est plafonné : l'écoulement est alors régulier plutôt qu'en rafale
    const taille = b.debitOctetsParSec ? Math.max(256, Math.min(2048, Math.floor(b.debitOctetsParSec / 4))) : buf.length;
    for (let i = 0; i < buf.length; i += taille) {
      const tranche = buf.subarray(i, i + taille);
      let du = maintenant + Math.max(0, b.latenceMs / 2 + (b.jitterMs ? alea(-b.jitterMs, b.jitterMs) / 2 : 0));
      if (b.debitOctetsParSec) {
        this.libreTx = Math.max(this.libreTx, maintenant) + (tranche.length / b.debitOctetsParSec) * 1000;
        du = Math.max(du, this.libreTx);
      }
      du = Math.max(du, this.dernierDu); // l'ordre des octets ne change jamais
      this.dernierDu = du;
      this.file.push({ buf: tranche, du });
    }
    this.planifier();
  }

  planifier() {
    if (this.minuteur || this.file.length === 0) return;
    const attente = Math.max(0, Math.min(this.file[0].du - Date.now(), 200));
    this.minuteur = setTimeout(() => { this.minuteur = null; this.vider(); }, attente);
  }

  vider() {
    if (this.conn.fini) return;
    const banc = this.banc;
    // trou noir : on ne livre rien, mais on garde les octets (comme une liaison gelée qui finit par repartir)
    if (banc.trouNoirActif()) { this.planifier(); return; }
    while (this.file.length && this.file[0].du <= Date.now()) {
      const { buf } = this.file.shift();
      if (this.dest.destroyed) { this.conn.fermer(); return; }
      this.dest.write(buf);
      banc.stats[this.sens === 'montant' ? 'octetsMontants' : 'octetsDescendants'] += buf.length;
      this.conn.octets += buf.length;
      if (this.conn.coupeApres !== null && this.conn.octets >= this.conn.coupeApres) {
        banc.stats.coupuresAleatoires++;
        this.conn.couper();
        return;
      }
    }
    this.planifier();
  }
}

class Connexion {
  constructor(banc, client) {
    this.banc = banc;
    this.client = client;
    this.amont = null;
    this.fini = false;
    this.octets = 0;
    // connexion « condamnée » : coupée après un volume d'octets tiré au hasard
    this.coupeApres = Math.random() < banc.etat.coupureConnexion ? entier(banc.etat.coupureMinOctets, banc.etat.coupureMaxOctets) : null;
    this.voies = [];
  }

  demarrer() {
    const banc = this.banc;
    this.amont = net.connect({ host: banc.cible.host, port: banc.cible.port });
    this.amont.setNoDelay(true);
    this.client.setNoDelay(true);
    const montante = new Voie(banc, this, this.client, this.amont, 'montant');
    const descendante = new Voie(banc, this, this.amont, this.client, 'descendant');
    this.voies = [montante, descendante];
    this.client.on('data', (b) => {
      banc.stats.envoisMontants++; // ~ un envoi du poste = une requête (ou une étape de TLS/authentification)
      const p = banc.etat.coupureRequete;
      if (p > 0 && Math.random() < p) {
        banc.stats.coupuresRequete++;
        // « au milieu d'une requête » : la moitié des octets part, puis la liaison tombe
        if (b.length > 1) { try { this.amont.write(b.subarray(0, Math.floor(b.length / 2))); } catch (_) { /* ignoré */ } }
        this.couper();
        return;
      }
      montante.pousser(b);
    });
    this.amont.on('data', (b) => descendante.pousser(b));
    const fin = () => this.fermer();
    this.client.on('error', fin); this.amont.on('error', fin);
    this.client.on('close', fin); this.amont.on('close', fin);
  }

  /** Coupure brutale (RST) des deux côtés */
  couper() {
    if (this.fini) return;
    this.fini = true;
    this.banc.connexions.delete(this);
    this.voies.forEach((v) => clearTimeout(v.minuteur));
    tuer(this.client); tuer(this.amont);
  }

  /** Fermeture normale */
  fermer() {
    if (this.fini) return;
    this.fini = true;
    this.banc.connexions.delete(this);
    this.voies.forEach((v) => clearTimeout(v.minuteur));
    try { this.client.destroy(); } catch (_) { /* déjà fermé */ }
    try { this.amont && this.amont.destroy(); } catch (_) { /* déjà fermé */ }
  }
}

const ETAT_PARFAIT = {
  latenceMs: 0, // aller-retour simulé
  jitterMs: 0, // ± sur l'aller-retour
  debitOctetsParSec: 0, // 0 = illimité (chaque sens)
  coupureConnexion: 0, // probabilité qu'une NOUVELLE connexion soit condamnée
  coupureMinOctets: 3000, // volume (2 sens cumulés) après lequel elle est coupée : tirage entre min et max
  coupureMaxOctets: 80000,
  coupureRequete: 0, // probabilité qu'un envoi du poste soit coupé en son milieu
};

class BancPannes {
  /** @param {{host:string, port?:number}} cible */
  constructor(cible) {
    this.cible = { host: cible.host, port: cible.port || 5432 };
    this.etat = { ...ETAT_PARFAIT };
    this.jusquaTrouNoir = 0;
    this.jusquaRefus = 0;
    this.refusPerpetuel = false;
    this.connexions = new Set();
    this.serveur = null;
    this.port = null;
    this.alternanceActive = false;
    this.minuteurAlternance = null;
    this.stats = { acceptees: 0, refusees: 0, coupuresAleatoires: 0, coupuresRequete: 0, coupuresTotales: 0, octetsMontants: 0, octetsDescendants: 0, envoisMontants: 0 };
  }

  /** Démarre un banc sur un port libre de 127.0.0.1. Seul l'hôte de l'URL est lu (jamais le mot de passe). */
  static async demarrer({ urlNeon = process.env.SYNC_TEST_NEON_URL, host, port } = {}) {
    const cible = { host: host || (urlNeon ? hoteDe(urlNeon) : null), port: port || 5432 };
    if (!cible.host) throw new Error('BancPannes : hôte cible inconnu (urlNeon ou host)');
    const banc = new BancPannes(cible);
    await banc._ecouter();
    return banc;
  }

  _ecouter() {
    return new Promise((resolve, reject) => {
      this.serveur = net.createServer((client) => this._accepter(client));
      this.serveur.on('error', reject);
      this.serveur.listen(0, '127.0.0.1', () => { this.port = this.serveur.address().port; resolve(); });
    });
  }

  _accepter(client) {
    this.stats.acceptees++;
    if (this.refusActif()) { this.stats.refusees++; tuer(client); return; }
    const conn = new Connexion(this, client);
    this.connexions.add(conn);
    conn.demarrer();
  }

  /** Options à fusionner dans la définition d'un poste de `nouvelleCampagne` */
  optionsPoste() {
    return { preload: [PRELOAD], env: { LOGESCO_FAULT_PROXY_PORT: String(this.port) } };
  }

  trouNoirActif() { return Date.now() < this.jusquaTrouNoir; }
  refusActif() { return this.refusPerpetuel || Date.now() < this.jusquaRefus; }

  /** Règle les paramètres continus (latence, débit, coupures aléatoires) ; sans effet sur les connexions déjà condamnées */
  regler(parametres) {
    for (const k of Object.keys(parametres)) if (!(k in ETAT_PARFAIT)) throw new Error(`Paramètre inconnu : ${k}`);
    Object.assign(this.etat, parametres);
    return this;
  }

  /** Connexions acceptées mais plus aucun octet ne circule (ms) ; Infinity = jusqu'à normal() */
  trouNoir(ms) { this.jusquaTrouNoir = ms === Infinity ? Number.MAX_SAFE_INTEGER : Date.now() + ms; return this; }
  finTrouNoir() { this.jusquaTrouNoir = 0; return this; }

  /** Coupure totale : les connexions existantes sont tuées, les nouvelles refusées (ms) ; Infinity = jusqu'à normal()/retablir() */
  coupureTotale(ms) {
    if (ms === Infinity) this.refusPerpetuel = true; else this.jusquaRefus = Date.now() + ms;
    this.tuerToutes();
    return this;
  }

  retablir() { this.refusPerpetuel = false; this.jusquaRefus = 0; return this; }

  tuerToutes() {
    for (const c of [...this.connexions]) { this.stats.coupuresTotales++; c.couper(); }
  }

  /**
   * Alternance rapide marche/arrêt. Chaque phase dure un temps tiré entre les bornes. Pendant « arrêt », comportement de
   * coupure totale. `arreterAlternance()` ou `normal()` la termine (réseau rétabli).
   */
  alternance({ marcheMs = [2000, 5000], arretMs = [2000, 5000] } = {}) {
    this.arreterAlternance();
    this.alternanceActive = true;
    const phase = (enMarche) => {
      if (!this.alternanceActive) return;
      if (enMarche) { this.refusPerpetuel = false; this.jusquaRefus = 0; } else { this.refusPerpetuel = true; this.tuerToutes(); }
      this.stats.phases = (this.stats.phases || 0) + 1;
      this.minuteurAlternance = setTimeout(() => phase(!enMarche), alea(...(enMarche ? marcheMs : arretMs)));
    };
    phase(true);
    return this;
  }

  arreterAlternance() {
    this.alternanceActive = false;
    clearTimeout(this.minuteurAlternance);
    this.retablir();
    return this;
  }

  /** Réseau parfait : tous les modes à zéro, alternance arrêtée */
  normal() {
    this.arreterAlternance();
    this.etat = { ...ETAT_PARFAIT };
    this.jusquaTrouNoir = 0;
    this.retablir();
    return this;
  }

  /** Arrête le banc (tue les connexions, ferme l'écoute) */
  async arreter() {
    this.arreterAlternance();
    this.tuerToutes();
    if (this.serveur) await new Promise((r) => this.serveur.close(() => r()));
    this.serveur = null;
  }
}

// ---------------------------------------------------------------------------------------------------------------
// Aides de mesure communes aux scénarios
// ---------------------------------------------------------------------------------------------------------------

/** Répartition des statuts du journal d'envoi d'un poste : { pending, failed, synced, cancelled } */
function statutsOperations(station) {
  const o = {};
  for (const r of station.lire('SELECT status, COUNT(*) n FROM operation_log GROUP BY status')) o[r.status] = Number(r.n);
  return o;
}

/** Opérations « failed » avec leur message : une erreur de liaison classée à tort comme refus de données */
function operationsRefusees(station) {
  return station.lire("SELECT table_name, operation_type, record_id, error_message FROM operation_log WHERE status = 'failed'");
}

/**
 * Lignes en double d'après les clés naturelles, sur un poste ET dans le cloud. Rend { poste:{}, cloud:{} } où chaque
 * clé est « table.colonne » et la valeur la liste des valeurs répétées.
 */
async function doublonsNaturels(station, cloudUrl, cles = [['produits', 'reference'], ['ventes', 'numero_vente'], ['clients', 'telephone']]) {
  const admin = require('./cloud-admin');
  const res = { poste: {}, cloud: {} };
  for (const [table, col] of cles) {
    try {
      const l = station.lire(`SELECT "${col}" v, COUNT(*) n FROM "${table}" WHERE "${col}" IS NOT NULL AND "${col}" <> '' GROUP BY "${col}" HAVING COUNT(*) > 1`);
      if (l.length) res.poste[`${table}.${col}`] = l.map((x) => x.v);
    } catch (_) { /* table ou colonne absente */ }
    try {
      const l = await admin.requete(cloudUrl, `SELECT "${col}" v, COUNT(*) n FROM "${table}" WHERE "${col}" IS NOT NULL AND "${col}"::text <> '' GROUP BY "${col}" HAVING COUNT(*) > 1`);
      if (l.length) res.cloud[`${table}.${col}`] = l.map((x) => x.v);
    } catch (_) { /* table ou colonne absente */ }
  }
  return res;
}

/** Temps processeur (secondes) consommé par le processus du poste ; null si indisponible. Coûte ~0,5 s (PowerShell). */
function tempsCpuPoste(station) {
  if (!station.proc) return null;
  try {
    const out = require('node:child_process').execFileSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', `(Get-Process -Id ${station.proc.pid}).TotalProcessorTime.TotalSeconds`], { encoding: 'utf8', timeout: 15000 });
    const v = parseFloat(out.trim().replace(',', '.'));
    return Number.isFinite(v) ? v : null;
  } catch (_) { return null; }
}

/** Latence des appels API LOCAUX du poste (ms) : la synchro lente ne doit jamais ralentir le travail local */
async function mesurerApiLocale(station, { appels = 10, chemin = '/products?limit=1' } = {}) {
  const durees = [];
  let erreurs = 0;
  for (let i = 0; i < appels; i++) {
    const t0 = Date.now();
    try { const r = await station.api('GET', chemin, undefined, { delaiMs: 30000 }); if (r.statut >= 500) erreurs++; } catch (_) { erreurs++; }
    durees.push(Date.now() - t0);
    await pause(150);
  }
  durees.sort((a, b) => a - b);
  return { min: durees[0], mediane: durees[Math.floor(durees.length / 2)], max: durees[durees.length - 1], erreurs };
}


/**
 * Surveille le journal d'envoi d'un poste PENDANT le scénario : l'état final peut masquer un « failed » passager
 * (les opérations refusées sont renvoyées au cycle suivant). Toute apparition de « failed » est enregistrée.
 * @returns {{arreter:()=>{vus:number, messages:string[], max:Object}}}
 */
function surveillerOperations(station, { pasMs = 700 } = {}) {
  const vus = new Set();
  const messages = new Map();
  const max = { pending: 0, failed: 0 };
  let actif = true;
  const boucle = (async () => {
    while (actif) {
      try {
        const st = statutsOperations(station);
        max.pending = Math.max(max.pending, st.pending || 0);
        max.failed = Math.max(max.failed, st.failed || 0);
        if (st.failed) {
          for (const r of station.lire("SELECT operation_id, table_name, error_message FROM operation_log WHERE status = 'failed'")) {
            vus.add(r.operation_id);
            messages.set(`${r.table_name}: ${r.error_message}`, true);
          }
        }
      } catch (_) { /* base occupée */ }
      await pause(pasMs);
    }
  })();
  return { async arreter() { actif = false; await boucle; return { vus: vus.size, messages: [...messages.keys()].slice(0, 8), max }; } };
}


/**
 * Variantes tolérantes aux coupures de la machine de test elle-même (les requêtes de vérification du test vont DIRECT
 * au cloud, sans passer par le banc : une coupure passagère de ce PC ne doit pas être prise pour un défaut du poste).
 */
async function avecReprise(fn, { essais = 5, pauseMs = 15000 } = {}) {
  let derniere;
  for (let i = 0; i < essais; i++) {
    try { return await fn(); } catch (e) {
      derniere = e;
      if (!/timeout|terminated|ETIMEDOUT|ENOTFOUND|ECONN|EAI_AGAIN|AggregateError|disconnected|TLS|socket|EPIPE|reset/i.test(`${e.code} ${e.name} ${e.message}`)) throw e;
      console.warn(`(reprise ${i + 1}/${essais} après coupure du banc de test : ${e.code || e.message})`);
      await pause(pauseMs);
    }
  }
  throw derniere;
}

/** Journal du poste filtré sur les lignes utiles à un diagnostic de liaison */
function lignesReseau(station, n = 400) {
  return station.journal(n).split('\n').filter((l) => /liaison|Neon|inaccessible|bloqu|ECONN|ETIMEDOUT|timeout|terminated|hybride|Replay|Erreur/i.test(l));
}

module.exports = { BancPannes, PRELOAD, surveillerOperations, avecReprise, statutsOperations, operationsRefusees, doublonsNaturels, tempsCpuPoste, mesurerApiLocale, lignesReseau, pause };
