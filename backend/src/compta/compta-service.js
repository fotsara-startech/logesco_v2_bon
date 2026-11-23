/**
 * Service comptable (phase 1 : socle) — voir docs/CONCEPTION_COMPTABILITE_OHADA.md
 *
 * Principes appliqués ici :
 *  - partie double stricte : Σ débit = Σ crédit, montants entiers (FCFA) ;
 *  - une écriture validée ne se modifie jamais : on la contre-passe ;
 *  - un exercice / une période clôturé(e) n'accepte plus d'écriture ;
 *  - dates comptables = jours UTC (« AAAA-MM-JJ » → minuit UTC), partout, pour
 *    éviter qu'un décalage horaire fasse glisser une pièce sur le mois voisin ;
 *  - numéro de pièce attribué à la validation, avec le suffixe de poste (-P2…)
 *    des autres documents pour ne jamais produire deux fois le même numéro.
 */
const installation = require('../utils/installation');

const STATUTS_COMPTABILISES = ['validee', 'contrepassee'];
const ORIGINES = ['auto', 'manuelle', 'ouverture', 'cloture', 'contrepassation'];

class ComptaError extends Error {
  constructor(message, status = 400, code = 'COMPTA_ERREUR') {
    super(message);
    this.name = 'ComptaError';
    this.status = status;
    this.code = code;
  }
}

/** Minuit UTC du jour d'une date (Date, ISO ou « AAAA-MM-JJ ») ; lève une erreur si illisible */
function jourUtc(valeur, nom = 'date') {
  const d = valeur instanceof Date ? valeur : new Date(valeur);
  if (valeur === undefined || valeur === null || Number.isNaN(d.getTime())) {
    throw new ComptaError(`${nom} invalide`);
  }
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function rangMois(debut, date) {
  return (date.getUTCFullYear() * 12 + date.getUTCMonth()) - (debut.getUTCFullYear() * 12 + debut.getUTCMonth()) + 1;
}

/** Numéro de compte auxiliaire affiché pour un tiers : « 411 » + code du tiers sur N chiffres */
function numeroAuxiliaire(numeroCompte, tiersId, longueur = 6) {
  if (!tiersId) return numeroCompte;
  return `${numeroCompte}${String(tiersId).padStart(longueur, '0')}`;
}

class ComptaService {
  /**
   * @param {object} prisma client Prisma
   * @param {object|null} syncService service de synchronisation (enqueue), absent en test
   */
  constructor(prisma, syncService = null) {
    this.prisma = prisma;
    this.syncService = syncService;
  }

  /**
   * Transaction interactive avec un délai large : par défaut Prisma coupe à 5 s, ce qui ne suffit pas quand la base
   * est distante (chaque requête coûte alors plusieurs centaines de millisecondes).
   */
  _transaction(fn) {
    return this.prisma.$transaction(fn, { maxWait: 20000, timeout: 60000 });
  }

  async _enqueue(table, operation, row) {
    if (!this.syncService || !row) return;
    try {
      await this.syncService.enqueue(table, operation, row);
    } catch (e) {
      // La comptabilité locale reste juste ; la synchro rattrapera (voir sync-heal)
      console.warn(`⚠️  [Compta] mise en file de synchro impossible (${table} ${operation}) : ${e.message}`);
    }
  }

  /**
   * Journal d'audit : trace une action sensible. Ne bloque jamais l'opération tracée (une erreur est seulement signalée).
   * @param {string} action ex. « ecriture.validee »
   * @param {{ utilisateurId?: number, entiteType?: string, entiteId?: number, details?: object }} p
   */
  async tracer(action, { utilisateurId, entiteType, entiteId, details } = {}) {
    try {
      const ligne = await this.prisma.comptaAudit.create({
        data: {
          action, utilisateurId: utilisateurId ? Number(utilisateurId) : null, entiteType: entiteType || null,
          entiteId: entiteId ? Number(entiteId) : null, details: details ? JSON.stringify(details) : null,
        },
      });
      await this._enqueue('compta_audit', 'INSERT', ligne);
    } catch (e) {
      console.warn(`⚠️  [Compta] audit non enregistré (${action}) : ${e.message}`);
    }
  }

  async listerAudit({ action, entiteType, dateDebut, dateFin, page = 1, limit = 100 } = {}) {
    const where = {};
    if (action) where.action = { startsWith: String(action) };
    if (entiteType) where.entiteType = String(entiteType);
    if (dateDebut || dateFin) {
      where.dateAction = {};
      if (dateDebut) where.dateAction.gte = jourUtc(dateDebut, 'Date de début');
      if (dateFin) where.dateAction.lt = new Date(jourUtc(dateFin, 'Date de fin').getTime() + 24 * 3600 * 1000);
    }
    page = Math.max(1, Number(page) || 1);
    limit = Math.min(500, Math.max(1, Number(limit) || 100));
    const [total, lignes] = await Promise.all([
      this.prisma.comptaAudit.count({ where }),
      this.prisma.comptaAudit.findMany({ where, orderBy: { id: 'desc' }, skip: (page - 1) * limit, take: limit }),
    ]);
    const ids = [...new Set(lignes.map((l) => l.utilisateurId).filter(Boolean))];
    const utilisateurs = ids.length ? await this.prisma.utilisateur.findMany({ where: { id: { in: ids } }, select: { id: true, nomUtilisateur: true } }) : [];
    const noms = new Map(utilisateurs.map((u) => [u.id, u.nomUtilisateur]));
    return {
      total, page, limit,
      lignes: lignes.map((l) => ({ ...l, utilisateur: l.utilisateurId ? (noms.get(l.utilisateurId) || `#${l.utilisateurId}`) : null, details: l.details ? JSON.parse(l.details) : null })),
    };
  }

  async _enqueueEcriture(operation, ecriture) {
    if (!ecriture) return;
    const { lignes, ...entete } = ecriture;
    await this._enqueue('compta_ecritures', operation, entete);
    for (const l of lignes || []) await this._enqueue('compta_lignes', operation, l);
  }

  // ───────────────────────────── Paramètres ─────────────────────────────

  async getParametres() {
    let p = await this.prisma.comptaParametres.findUnique({ where: { id: 1 } });
    if (!p) p = await this.prisma.comptaParametres.create({ data: { id: 1 } });
    return p;
  }

  async updateParametres(patch = {}, { utilisateurId } = {}) {
    const data = {};
    if (patch.regime !== undefined) {
      if (!['normal', 'smt'].includes(patch.regime)) throw new ComptaError('Régime invalide (normal ou smt)');
      data.regime = patch.regime;
    }
    if (patch.modeAffichage !== undefined) {
      if (!['simple', 'expert'].includes(patch.modeAffichage)) throw new ComptaError('Mode invalide (simple ou expert)');
      data.modeAffichage = patch.modeAffichage;
    }
    if (patch.tauxTvaDefaut !== undefined) {
      const t = Number(patch.tauxTvaDefaut);
      if (!Number.isFinite(t) || t < 0 || t > 100) throw new ComptaError('Taux de TVA invalide');
      data.tauxTvaDefaut = t;
    }
    if (patch.assujettiTva !== undefined) data.assujettiTva = Boolean(patch.assujettiTva);
    if (patch.longueurComptesTiers !== undefined) {
      const n = Number(patch.longueurComptesTiers);
      if (!Number.isInteger(n) || n < 1 || n > 10) throw new ComptaError('Longueur des comptes de tiers invalide (1 à 10)');
      data.longueurComptesTiers = n;
    }
    await this.getParametres();
    const p = await this.prisma.comptaParametres.update({ where: { id: 1 }, data });
    await this._enqueue('compta_parametres', 'UPDATE', p);
    await this.tracer('parametres.modifies', { utilisateurId, entiteType: 'parametres', entiteId: 1, details: data });
    return p;
  }

  // ───────────────────────────── Plan comptable ─────────────────────────────

  async listerComptes({ q, classe, actif } = {}) {
    const where = {};
    if (classe) where.classe = Number(classe);
    if (actif !== undefined) where.actif = actif === true || actif === 'true';
    if (q) where.OR = [{ numero: { startsWith: String(q) } }, { libelle: { contains: String(q) } }];
    return this.prisma.comptaCompte.findMany({ where, orderBy: { numero: 'asc' } });
  }

  async creerCompte({ numero, libelle, nature, sens, lettrable = false } = {}, { utilisateurId } = {}) {
    numero = String(numero || '').trim();
    libelle = String(libelle || '').trim();
    if (!/^[1-8]\d{1,7}$/.test(numero)) throw new ComptaError('Numéro de compte invalide : 2 à 8 chiffres, classe 1 à 8');
    if (!libelle) throw new ComptaError('Le libellé est obligatoire');
    if (await this.prisma.comptaCompte.findUnique({ where: { numero } })) {
      throw new ComptaError(`Le compte ${numero} existe déjà`, 409, 'COMPTE_EXISTANT');
    }
    // Parent = compte existant le plus proche par préfixe
    let parent = null;
    for (let l = numero.length - 1; l >= 2 && !parent; l--) {
      parent = await this.prisma.comptaCompte.findUnique({ where: { numero: numero.slice(0, l) } });
    }
    const classeNum = Number(numero[0]);
    const natureDefaut = parent?.nature || { 1: 'passif', 2: 'actif', 3: 'actif', 4: 'tiers', 5: 'tresorerie', 6: 'charge', 7: 'produit', 8: 'charge' }[classeNum];
    const compte = await this.prisma.comptaCompte.create({
      data: {
        numero,
        libelle,
        classe: classeNum,
        nature: nature || natureDefaut,
        sens: sens || parent?.sens || null,
        parentNumero: parent?.numero || null,
        estCollectif: false,
        lettrable: Boolean(lettrable),
        systeme: false,
        actif: true,
      },
    });
    await this._enqueue('compta_comptes', 'INSERT', compte);
    await this.tracer('compte.cree', { utilisateurId, entiteType: 'compte', entiteId: compte.id, details: { numero: compte.numero, libelle: compte.libelle } });
    return compte;
  }

  async modifierCompte(id, { libelle, actif, lettrable } = {}) {
    const existant = await this.prisma.comptaCompte.findUnique({ where: { id: Number(id) } });
    if (!existant) throw new ComptaError('Compte introuvable', 404);
    const data = {};
    if (libelle !== undefined) {
      if (!String(libelle).trim()) throw new ComptaError('Le libellé est obligatoire');
      data.libelle = String(libelle).trim();
    }
    if (actif !== undefined) data.actif = Boolean(actif);
    if (lettrable !== undefined) data.lettrable = Boolean(lettrable);
    const compte = await this.prisma.comptaCompte.update({ where: { id: existant.id }, data });
    await this._enqueue('compta_comptes', 'UPDATE', compte);
    return compte;
  }

  // ───────────────────────────── Exercices et périodes ─────────────────────────────

  async listerExercices() {
    return this.prisma.comptaExercice.findMany({ orderBy: { dateDebut: 'desc' }, include: { periodes: { orderBy: { mois: 'asc' } } } });
  }

  async creerExercice({ libelle, dateDebut, dateFin } = {}) {
    const debut = jourUtc(dateDebut, 'Date de début');
    const fin = jourUtc(dateFin, 'Date de fin');
    if (fin <= debut) throw new ComptaError('La date de fin doit suivre la date de début');
    const nbMois = rangMois(debut, fin);
    if (nbMois > 24) throw new ComptaError('Un exercice ne peut pas dépasser 24 mois');

    const chevauche = await this.prisma.comptaExercice.findFirst({
      where: { dateDebut: { lte: fin }, dateFin: { gte: debut } },
    });
    if (chevauche) throw new ComptaError(`Cet exercice chevauche « ${chevauche.libelle} »`, 409, 'EXERCICE_CHEVAUCHE');

    const exercice = await this.prisma.comptaExercice.create({
      data: {
        libelle: String(libelle || '').trim() || `Exercice ${debut.getUTCFullYear()}`,
        dateDebut: debut,
        dateFin: fin,
        periodes: { create: Array.from({ length: nbMois }, (_, i) => ({ mois: i + 1 })) },
      },
      include: { periodes: true },
    });
    await this._enqueue('compta_exercices', 'INSERT', { ...exercice, periodes: undefined });
    for (const p of exercice.periodes) await this._enqueue('compta_periodes', 'INSERT', p);
    return exercice;
  }

  async _exerciceEtPeriode(db, date) {
    const exercice = await db.comptaExercice.findFirst({ where: { dateDebut: { lte: date }, dateFin: { gte: date } } });
    if (!exercice) {
      throw new ComptaError(`Aucun exercice comptable ne couvre le ${date.toISOString().slice(0, 10)}`, 400, 'AUCUN_EXERCICE');
    }
    const rang = rangMois(exercice.dateDebut, date);
    const periode = await db.comptaPeriode.findUnique({ where: { exerciceId_mois: { exerciceId: exercice.id, mois: rang } } });
    return { exercice, periode };
  }

  _verifierOuverts({ exercice, periode }) {
    if (exercice.statut !== 'ouvert') {
      throw new ComptaError(`L'exercice « ${exercice.libelle} » est clôturé`, 409, 'EXERCICE_CLOTURE');
    }
    if (periode && periode.statut !== 'ouverte') {
      throw new ComptaError('La période comptable de cette date est verrouillée', 409, 'PERIODE_VERROUILLEE');
    }
  }

  async changerStatutPeriode(exerciceId, mois, statut, { utilisateurId } = {}) {
    if (!['ouverte', 'verrouillee'].includes(statut)) throw new ComptaError('Statut de période invalide');
    const periode = await this.prisma.comptaPeriode.findUnique({ where: { exerciceId_mois: { exerciceId: Number(exerciceId), mois: Number(mois) } } });
    if (!periode) throw new ComptaError('Période introuvable', 404);
    const exercice = await this.prisma.comptaExercice.findUnique({ where: { id: periode.exerciceId } });
    if (statut === 'ouverte' && exercice.statut !== 'ouvert') {
      throw new ComptaError('Impossible de rouvrir une période d\'un exercice clôturé', 409, 'EXERCICE_CLOTURE');
    }
    const maj = await this.prisma.comptaPeriode.update({ where: { id: periode.id }, data: { statut } });
    await this._enqueue('compta_periodes', 'UPDATE', maj);
    await this.tracer(statut === 'verrouillee' ? 'periode.verrouillee' : 'periode.rouverte', { utilisateurId, entiteType: 'periode', entiteId: maj.id, details: { exerciceId: Number(exerciceId), mois: Number(mois) } });
    return maj;
  }

  // ───────────────────────────── Écritures ─────────────────────────────

  /** Contrôles communs : retourne les lignes normalisées ou lève une ComptaError */
  async _preparerLignes(db, lignes, boutiqueIdEntete) {
    if (!Array.isArray(lignes) || lignes.length < 2) {
      throw new ComptaError('Une écriture comporte au moins deux lignes');
    }
    let totalDebit = 0;
    let totalCredit = 0;
    const resultat = [];
    const idsDemandes = [...new Set(lignes.map((l) => l.compteId).filter(Boolean).map(Number))];
    const numerosDemandes = [...new Set(lignes.map((l) => l.compteNumero).filter(Boolean).map(String))];
    const trouves = await db.comptaCompte.findMany({ where: { OR: [{ id: { in: idsDemandes } }, { numero: { in: numerosDemandes } }] } });
    const parId = new Map(trouves.map((c) => [c.id, c]));
    const parNumero = new Map(trouves.map((c) => [c.numero, c]));
    for (const [i, l] of lignes.entries()) {
      const debit = l.debit === undefined || l.debit === null || l.debit === '' ? 0 : Number(l.debit);
      const credit = l.credit === undefined || l.credit === null || l.credit === '' ? 0 : Number(l.credit);
      const n = i + 1;
      if (!Number.isInteger(debit) || !Number.isInteger(credit)) throw new ComptaError(`Ligne ${n} : les montants doivent être des entiers (FCFA)`);
      if (debit < 0 || credit < 0) throw new ComptaError(`Ligne ${n} : montant négatif interdit`);
      if ((debit > 0) === (credit > 0)) throw new ComptaError(`Ligne ${n} : renseigner soit un débit, soit un crédit`);

      let compte = null;
      if (l.compteId) compte = parId.get(Number(l.compteId)) || null;
      else if (l.compteNumero) compte = parNumero.get(String(l.compteNumero)) || null;
      if (!compte) throw new ComptaError(`Ligne ${n} : compte introuvable`);
      if (!compte.actif) throw new ComptaError(`Ligne ${n} : le compte ${compte.numero} est désactivé`);

      if (l.tiersType && !['client', 'fournisseur'].includes(l.tiersType)) throw new ComptaError(`Ligne ${n} : type de tiers invalide`);
      if (l.tiersType && !l.tiersId) throw new ComptaError(`Ligne ${n} : tiers non précisé`);

      totalDebit += debit;
      totalCredit += credit;
      resultat.push({
        compteId: compte.id,
        tiersType: l.tiersType || null,
        tiersId: l.tiersId ? Number(l.tiersId) : null,
        libelle: l.libelle ? String(l.libelle) : null,
        debit,
        credit,
        lettrage: null,
        boutiqueId: l.boutiqueId ? Number(l.boutiqueId) : boutiqueIdEntete || null,
      });
    }
    if (totalDebit !== totalCredit) {
      throw new ComptaError(`Écriture déséquilibrée : débit ${totalDebit} ≠ crédit ${totalCredit}`, 400, 'DESEQUILIBRE');
    }
    if (totalDebit === 0) throw new ComptaError('Écriture sans montant');
    return resultat;
  }

  async _journal(db, { journalId, journalCode }) {
    const journal = journalId
      ? await db.comptaJournal.findUnique({ where: { id: Number(journalId) } })
      : await db.comptaJournal.findUnique({ where: { code: String(journalCode || '') } });
    if (!journal) throw new ComptaError('Journal introuvable', 404);
    return journal;
  }

  /**
   * Crée une écriture (brouillon par défaut).
   * @param {object} p { journalId|journalCode, dateEcriture, libelle, lignes[], boutiqueId, utilisateurId,
   *                     origine, source: {type,id,role}, valider }
   */
  async creerEcriture(p = {}) {
    const origine = p.origine || 'manuelle';
    if (!ORIGINES.includes(origine)) throw new ComptaError('Origine invalide');
    const libelle = String(p.libelle || '').trim();
    if (!libelle) throw new ComptaError('Le libellé de l\'écriture est obligatoire');
    const date = jourUtc(p.dateEcriture, 'Date d\'écriture');

    const creee = await this._transaction(async (tx) => {
      const journal = await this._journal(tx, p);
      if (journal.type === 'a_nouveaux' && origine === 'manuelle') {
        throw new ComptaError('Le journal des à-nouveaux est réservé à l\'ouverture et à la clôture');
      }
      const contexte = await this._exerciceEtPeriode(tx, date);
      this._verifierOuverts(contexte);
      const lignes = await this._preparerLignes(tx, p.lignes, p.boutiqueId);

      const source = p.source || {};
      if (source.type && source.id) {
        const deja = await tx.comptaEcriture.findFirst({
          where: { sourceType: source.type, sourceId: Number(source.id), sourceRole: source.role || null },
          include: { lignes: true },
        });
        if (deja) return { ecriture: deja, existante: true };
      }

      const ecriture = await tx.comptaEcriture.create({
        data: {
          exerciceId: contexte.exercice.id,
          journalId: journal.id,
          dateEcriture: date,
          libelle,
          statut: 'brouillon',
          origine,
          sourceType: source.type || null,
          sourceId: source.id ? Number(source.id) : null,
          sourceRole: source.role || null,
          contrepasseId: p.contrepasseId || null,
          boutiqueId: p.boutiqueId ? Number(p.boutiqueId) : null,
          utilisateurId: p.utilisateurId ? Number(p.utilisateurId) : null,
          lignes: { create: lignes },
        },
        include: { lignes: true },
      });
      return { ecriture, existante: false, journal, contexte };
    });

    if (creee.existante) return creee.ecriture; // idempotence : la pièce de cette source existe déjà
    await this._enqueueEcriture('INSERT', creee.ecriture);
    return p.valider ? this.validerEcriture(creee.ecriture.id, { utilisateurId: p.utilisateurId }) : creee.ecriture;
  }

  async modifierBrouillon(id, p = {}) {
    const maj = await this._transaction(async (tx) => {
      const existante = await tx.comptaEcriture.findUnique({ where: { id: Number(id) }, include: { lignes: true } });
      if (!existante) throw new ComptaError('Écriture introuvable', 404);
      if (existante.statut !== 'brouillon') throw new ComptaError('Seul un brouillon peut être modifié : contre-passez la pièce validée', 409, 'ECRITURE_VALIDEE');
      if (existante.origine !== 'manuelle') throw new ComptaError('Une écriture automatique ne se modifie pas', 409);

      const data = {};
      const date = p.dateEcriture !== undefined ? jourUtc(p.dateEcriture, 'Date d\'écriture') : existante.dateEcriture;
      if (p.dateEcriture !== undefined) {
        const contexte = await this._exerciceEtPeriode(tx, date);
        this._verifierOuverts(contexte);
        data.dateEcriture = date;
        data.exerciceId = contexte.exercice.id;
      }
      if (p.libelle !== undefined) {
        if (!String(p.libelle).trim()) throw new ComptaError('Le libellé de l\'écriture est obligatoire');
        data.libelle = String(p.libelle).trim();
      }
      if (p.journalId || p.journalCode) {
        const journal = await this._journal(tx, p);
        if (journal.type === 'a_nouveaux') throw new ComptaError('Le journal des à-nouveaux est réservé');
        data.journalId = journal.id;
      }
      let nouvelles = null;
      if (p.lignes !== undefined) nouvelles = await this._preparerLignes(tx, p.lignes, existante.boutiqueId);

      const anciennes = existante.lignes;
      if (nouvelles) await tx.comptaLigne.deleteMany({ where: { ecritureId: existante.id } });
      const ecriture = await tx.comptaEcriture.update({
        where: { id: existante.id },
        data: { ...data, ...(nouvelles ? { lignes: { create: nouvelles } } : {}) },
        include: { lignes: true },
      });
      return { ecriture, anciennes: nouvelles ? anciennes : [] };
    });

    for (const l of maj.anciennes) await this._enqueue('compta_lignes', 'DELETE', { id: l.id });
    await this._enqueue('compta_ecritures', 'UPDATE', { ...maj.ecriture, lignes: undefined });
    if (maj.anciennes.length) for (const l of maj.ecriture.lignes) await this._enqueue('compta_lignes', 'INSERT', l);
    return maj.ecriture;
  }

  async supprimerBrouillon(id, { utilisateurId } = {}) {
    const existante = await this.prisma.comptaEcriture.findUnique({ where: { id: Number(id) }, include: { lignes: true } });
    if (!existante) throw new ComptaError('Écriture introuvable', 404);
    if (existante.statut !== 'brouillon') throw new ComptaError('Une écriture validée ne se supprime pas : contre-passez-la', 409, 'ECRITURE_VALIDEE');
    await this.prisma.comptaEcriture.delete({ where: { id: existante.id } });
    for (const l of existante.lignes) await this._enqueue('compta_lignes', 'DELETE', { id: l.id });
    await this._enqueue('compta_ecritures', 'DELETE', { id: existante.id });
    await this.tracer('ecriture.brouillon_supprime', { utilisateurId, entiteType: 'ecriture', entiteId: existante.id, details: { libelle: existante.libelle } });
    return { id: existante.id };
  }

  /** Prochain numéro de pièce pour ce journal et cet exercice : « VT-2027-000012 » (+ « -P2 » hors poste 1) */
  async _prochainNumero(db, journal, exercice) {
    const prefixe = `${journal.code}-${exercice.dateDebut.getUTCFullYear()}-`;
    const suffixe = installation.documentSuffix();
    const motif = new RegExp(`^${prefixe}(\\d{6})(-P\\d+)?$`);
    const lire = (liste) => {
      let max = 0;
      for (const { numeroPiece } of liste) {
        const m = motif.exec(numeroPiece || '');
        if (m && (m[2] || '') === suffixe) max = Math.max(max, Number(m[1]));
      }
      return max;
    };
    const recents = await db.comptaEcriture.findMany({
      where: { numeroPiece: { startsWith: prefixe } },
      select: { numeroPiece: true },
      orderBy: { numeroPiece: 'desc' },
      take: 200,
    });
    let max = lire(recents);
    if (max === 0 && recents.length === 200) {
      max = lire(await db.comptaEcriture.findMany({ where: { numeroPiece: { startsWith: prefixe } }, select: { numeroPiece: true } }));
    }
    return `${prefixe}${String(max + 1).padStart(6, '0')}${suffixe}`;
  }

  async validerEcriture(id, { utilisateurId } = {}) {
    const validee = await this._transaction(async (tx) => {
      const e = await tx.comptaEcriture.findUnique({ where: { id: Number(id) }, include: { lignes: true, journal: true, exercice: true } });
      if (!e) throw new ComptaError('Écriture introuvable', 404);
      if (e.statut !== 'brouillon') throw new ComptaError('Cette écriture est déjà validée', 409, 'DEJA_VALIDEE');

      const contexte = await this._exerciceEtPeriode(tx, e.dateEcriture);
      this._verifierOuverts(contexte);
      // Re-contrôle de l'équilibre sur ce qui est réellement en base
      const debit = e.lignes.reduce((s, l) => s + l.debit, 0);
      const credit = e.lignes.reduce((s, l) => s + l.credit, 0);
      if (debit !== credit || debit === 0 || e.lignes.length < 2) {
        throw new ComptaError(`Écriture déséquilibrée : débit ${debit} ≠ crédit ${credit}`, 400, 'DESEQUILIBRE');
      }

      const numeroPiece = await this._prochainNumero(tx, e.journal, contexte.exercice);
      return tx.comptaEcriture.update({
        where: { id: e.id },
        data: {
          numeroPiece,
          statut: 'validee',
          dateValidation: new Date(),
          exerciceId: contexte.exercice.id,
          ...(utilisateurId ? { utilisateurId: Number(utilisateurId) } : {}),
        },
        include: { lignes: true },
      });
    });
    await this._enqueue('compta_ecritures', 'UPDATE', { ...validee, lignes: undefined });
    await this.tracer('ecriture.validee', { utilisateurId, entiteType: 'ecriture', entiteId: validee.id, details: { numeroPiece: validee.numeroPiece, origine: validee.origine } });
    return validee;
  }

  /** Annule une pièce validée par une écriture inverse (l'originale passe à « contrepassee ») */
  async contrepasser(id, { dateEcriture, motif, utilisateurId } = {}) {
    const res = await this._transaction(async (tx) => {
      const o = await tx.comptaEcriture.findUnique({ where: { id: Number(id) }, include: { lignes: true, journal: true } });
      if (!o) throw new ComptaError('Écriture introuvable', 404);
      if (o.statut === 'contrepassee') throw new ComptaError('Cette écriture est déjà contre-passée', 409, 'DEJA_CONTREPASSEE');
      if (o.statut !== 'validee') throw new ComptaError('Seule une écriture validée se contre-passe (supprimez un brouillon)', 409);
      if (o.origine === 'auto') {
        throw new ComptaError('Écriture automatique : corrigez l\'opération d\'origine (vente, commande, dépense...), la comptabilité se régularise seule', 409, 'ECRITURE_AUTO');
      }
      if (o.origine === 'contrepassation') throw new ComptaError('Une contre-passation ne se contre-passe pas : saisissez une nouvelle écriture', 409);

      const date = jourUtc(dateEcriture || new Date(), 'Date de contre-passation');
      const contexte = await this._exerciceEtPeriode(tx, date);
      this._verifierOuverts(contexte);

      const contre = await tx.comptaEcriture.create({
        data: {
          exerciceId: contexte.exercice.id,
          journalId: o.journalId,
          dateEcriture: date,
          libelle: `Contre-passation de ${o.numeroPiece}${motif ? ` — ${motif}` : ''}`,
          statut: 'brouillon',
          origine: 'contrepassation',
          sourceType: 'contrepassation',
          sourceId: o.id,
          sourceRole: 'inverse',
          contrepasseId: o.id,
          boutiqueId: o.boutiqueId,
          utilisateurId: utilisateurId ? Number(utilisateurId) : o.utilisateurId,
          lignes: {
            create: o.lignes.map((l) => ({
              compteId: l.compteId,
              tiersType: l.tiersType,
              tiersId: l.tiersId,
              libelle: l.libelle,
              debit: l.credit,
              credit: l.debit,
              boutiqueId: l.boutiqueId,
            })),
          },
        },
        include: { lignes: true },
      });
      const numeroPiece = await this._prochainNumero(tx, o.journal, contexte.exercice);
      const validee = await tx.comptaEcriture.update({
        where: { id: contre.id },
        data: { numeroPiece, statut: 'validee', dateValidation: new Date() },
        include: { lignes: true },
      });
      const originale = await tx.comptaEcriture.update({ where: { id: o.id }, data: { statut: 'contrepassee' } });
      return { contre: validee, originale };
    });

    await this._enqueueEcriture('INSERT', res.contre);
    await this._enqueue('compta_ecritures', 'UPDATE', res.originale);
    await this.tracer('ecriture.contrepassee', { utilisateurId, entiteType: 'ecriture', entiteId: res.originale.id, details: { numeroPiece: res.originale.numeroPiece, contrePassation: res.contre.numeroPiece, motif: motif || null } });
    return res;
  }

  async getEcriture(id) {
    const e = await this.prisma.comptaEcriture.findUnique({
      where: { id: Number(id) },
      include: { lignes: { include: { compte: true }, orderBy: { id: 'asc' } }, journal: true },
    });
    if (!e) throw new ComptaError('Écriture introuvable', 404);
    return e;
  }

  async listerEcritures({ journalCode, statut, exerciceId, dateDebut, dateFin, boutiqueId, q, page = 1, limit = 50 } = {}) {
    const where = {};
    if (journalCode) where.journal = { code: String(journalCode) };
    if (statut) where.statut = String(statut);
    if (exerciceId) where.exerciceId = Number(exerciceId);
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    if (dateDebut || dateFin) {
      where.dateEcriture = {};
      if (dateDebut) where.dateEcriture.gte = jourUtc(dateDebut, 'Date de début');
      if (dateFin) where.dateEcriture.lte = jourUtc(dateFin, 'Date de fin');
    }
    if (q) where.OR = [{ libelle: { contains: String(q) } }, { numeroPiece: { contains: String(q) } }];
    page = Math.max(1, Number(page) || 1);
    limit = Math.min(200, Math.max(1, Number(limit) || 50));
    const [total, ecritures] = await Promise.all([
      this.prisma.comptaEcriture.count({ where }),
      this.prisma.comptaEcriture.findMany({
        where,
        include: { journal: true, lignes: { include: { compte: true }, orderBy: { id: 'asc' } } },
        orderBy: [{ dateEcriture: 'desc' }, { id: 'desc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);
    return { ecritures, total, page, limit };
  }

  // ───────────────────────────── Ouverture ─────────────────────────────

  /**
   * Assistant d'ouverture : crée l'exercice (s'il n'existe pas), l'écriture
   * d'à-nouveaux (journal AN) à partir des soldes saisis, et mémorise régime et date.
   * Un écart éventuel va sur un compte d'attente (4711/4712) à justifier ensuite.
   */
  async enregistrerOuverture({ dateOuverture, dateFinExercice, libelleExercice, regime, soldes = [], clients = [], fournisseurs = [], utilisateurId } = {}) {
    const params = await this.getParametres();
    if (params.ouvertureValidee) throw new ComptaError('L\'ouverture a déjà été enregistrée', 409, 'OUVERTURE_DEJA_FAITE');
    const debut = jourUtc(dateOuverture, 'Date d\'ouverture');
    if (regime !== undefined && !['normal', 'smt'].includes(regime)) throw new ComptaError('Régime invalide (normal ou smt)');

    let exercice = await this.prisma.comptaExercice.findFirst({ where: { dateDebut: { lte: debut }, dateFin: { gte: debut } } });
    if (!exercice) {
      const fin = dateFinExercice ? jourUtc(dateFinExercice, 'Date de fin') : new Date(Date.UTC(debut.getUTCFullYear(), 11, 31));
      exercice = await this.creerExercice({ libelle: libelleExercice, dateDebut: debut, dateFin: fin });
    }

    const lignes = (soldes || [])
      .filter((s) => Number(s.debit || 0) > 0 || Number(s.credit || 0) > 0)
      .map((s) => ({ ...s, libelle: s.libelle || 'Solde d\'ouverture' }));
    // Soldes par tiers : client > 0 = créance (411), < 0 = avance reçue (4191) ; fournisseur > 0 = dette (401), < 0 = avance versée (4091)
    for (const c of clients || []) {
      const m = Number(c.montant);
      if (!Number.isInteger(m)) throw new ComptaError('Les soldes des clients doivent être des entiers (FCFA)');
      if (m === 0) continue;
      lignes.push(m > 0
        ? { compteNumero: '411', debit: m, tiersType: 'client', tiersId: Number(c.clientId), libelle: 'Créance client à l\'ouverture' }
        : { compteNumero: '4191', credit: -m, tiersType: 'client', tiersId: Number(c.clientId), libelle: 'Avance client à l\'ouverture' });
    }
    for (const fo of fournisseurs || []) {
      const m = Number(fo.montant);
      if (!Number.isInteger(m)) throw new ComptaError('Les soldes des fournisseurs doivent être des entiers (FCFA)');
      if (m === 0) continue;
      lignes.push(m > 0
        ? { compteNumero: '401', credit: m, tiersType: 'fournisseur', tiersId: Number(fo.fournisseurId), libelle: 'Dette fournisseur à l\'ouverture' }
        : { compteNumero: '4091', debit: -m, tiersType: 'fournisseur', tiersId: Number(fo.fournisseurId), libelle: 'Avance fournisseur à l\'ouverture' });
    }
    const totalDebit = lignes.reduce((a, s) => a + Number(s.debit || 0), 0);
    const totalCredit = lignes.reduce((a, s) => a + Number(s.credit || 0), 0);
    const ecart = totalDebit - totalCredit;
    if (ecart !== 0) {
      lignes.push(ecart > 0
        ? { compteNumero: '4712', credit: ecart, libelle: 'Écart d\'ouverture à justifier' }
        : { compteNumero: '4711', debit: -ecart, libelle: 'Écart d\'ouverture à justifier' });
    }

    let ecriture = null;
    if (lignes.length >= 2) {
      ecriture = await this.creerEcriture({
        journalCode: 'AN',
        dateEcriture: debut,
        libelle: 'Bilan d\'ouverture',
        lignes,
        origine: 'ouverture',
        source: { type: 'ouverture', id: exercice.id, role: 'bilan' },
        utilisateurId,
        valider: true,
      });
    }

    const maj = await this.prisma.comptaParametres.update({
      where: { id: 1 },
      data: { dateOuverture: debut, ouvertureValidee: true, exerciceDefautId: exercice.id, ...(regime ? { regime } : {}) },
    });
    await this._enqueue('compta_parametres', 'UPDATE', maj);
    await this.tracer('ouverture.enregistree', { utilisateurId, entiteType: 'exercice', entiteId: exercice.id, details: { dateOuverture: debut.toISOString().slice(0, 10), ecart, regime: maj.regime } });
    return { exercice, ecriture, ecart, parametres: maj };
  }

  // ───────────────────────────── États ─────────────────────────────

  _filtreLignes({ exerciceId, dateDebut, dateFin, boutiqueId }) {
    const ecriture = { statut: { in: STATUTS_COMPTABILISES } };
    if (exerciceId) ecriture.exerciceId = Number(exerciceId);
    if (dateDebut || dateFin) {
      ecriture.dateEcriture = {};
      if (dateDebut) ecriture.dateEcriture.gte = jourUtc(dateDebut, 'Date de début');
      if (dateFin) ecriture.dateEcriture.lte = jourUtc(dateFin, 'Date de fin');
    }
    const where = { ecriture };
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    return where;
  }

  /** Grand livre d'un compte (général ou auxiliaire si tiersType/tiersId) avec solde progressif */
  async grandLivre({ compteNumero, exerciceId, dateDebut, dateFin, boutiqueId, tiersType, tiersId } = {}) {
    const compte = await this.prisma.comptaCompte.findUnique({ where: { numero: String(compteNumero || '') } });
    if (!compte) throw new ComptaError('Compte introuvable', 404);
    const params = await this.getParametres();

    const filtre = (extra = {}) => {
      const w = this._filtreLignes({ exerciceId, dateDebut: extra.dateDebut, dateFin: extra.dateFin, boutiqueId });
      w.compteId = compte.id;
      if (tiersType) w.tiersType = String(tiersType);
      if (tiersId) w.tiersId = Number(tiersId);
      return w;
    };

    // Solde reporté : mouvements de l'exercice AVANT la date de début demandée
    let soldeDebut = 0;
    if (dateDebut) {
      const avant = await this.prisma.comptaLigne.aggregate({
        where: (() => {
          const w = this._filtreLignes({ exerciceId, boutiqueId });
          w.ecriture.dateEcriture = { lt: jourUtc(dateDebut, 'Date de début') };
          w.compteId = compte.id;
          if (tiersType) w.tiersType = String(tiersType);
          if (tiersId) w.tiersId = Number(tiersId);
          return w;
        })(),
        _sum: { debit: true, credit: true },
      });
      soldeDebut = (avant._sum.debit || 0) - (avant._sum.credit || 0);
    }

    const lignes = await this.prisma.comptaLigne.findMany({
      where: filtre({ dateDebut, dateFin }),
      include: { ecriture: { include: { journal: true } } },
      orderBy: [{ ecriture: { dateEcriture: 'asc' } }, { ecriture: { numeroPiece: 'asc' } }, { id: 'asc' }],
    });

    let solde = soldeDebut;
    let totalDebit = 0;
    let totalCredit = 0;
    const mouvements = lignes.map((l) => {
      solde += l.debit - l.credit;
      totalDebit += l.debit;
      totalCredit += l.credit;
      return {
        id: l.id,
        date: l.ecriture.dateEcriture,
        journal: l.ecriture.journal.code,
        numeroPiece: l.ecriture.numeroPiece,
        libelle: l.libelle || l.ecriture.libelle,
        compteAuxiliaire: l.tiersId ? numeroAuxiliaire(compte.numero, l.tiersId, params.longueurComptesTiers) : null,
        tiersType: l.tiersType,
        tiersId: l.tiersId,
        debit: l.debit,
        credit: l.credit,
        solde,
        lettrage: l.lettrage,
      };
    });
    return { compte, soldeDebut, mouvements, totalDebit, totalCredit, soldeFin: solde };
  }

  /** Balance générale : cumuls débit/crédit et soldes par compte */
  async balance({ exerciceId, dateDebut, dateFin, boutiqueId, inclureSoldesNuls = false } = {}) {
    const groupes = await this.prisma.comptaLigne.groupBy({
      by: ['compteId'],
      where: this._filtreLignes({ exerciceId, dateDebut, dateFin, boutiqueId }),
      _sum: { debit: true, credit: true },
    });
    const comptes = await this.prisma.comptaCompte.findMany({ where: { id: { in: groupes.map((g) => g.compteId) } } });
    const parId = new Map(comptes.map((c) => [c.id, c]));

    const lignes = groupes
      .map((g) => {
        const c = parId.get(g.compteId);
        const debit = g._sum.debit || 0;
        const credit = g._sum.credit || 0;
        const solde = debit - credit;
        return {
          numero: c.numero,
          libelle: c.libelle,
          classe: c.classe,
          debit,
          credit,
          soldeDebiteur: solde > 0 ? solde : 0,
          soldeCrediteur: solde < 0 ? -solde : 0,
        };
      })
      .filter((l) => inclureSoldesNuls || l.debit !== 0 || l.credit !== 0)
      .sort((a, b) => a.numero.localeCompare(b.numero, 'fr', { numeric: true }));

    const total = lignes.reduce(
      (t, l) => ({
        debit: t.debit + l.debit,
        credit: t.credit + l.credit,
        soldeDebiteur: t.soldeDebiteur + l.soldeDebiteur,
        soldeCrediteur: t.soldeCrediteur + l.soldeCrediteur,
      }),
      { debit: 0, credit: 0, soldeDebiteur: 0, soldeCrediteur: 0 },
    );
    return { lignes, total, equilibree: total.debit === total.credit && total.soldeDebiteur === total.soldeCrediteur };
  }
}

module.exports = { ComptaService, ComptaError, jourUtc, rangMois, numeroAuxiliaire, STATUTS_COMPTABILISES };
