/**
 * Conflits de synchronisation à trancher par une personne (étape 2 du centre de décisions).
 *
 * Un « conflit » : cette installation et le cloud (Neon) possèdent chacun une fiche portant la même clé
 * (même référence de produit, même nom d'utilisateur, même client pour un compte, même numéro de
 * vente...) mais sous des identifiants différents. Chaque côté refuse la fiche de l'autre : la
 * synchronisation reste bloquée tant que personne ne dit s'il s'agit de la MÊME fiche ou de DEUX fiches.
 *
 * Ce module :
 *  - repère ces conflits (envois refusés + lignes reçues non appliquées) et va chercher la fiche
 *    correspondante du cloud pour les comparer ;
 *  - propose des options chiffrées et en clair ;
 *  - applique la décision :
 *      « même fiche »      → la fiche locale prend l'identifiant du cloud (références repointées, rien
 *                            n'est supprimé) ; pour un compte, les soldes sont additionnés ou l'un est retenu ;
 *      « fiches distinctes » → la fiche locale est renommée (nouvelle référence / nouveau nom / nouveau numéro)
 *                            puis renvoyée au cloud.
 */

const { DOUBLON_PAR_TABLE } = require('./sync-detail');

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);
const fmt = (n) => Math.round(Number(n) || 0).toLocaleString('fr-FR').replace(/[  ]/g, ' ');

/**
 * Tables gérées. `colonne` = clé unique qui provoque le conflit.
 * `type` : 'fiche' (fusion possible ou renommage), 'compte' (soldes à additionner), 'document' (numéro à changer).
 */
const CONFIG = {
  produits:          { type: 'fiche',    libelle: 'Produit',            colonne: 'reference',       mot: 'référence',            affiche: ['nom', 'reference', 'prix_unitaire', 'prix_achat'], fusion: true,  suffixe: '-2' },
  utilisateurs:      { type: 'fiche',    libelle: 'Utilisateur',        colonne: 'nom_utilisateur', mot: "nom d'utilisateur",    affiche: ['nom_utilisateur', 'email'], fusion: true,  suffixe: '2' },
  boutiques:         { type: 'fiche',    libelle: 'Boutique',           colonne: 'nom',             mot: 'nom',                  affiche: ['nom', 'adresse', 'telephone'], fusion: true,  suffixe: ' (2)' },
  cash_registers:    { type: 'fiche',    libelle: 'Caisse',             colonne: 'nom',             mot: 'nom',                  affiche: ['nom', 'solde_actuel'], fusion: true,  suffixe: ' (2)' },
  stock_inventories: { type: 'fiche',    libelle: 'Inventaire',         colonne: 'nom',             mot: 'nom',                  affiche: ['nom', 'status', 'date_creation'], fusion: false, suffixe: ' (2)' },
  comptes_clients:      { type: 'compte', libelle: 'Compte client',      colonne: 'client_id',       mot: 'client',               affiche: ['solde_actuel', 'limite_credit'], proprietaire: 'clients' },
  comptes_fournisseurs: { type: 'compte', libelle: 'Compte fournisseur', colonne: 'fournisseur_id',  mot: 'fournisseur',          affiche: ['solde_actuel', 'limite_credit'], proprietaire: 'fournisseurs' },
  ventes:                      { type: 'document', libelle: 'Vente',                 colonne: 'numero_vente',    mot: 'numéro de vente',    affiche: ['numero_vente', 'montant_total', 'date_vente'], suffixe: '-2' },
  commandes_approvisionnement: { type: 'document', libelle: 'Commande',              colonne: 'numero_commande', mot: 'numéro de commande', affiche: ['numero_commande', 'montant_total'], suffixe: '-2' },
  ventes_proforma:             { type: 'document', libelle: 'Proforma',              colonne: 'numero_proforma', mot: 'numéro de proforma', affiche: ['numero_proforma', 'montant_total'], suffixe: '-2' },
  historique_recus:            { type: 'document', libelle: 'Reçu',                  colonne: 'numero_recu',     mot: 'numéro de reçu',     affiche: ['numero_recu'], suffixe: '-2' },
  financial_movements:         { type: 'document', libelle: 'Mouvement financier',   colonne: 'reference',       mot: 'référence',          affiche: ['reference', 'description', 'montant'], suffixe: '-2' },
  transferts_stock:            { type: 'document', libelle: 'Transfert de stock',    colonne: 'reference',       mot: 'référence',          affiche: ['reference'], suffixe: '-2' },
};

const MOTS_COLONNES = {
  nom: 'Nom', reference: 'Référence', prix_unitaire: 'Prix', prix_achat: "Prix d'achat", nom_utilisateur: 'Utilisateur', email: 'E-mail',
  adresse: 'Adresse', telephone: 'Téléphone', solde_actuel: 'Solde', limite_credit: 'Limite de crédit', status: 'État',
  date_creation: 'Créé le', numero_vente: 'Numéro', numero_commande: 'Numéro', numero_proforma: 'Numéro', numero_recu: 'Numéro',
  montant_total: 'Montant', date_vente: 'Date', description: 'Description', montant: 'Montant',
};

function erreur(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function formaterValeur(col, v) {
  if (v === null || v === undefined || v === '') return null;
  v = num(v);
  if (v instanceof Date) return v.toLocaleDateString('fr-FR');
  if (/^(solde|limite|prix|montant)/.test(col) && typeof v === 'number') return `${fmt(v)} FCFA`;
  if (/^date_/.test(col)) {
    const d = new Date(typeof v === 'number' ? v : String(v));
    return Number.isNaN(d.getTime()) ? String(v) : d.toLocaleDateString('fr-FR');
  }
  return String(v);
}

function resumer(config, ligne) {
  const out = [];
  for (const col of config.affiche) {
    if (!(col in ligne)) continue;
    const v = formaterValeur(col, ligne[col]);
    if (v !== null) out.push(`${MOTS_COLONNES[col] || col} : ${v}`);
  }
  return out;
}

class SyncConflictCenter {
  /**
   * @param {{prisma:Object, syncService:Object, journal?:Function}} deps
   *   journal(caseKey, optionId, details) : trace de la décision (facultatif)
   */
  constructor({ prisma, syncService, journal = null }) {
    this.prisma = prisma;
    this.sync = syncService;
    this.journal = journal;
  }

  get actif() {
    return !!(this.sync && this.sync.cloudUrl && this.sync.cloudPool);
  }

  async _local(table, colonne, valeur) {
    const r = await this.prisma.$queryRawUnsafe(`SELECT * FROM "${table}" WHERE "${colonne}" = ? LIMIT 1`, valeur);
    return r[0] || null;
  }

  async _localParId(table, id) {
    const r = await this.prisma.$queryRawUnsafe(`SELECT * FROM "${table}" WHERE id = ? LIMIT 1`, id);
    return r[0] || null;
  }

  async _cloud(client, table, colonne, valeur) {
    const r = await client.query(`SELECT * FROM "${table}" WHERE "${colonne}" = $1 LIMIT 1`, [valeur]);
    return r.rows[0] || null;
  }

  /** Valeurs de clé candidates : envois refusés pour doublon + lignes reçues non appliquées. */
  async _candidats() {
    const parTable = new Map(); // table → Set de valeurs de clé
    const ajouter = (table, valeur) => {
      if (valeur === null || valeur === undefined || valeur === '') return;
      if (!parTable.has(table)) parTable.set(table, new Set());
      parTable.get(table).add(num(valeur));
    };

    for (const [table, cfg] of Object.entries(CONFIG)) {
      try {
        const envois = await this.prisma.$queryRawUnsafe(
          `SELECT DISTINCT record_id FROM operation_log
           WHERE table_name = ? AND status = 'failed' AND operation_type <> 'DELETE' AND record_id IS NOT NULL
             AND (error_message LIKE '%duplicate key%' OR error_message LIKE '%UNIQUE constraint%')`,
          table
        );
        for (const e of envois) {
          const l = await this._localParId(table, Number(e.record_id));
          if (l) ajouter(table, l[cfg.colonne]);
        }
        const recues = await this.prisma.$queryRawUnsafe(
          `SELECT payload FROM sync_pull_retry WHERE table_name = ? AND last_error LIKE '%UNIQUE constraint%'`,
          table
        );
        for (const e of recues) {
          let d;
          try { d = typeof e.payload === 'string' ? JSON.parse(e.payload) : e.payload; } catch (_) { continue; }
          if (d) ajouter(table, d[cfg.colonne]);
        }
      } catch (_) { /* table ou suivi absent sur une ancienne installation */ }
    }
    return parTable;
  }

  async _emprunter() {
    return this.sync.cloudPool.connect();
  }

  /** @returns {{conflits:Array, total:number, cloud:'ok'|'indisponible'|'inactif'}} */
  async listConflicts() {
    if (!this.actif) return { conflits: [], total: 0, cloud: 'inactif' };
    const candidats = await this._candidats();
    if (candidats.size === 0) return { conflits: [], total: 0, cloud: 'ok' };

    let client;
    try {
      client = await this._emprunter();
    } catch (_) {
      return { conflits: [], total: 0, cloud: 'indisponible' };
    }
    const conflits = [];
    try {
      for (const [table, valeurs] of candidats) {
        const cfg = CONFIG[table];
        for (const valeur of valeurs) {
          try {
            const c = await this._construire(client, table, cfg, valeur);
            if (c) conflits.push(c);
          } catch (e) {
            if (this.sync._isConnectionError && this.sync._isConnectionError(e)) throw e;
          }
        }
      }
    } catch (_) {
      return { conflits, total: conflits.length, cloud: 'indisponible' };
    } finally {
      client.release();
    }
    return { conflits, total: conflits.length, cloud: 'ok' };
  }

  /** Construit le cas (ou null si les deux fiches ne se contredisent pas). */
  async _construire(client, table, cfg, valeur) {
    const local = await this._local(table, cfg.colonne, valeur);
    if (!local) return null;
    const cloud = await this._cloud(client, table, cfg.colonne, valeur);
    if (!cloud) return null;
    const localId = Number(local.id);
    const cloudId = Number(cloud.id);
    if (localId === cloudId) return null; // même fiche des deux côtés : le refus avait une autre cause

    const modele = DOUBLON_PAR_TABLE[table] || {};
    const base = {
      key: `sync:${table}:${localId}`,
      table,
      libelle: cfg.libelle,
      type: cfg.type,
      cle: { colonne: cfg.colonne, mot: cfg.mot, valeur: String(num(valeur)) },
      titre: modele.titre || 'Deux fiches pour la même clé',
      explication: modele.explication || '',
    };

    if (cfg.type === 'compte') {
      const proprio = await this._proprietaire(cfg, local);
      const soldeLocal = Number(num(local.solde_actuel)) || 0;
      const soldeCloud = Number(num(cloud.solde_actuel)) || 0;
      let nbEcritures = 0;
      try {
        const r = await this.prisma.$queryRawUnsafe(`SELECT COUNT(*) AS n FROM transactions_comptes WHERE compte_id = ?`, localId);
        nbEcritures = Number(num(r[0].n)) || 0;
      } catch (_) { /* table absente */ }
      const somme = soldeLocal + soldeCloud;
      return {
        ...base,
        titre: proprio ? `${cfg.libelle} de ${proprio} en double` : base.titre,
        local: { id: localId, resume: [`Solde : ${fmt(soldeLocal)} FCFA`, `${nbEcritures} écriture(s) sur ce poste`] },
        cloud: { id: cloudId, resume: [`Solde : ${fmt(soldeCloud)} FCFA`] },
        options: [
          {
            id: 'additionner', recommandee: true,
            label: 'Additionner les deux soldes',
            description: 'Les deux comptes ont enregistré des opérations différentes : on les cumule.',
            consequence: `Solde final : ${fmt(somme)} FCFA (${fmt(soldeCloud)} du cloud + ${fmt(soldeLocal)} de ce poste). Les écritures de ce poste sont rattachées au compte du cloud.`,
          },
          {
            id: 'garder_cloud',
            label: 'Garder le solde du cloud',
            description: "À choisir si le solde de ce poste n'est qu'une copie ou une erreur.",
            consequence: `Solde final : ${fmt(soldeCloud)} FCFA. Le solde de ce poste (${fmt(soldeLocal)} FCFA) est abandonné ; ses écritures restent consultables.`,
          },
          {
            id: 'garder_local',
            label: 'Garder le solde de ce poste',
            description: "À choisir si le solde du cloud n'est qu'une copie ou une erreur.",
            consequence: `Solde final : ${fmt(soldeLocal)} FCFA, renvoyé au cloud à la place de ${fmt(soldeCloud)} FCFA.`,
          },
        ],
      };
    }

    const suggestion = await this._suggerer(client, table, cfg, valeur);
    const renommer = {
      id: 'renommer',
      label: cfg.type === 'document' ? `Ce sont deux ${cfg.libelle.toLowerCase()}s différents : changer le ${cfg.mot} de celui de ce poste`
        : `Ce sont deux fiches différentes : renommer celle de ce poste`,
      description: `Le ${cfg.mot} de ce poste devient « ${suggestion} » (modifiable) puis la fiche est envoyée au cloud.`,
      consequence: `Les deux fiches coexistent. Seul le ${cfg.mot} de la fiche de ce poste change${cfg.type === 'document' ? ' (un ancien exemplaire imprimé portera l\'ancien numéro)' : ''}.`,
      valeurSuggeree: suggestion,
      recommandee: cfg.type === 'document',
    };
    const options = [];
    if (cfg.fusion) {
      options.push({
        id: 'fusionner',
        label: "C'est la même fiche : garder celle du cloud",
        description: `La fiche de ce poste prend l'identifiant et les valeurs de celle du cloud.`,
        consequence: `Tout ce qui se rattachait ici à la fiche n° ${localId} (ventes, stocks, historique...) est rattaché à la fiche du cloud n° ${cloudId}. Les valeurs du cloud remplacent celles de ce poste. Rien n'est supprimé.`,
      });
    }
    options.push(renommer);

    return {
      ...base,
      local: { id: localId, resume: resumer(cfg, local) },
      cloud: { id: cloudId, resume: resumer(cfg, cloud) },
      options,
    };
  }

  async _proprietaire(cfg, compte) {
    try {
      const col = cfg.colonne;
      const r = await this.prisma.$queryRawUnsafe(`SELECT * FROM "${cfg.proprietaire}" WHERE id = ? LIMIT 1`, num(compte[col]));
      if (!r[0]) return null;
      return [r[0].nom, r[0].prenom].filter(Boolean).join(' ') || null;
    } catch (_) { return null; }
  }

  async _existe(client, table, colonne, valeur, sauf = null) {
    const l = await this._local(table, colonne, valeur);
    if (l && Number(l.id) !== sauf) return true;
    return !!(await this._cloud(client, table, colonne, valeur));
  }

  /** Première valeur libre des deux côtés : « REF-2 », « REF-3 »... */
  async _suggerer(client, table, cfg, valeur) {
    const base = String(valeur);
    for (let i = 2; i < 50; i++) {
      const candidat = cfg.suffixe.includes('2') ? base + cfg.suffixe.replace('2', String(i)) : `${base}-${i}`;
      if (!(await this._existe(client, table, cfg.colonne, candidat))) return candidat;
    }
    return `${base}-${Date.now() % 100000}`;
  }

  // ── Application ────────────────────────────────────────────────────────────

  /**
   * @param {{caseKey:string, optionId:string, valeur?:string, userId?:number}} p
   */
  async apply({ caseKey, optionId, valeur = null, userId = null }) {
    const m = /^sync:([a-z_]+):(\d+)$/.exec(String(caseKey || ''));
    if (!m || !CONFIG[m[1]]) throw erreur(404, 'Conflit introuvable');
    if (!this.actif) throw erreur(409, "La synchronisation n'est pas configurée sur ce poste.");
    const [, table, idTexte] = m;
    const cfg = CONFIG[table];
    const localId = Number(idTexte);

    const local = await this._localParId(table, localId);
    if (!local) throw erreur(409, "Cette fiche n'existe plus sur ce poste : le conflit a été résolu entre-temps.");

    let client;
    try {
      client = await this._emprunter();
    } catch (_) {
      throw erreur(503, 'Neon est inaccessible : vérifiez la connexion internet puis réessayez.');
    }
    try {
      const cloud = await this._cloud(client, table, cfg.colonne, local[cfg.colonne]);
      if (!cloud || Number(cloud.id) === localId) {
        throw erreur(409, "Ce conflit n'existe plus (le cloud n'a plus de fiche concurrente). Relancez la synchronisation.");
      }

      let detail;
      if (cfg.type === 'compte') {
        if (!['additionner', 'garder_cloud', 'garder_local'].includes(optionId)) throw erreur(400, 'Option inconnue');
        detail = await this._fusionnerCompte(table, local, cloud, optionId);
      } else if (optionId === 'fusionner') {
        if (!cfg.fusion) throw erreur(400, 'Option inconnue');
        detail = await this._aligner(table, local, cloud);
      } else if (optionId === 'renommer') {
        detail = await this._renommer(client, table, cfg, local, valeur);
      } else {
        throw erreur(400, 'Option inconnue');
      }

      if (this.journal) {
        try { await this.journal(caseKey, optionId, { ...detail, userId }); } catch (_) { /* trace non bloquante */ }
      }
      this._relancer();
      return { statut: 'applique', ...detail };
    } finally {
      client.release();
    }
  }

  _relancer() {
    try {
      if (this.sync.isCloudAvailable && !this.sync.isSyncing && typeof this.sync._syncCycle === 'function') {
        setImmediate(() => this.sync._syncCycle());
      }
    } catch (_) { /* la prochaine synchronisation planifiée s'en chargera */ }
  }

  /** La fiche locale prend l'identifiant et les valeurs du cloud ; rien n'est supprimé. */
  async _aligner(table, local, cloud) {
    const ancienId = Number(local.id);
    const nouveauId = Number(cloud.id);
    const occupe = await this._localParId(table, nouveauId);
    if (occupe) throw erreur(409, `L'identifiant ${nouveauId} du cloud est déjà utilisé par une autre fiche de ce poste : fusion refusée.`);

    await this.prisma.$executeRawUnsafe(`UPDATE "${table}" SET id = ? WHERE id = ?`, nouveauId, ancienId);
    await this.sync._repointerReferences(table, ancienId, nouveauId);
    await this.prisma.$executeRawUnsafe(
      `UPDATE operation_log SET status = 'cancelled', error_message = ?
       WHERE table_name = ? AND record_id = ? AND status IN ('pending', 'failed')`,
      `Fiche fusionnée avec celle du cloud (identifiant ${ancienId} → ${nouveauId})`, table, ancienId
    );
    await this.sync._mergeRemoteRow(table, cloud);
    await this.prisma.$executeRawUnsafe(
      `DELETE FROM sync_pull_retry WHERE table_name = ? AND record_id IN (?, ?)`, table, String(nouveauId), String(ancienId)
    );
    await this._rafraichirEnfants(table);
    return { ancienId, nouveauId };
  }

  async _fusionnerCompte(table, local, cloud, optionId) {
    const soldeLocal = Number(num(local.solde_actuel)) || 0;
    const soldeCloud = Number(num(cloud.solde_actuel)) || 0;
    const detail = await this._aligner(table, local, cloud);
    const final = optionId === 'additionner' ? soldeLocal + soldeCloud : (optionId === 'garder_local' ? soldeLocal : soldeCloud);

    await this.prisma.$executeRawUnsafe(`UPDATE "${table}" SET solde_actuel = ? WHERE id = ?`, final, detail.nouveauId);
    if (final !== soldeCloud) {
      // le cloud doit connaître le nouveau solde
      const ligne = await this._localParId(table, detail.nouveauId);
      const donnees = Object.fromEntries(Object.entries(ligne).map(([k, v]) => [k, num(v)]));
      await this.sync.logOperation(table, 'UPDATE', donnees);
    }
    return { ...detail, soldeLocal, soldeCloud, soldeFinal: final };
  }

  async _renommer(client, table, cfg, local, valeurSaisie) {
    const ancienne = String(num(local[cfg.colonne]));
    const nouvelle = String(valeurSaisie === null || valeurSaisie === undefined || String(valeurSaisie).trim() === ''
      ? await this._suggerer(client, table, cfg, ancienne)
      : valeurSaisie).trim();
    if (nouvelle === ancienne) throw erreur(400, `Le nouveau ${cfg.mot} doit être différent de l'actuel.`);
    if (await this._existe(client, table, cfg.colonne, nouvelle, Number(local.id))) {
      throw erreur(409, `Le ${cfg.mot} « ${nouvelle} » existe déjà : choisissez-en un autre.`);
    }
    const id = Number(local.id);
    await this.prisma.$executeRawUnsafe(`UPDATE "${table}" SET "${cfg.colonne}" = ? WHERE id = ?`, nouvelle, id);
    await this.prisma.$executeRawUnsafe(
      `UPDATE operation_log SET status = 'cancelled', error_message = ?
       WHERE table_name = ? AND record_id = ? AND status IN ('pending', 'failed')`,
      `Ancienne valeur « ${ancienne} » remplacée par « ${nouvelle} » après décision`, table, id
    );
    const ligne = await this._localParId(table, id);
    const donnees = Object.fromEntries(Object.entries(ligne).map(([k, v]) => [k, num(v)]));
    await this.sync.logOperation(table, 'INSERT', donnees);
    return { id, ancienne, nouvelle };
  }

  /**
   * Après un changement d'identifiant, les envois en attente des tables rattachées (écritures de compte,
   * lignes de vente...) portent encore l'ancien : on les reconstruit depuis l'état réel de la base.
   */
  async _rafraichirEnfants(cible) {
    const tables = await this.prisma.$queryRawUnsafe(`SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'`);
    const enfants = [cible];
    for (const { name } of tables) {
      let fks;
      try { fks = await this.prisma.$queryRawUnsafe(`PRAGMA foreign_key_list("${name}")`); } catch (_) { continue; }
      if (fks.some((fk) => fk.table === cible)) enfants.push(name);
    }
    for (const t of enfants) {
      let ops;
      try {
        ops = await this.prisma.$queryRawUnsafe(
          `SELECT operation_id, record_id FROM operation_log WHERE table_name = ? AND status IN ('pending', 'failed') AND operation_type <> 'DELETE'`, t
        );
      } catch (_) { continue; }
      for (const op of ops) {
        const ligne = op.record_id === null ? null : await this._localParId(t, Number(op.record_id));
        if (!ligne) continue;
        const donnees = JSON.stringify(Object.fromEntries(Object.entries(ligne).map(([k, v]) => [k, num(v)])));
        await this.prisma.$executeRawUnsafe(
          `UPDATE operation_log SET data = ?, status = 'pending', error_message = NULL WHERE operation_id = ?`, donnees, op.operation_id
        );
      }
    }
  }
}

module.exports = { SyncConflictCenter, CONFIG };
