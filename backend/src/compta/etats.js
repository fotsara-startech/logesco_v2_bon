/**
 * États comptables (phase 3) : compte de résultat, bilan, déclaration de TVA, balance âgée, lettrage,
 * livre des recettes et dépenses (SMT), résumé pour le mode simple, et export des tableaux (CSV / Excel).
 * Voir docs/CONCEPTION_COMPTABILITE_OHADA.md §8.
 *
 * Tous les états lisent les lignes d'écritures VALIDÉES (brouillons exclus). Les montants sont des entiers FCFA.
 */
const ExcelJS = require('exceljs');
const installation = require('../utils/installation');
const config = require('./etats-syscohada.json');
const { ComptaError, jourUtc, STATUTS_COMPTABILISES: STATUTS } = require('./compta-service');

const JOUR_MS = 24 * 3600 * 1000;

const commence = (numero, prefixes) => prefixes.some((p) => numero.startsWith(p));

class EtatsService {
  constructor(prisma, comptaService) {
    this.prisma = prisma;
    this.compta = comptaService;
  }

  /** Exercice et bornes de dates : exercice demandé, sinon celui qui couvre la date de fin (ou aujourd'hui), sinon le plus récent */
  async _periode({ exerciceId, dateDebut, dateFin } = {}) {
    let exercice = null;
    if (exerciceId) exercice = await this.prisma.comptaExercice.findUnique({ where: { id: Number(exerciceId) } });
    if (!exercice) {
      const ref = dateFin ? jourUtc(dateFin, 'Date de fin') : jourUtc(new Date());
      exercice = await this.prisma.comptaExercice.findFirst({ where: { dateDebut: { lte: ref }, dateFin: { gte: ref } } });
    }
    if (!exercice) exercice = await this.prisma.comptaExercice.findFirst({ orderBy: { dateDebut: 'desc' } });
    if (!exercice) throw new ComptaError('Aucun exercice comptable : enregistrez d\'abord l\'ouverture', 404, 'AUCUN_EXERCICE');
    return {
      exercice,
      debut: dateDebut ? jourUtc(dateDebut, 'Date de début') : exercice.dateDebut,
      fin: dateFin ? jourUtc(dateFin, 'Date de fin') : exercice.dateFin,
    };
  }

  /** Soldes par compte sur la période : Map numero → { numero, libelle, classe, debit, credit, net } */
  async _soldes({ exerciceId, debut, fin, boutiqueId, journalTypeExclu, seulementJournalType, exclureCloture }) {
    const where = { ecriture: { statut: { in: STATUTS }, exerciceId, dateEcriture: { gte: debut, lte: fin } } };
    if (journalTypeExclu) where.ecriture.journal = { type: { not: journalTypeExclu } };
    if (seulementJournalType) where.ecriture.journal = { type: seulementJournalType };
    if (exclureCloture) where.ecriture.origine = { not: 'cloture' };
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    const groupes = await this.prisma.comptaLigne.groupBy({ by: ['compteId'], where, _sum: { debit: true, credit: true } });
    const comptes = await this.prisma.comptaCompte.findMany({ where: { id: { in: groupes.map((g) => g.compteId) } } });
    const parId = new Map(comptes.map((c) => [c.id, c]));
    const m = new Map();
    for (const g of groupes) {
      const c = parId.get(g.compteId);
      const debit = g._sum.debit || 0;
      const credit = g._sum.credit || 0;
      m.set(c.numero, { numero: c.numero, libelle: c.libelle, classe: c.classe, debit, credit, net: debit - credit });
    }
    return m;
  }

  /** Pour les comptes de tiers du bilan (clients, fournisseurs) : solde de CHAQUE tiers, car une créance et une avance ne se compensent pas */
  async _soldesTiers({ exerciceId, debut, fin, boutiqueId }) {
    const comptes = await this.prisma.comptaCompte.findMany({ where: { numero: { in: ['401', '411', '416'] } } });
    const where = { compteId: { in: comptes.map((c) => c.id) }, ecriture: { statut: { in: STATUTS }, exerciceId, dateEcriture: { gte: debut, lte: fin } } };
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    const groupes = await this.prisma.comptaLigne.groupBy({ by: ['compteId', 'tiersId'], where, _sum: { debit: true, credit: true } });
    const numeroDe = new Map(comptes.map((c) => [c.id, c.numero]));
    const m = new Map();
    for (const g of groupes) {
      const numero = numeroDe.get(g.compteId);
      m.set(numero, [...(m.get(numero) || []), { net: (g._sum.debit || 0) - (g._sum.credit || 0) }]);
    }
    return m;
  }

  // ───────────────────────────── Compte de résultat ─────────────────────────────

  async compteDeResultat(params = {}) {
    const { exercice, debut, fin } = await this._periode(params);
    const soldes = await this._soldes({ exerciceId: exercice.id, debut, fin, boutiqueId: params.boutiqueId, exclureCloture: true });
    const valeurs = new Map();
    const utilises = new Set();
    const lignes = [];

    for (const r of config.resultat) {
      let montant = 0;
      if (r.type === 'total') {
        for (const [signe, id] of r.formule) montant += (signe === '+' ? 1 : -1) * (valeurs.get(id) || 0);
      } else {
        for (const s of soldes.values()) {
          if (!commence(s.numero, r.comptes)) continue;
          utilises.add(s.numero);
          montant += r.type === 'produit' ? -s.net : s.net; // produit : crédit − débit ; charge : débit − crédit
        }
      }
      if (r.id === 'resultat_net') {
        // Comptes de résultat que la structure ne reconnaît pas : ils comptent quand même dans le résultat
        let nonClasses = 0;
        const detail = [];
        for (const s of soldes.values()) {
          if (s.classe >= 6 && s.classe <= 8 && !utilises.has(s.numero)) {
            nonClasses += -s.net;
            detail.push({ numero: s.numero, libelle: s.libelle, montant: -s.net });
          }
        }
        valeurs.set('non_classes', nonClasses);
        if (nonClasses !== 0) {
          lignes.splice(lignes.length, 0, { id: 'non_classes', libelle: 'Comptes non classés dans la structure', type: 'produit', montant: nonClasses, detail });
        }
        montant += nonClasses;
      }
      valeurs.set(r.id, montant);
      lignes.push({ id: r.id, libelle: r.libelle, type: r.type, montant });
    }
    const chiffreAffaires = (valeurs.get('ventes_marchandises') || 0) + (valeurs.get('rrr_accordes') || 0) + (valeurs.get('autres_ventes') || 0);
    return { exercice: { id: exercice.id, libelle: exercice.libelle }, debut, fin, lignes, chiffreAffaires, resultatNet: valeurs.get('resultat_net') || 0 };
  }

  // ───────────────────────────── Bilan ─────────────────────────────

  async bilan(params = {}) {
    const { exercice, debut, fin } = await this._periode(params);
    const soldes = await this._soldes({ exerciceId: exercice.id, debut, fin, boutiqueId: params.boutiqueId });
    const montants = new Map();
    const ajouter = (id, v) => montants.set(id, (montants.get(id) || 0) + v);
    const affectes = new Set();
    const bilan = config.bilan;

    const trouver = (cote, numero, net) => {
      for (const r of bilan[cote]) {
        if (!r.comptes || !commence(numero, r.comptes)) continue;
        if (r.mode === 'debiteur' && net <= 0) continue;
        if (r.mode === 'crediteur' && net >= 0) continue;
        return { r, valeur: r.mode === 'net' ? net : r.mode === 'credit' ? -net : r.mode === 'debiteur' ? net : -net };
      }
      return null;
    };

    const parTiers = await this._soldesTiers({ exerciceId: exercice.id, debut, fin, boutiqueId: params.boutiqueId });
    const elements = [];
    for (const s of soldes.values()) {
      if (parTiers.has(s.numero)) for (const t of parTiers.get(s.numero)) elements.push({ ...s, net: t.net });
      else elements.push(s);
    }

    for (const s of elements) {
      if (s.classe > 5 || s.net === 0) continue; // classes 6 à 8 : résultat de l'exercice en cours
      let affectation = null;
      // Actif pour un solde débiteur ; passif pour un solde créditeur ; les rubriques « net » et « credit » prennent les deux sens
      const ordre = s.net > 0 ? ['actif', 'passif'] : ['passif', 'actif'];
      for (const cote of ordre) {
        const t = trouver(cote, s.numero, s.net);
        if (t) { affectation = { cote, ...t }; break; }
      }
      // Repli : tiers et trésorerie suivent le sens du solde
      if (!affectation && s.classe === 4) {
        const id = s.net > 0 ? 'autres_creances' : 'autres_dettes';
        affectation = { cote: s.net > 0 ? 'actif' : 'passif', r: { id }, valeur: Math.abs(s.net) };
      }
      if (!affectation && s.classe === 5) {
        const id = s.net > 0 ? 'tresorerie_actif' : 'tresorerie_passif';
        affectation = { cote: s.net > 0 ? 'actif' : 'passif', r: { id }, valeur: Math.abs(s.net) };
      }
      if (!affectation) continue;
      ajouter(affectation.r.id, affectation.valeur);
      affectes.add(s.numero);
    }

    // Résultat de l'exercice non encore clôturé = produits − charges (classes 6 à 8)
    let resultatEnCours = 0;
    for (const s of soldes.values()) if (s.classe >= 6 && s.classe <= 8) resultatEnCours += -s.net;
    ajouter('resultat_en_cours', resultatEnCours);

    const construire = (cote) => {
      const lignes = bilan[cote].map((r) => ({ id: r.id, libelle: r.libelle, montant: montants.get(r.id) || 0 }));
      return { lignes, total: lignes.reduce((t, l) => t + l.montant, 0) };
    };
    const actif = construire('actif');
    const passif = construire('passif');
    const nonAffectes = [...soldes.values()].filter((s) => s.classe <= 5 && s.net !== 0 && !affectes.has(s.numero))
      .map((s) => ({ numero: s.numero, libelle: s.libelle, net: s.net }));
    return {
      exercice: { id: exercice.id, libelle: exercice.libelle }, debut, fin, actif, passif, resultatEnCours,
      equilibre: actif.total === passif.total && nonAffectes.length === 0, nonAffectes,
    };
  }

  // ───────────────────────────── Tableau des flux de trésorerie (TFT) ─────────────────────────────

  /**
   * TFT par la méthode indirecte, calculé à partir des seuls mouvements de l'exercice (à-nouveaux et écriture de clôture exclus) :
   * trésorerie nette d'ouverture → flux opérationnels, d'investissement, de financement → trésorerie nette de clôture.
   * Il remplace l'ancien TAFIRE (SYSCOHADA révisé, dans l'esprit de la norme IAS 7).
   * Tout compte hors trésorerie est rangé dans l'un des trois flux, donc leur somme égale la variation de trésorerie par construction ;
   * l'indicateur « controle » vérifie en plus que la trésorerie de clôture retombe sur le solde des comptes de trésorerie.
   * [À VALIDER] : rangement de certains comptes (cessions, provisions, comptes d'associés) et libellés par rapport au modèle officiel.
   */
  async fluxTresorerie(params = {}) {
    const { exercice, fin } = await this._periode(params);
    const mouvements = await this._soldes({ exerciceId: exercice.id, debut: exercice.dateDebut, fin, journalTypeExclu: 'a_nouveaux', exclureCloture: true });
    const ouverture = await this._soldes({ exerciceId: exercice.id, debut: exercice.dateDebut, fin: exercice.dateFin, seulementJournalType: 'a_nouveaux' });
    const tous = await this._soldes({ exerciceId: exercice.id, debut: exercice.dateDebut, fin });

    const estTreso = (n) => commence(n, config.tresorerie);
    const somme = (m, test) => [...m.values()].filter((s) => test(s.numero)).reduce((t, s) => t + s.net, 0);
    const soldeOuverture = somme(ouverture, estTreso);
    const variationReelle = somme(mouvements, estTreso);

    // Rangement des comptes (hors trésorerie) ; par défaut : résultat (classes 6, 7 et 89)
    const nonCash = ['28', '29', '15', '39', '49', '59'];
    const investissement = ['20', '21', '22', '23', '24', '25', '26', '27', '754', '81', '82', '83', '84'];
    const financement = ['10', '11', '12', '13', '14', '16', '17', '18', '19', '45', '46'];
    const stocks = ['31', '32', '33', '34', '35', '36', '37', '38'];
    const exploitation = ['40', '41', '42', '43', '44', '47'];
    const groupe = (n) => {
      if (estTreso(n)) return 'tresorerie';
      if (commence(n, nonCash)) return 'noncash';
      if (commence(n, investissement)) return 'investissement';
      if (commence(n, financement)) return 'financement';
      if (commence(n, stocks)) return 'stocks';
      if (commence(n, exploitation)) return 'exploitation';
      return 'resultat';
    };
    const flux = { resultat: 0, noncash: 0, stocks: 0, exploitation: 0, investissement: 0, financement: 0 };
    const detail = { acquisitions: 0, cessions: 0, capitaux: 0, associes: 0 };
    for (const s of mouvements.values()) {
      const g = groupe(s.numero);
      if (g === 'tresorerie') continue;
      flux[g] += -s.net; // un compte qui augmente au débit consomme de la trésorerie
      if (g === 'investissement') { if (s.classe === 2) detail.acquisitions += -s.net; else detail.cessions += -s.net; }
      if (g === 'financement') { if (s.numero.startsWith('45') || s.numero.startsWith('46')) detail.associes += -s.net; else detail.capitaux += -s.net; }
    }
    const cafg = flux.resultat + flux.noncash;
    const variationBfr = flux.stocks + flux.exploitation;
    const fluxOperationnels = cafg + variationBfr;
    const variation = fluxOperationnels + flux.investissement + flux.financement;
    const cloture = soldeOuverture + variation;
    const soldeCloture = somme(tous, estTreso);

    return {
      exercice: { id: exercice.id, libelle: exercice.libelle }, debut: exercice.dateDebut, fin,
      tresorerieOuverture: soldeOuverture,
      resultat: flux.resultat, dotationsNettes: flux.noncash, cafg,
      variationStocks: flux.stocks, variationCreancesDettes: flux.exploitation, variationBfr, fluxOperationnels,
      acquisitions: detail.acquisitions, cessions: detail.cessions, fluxInvestissement: flux.investissement,
      capitauxEtEmprunts: detail.capitaux, associesEtDividendes: detail.associes, fluxFinancement: flux.financement,
      variationTresorerie: variation, tresorerieCloture: cloture,
      controle: variation === variationReelle && cloture === soldeCloture,
    };
  }

  // ───────────────────────────── Déclaration de TVA ─────────────────────────────

  /**
   * TVA d'un mois. Les écritures d'opérations diverses (liquidation de TVA, régularisations) ne sont pas comptées :
   * la TVA collectée et déductible vient des ventes, achats, caisse et banque.
   * TVA due = collectée − déductible − crédit reporté ; un solde négatif devient crédit de TVA reporté sur le mois suivant.
   */
  async declarationTva({ exerciceId, annee, mois, boutiqueId } = {}) {
    annee = Number(annee); mois = Number(mois);
    if (!Number.isInteger(annee) || !Number.isInteger(mois) || mois < 1 || mois > 12) throw new ComptaError('Année et mois requis (mois de 1 à 12)');
    const ref = new Date(Date.UTC(annee, mois - 1, 15));
    const { exercice } = await this._periode({ exerciceId, dateFin: ref });
    const chaine = [];
    // Du premier mois de l'exercice jusqu'au mois demandé (pour le crédit reporté)
    let curseur = new Date(Date.UTC(exercice.dateDebut.getUTCFullYear(), exercice.dateDebut.getUTCMonth(), 1));
    const cible = new Date(Date.UTC(annee, mois - 1, 1));
    if (cible < curseur) throw new ComptaError('Ce mois précède l\'exercice');
    let report = 0;
    let resultat = null;
    while (curseur <= cible) {
      const d = curseur;
      const f = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0));
      const soldes = await this._soldes({ exerciceId: exercice.id, debut: d, fin: f, boutiqueId, journalTypeExclu: 'od' });
      let collectee = 0; let deductible = 0;
      for (const s of soldes.values()) {
        if (s.numero.startsWith('443')) collectee += -s.net;
        else if (s.numero.startsWith('445')) deductible += s.net;
      }
      const du = collectee - deductible - report;
      resultat = { annee: d.getUTCFullYear(), mois: d.getUTCMonth() + 1, collectee, deductible, creditReporte: report, tvaDue: Math.max(0, du), creditAReporter: Math.max(0, -du) };
      chaine.push(resultat);
      report = Math.max(0, -du);
      curseur = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1));
    }
    return { ...resultat, historique: chaine };
  }

  // ───────────────────────────── Balance âgée ─────────────────────────────

  /**
   * Créances clients (ou dettes fournisseurs) par ancienneté. Les règlements soldent d'abord les plus anciennes
   * échéances ; les lignes lettrées sont écartées ; un excédent de règlements apparaît comme avance.
   * Tranches (jours) : 0-30, 31-60, 61-90, plus de 90, mesurées à la date de référence.
   */
  async balanceAgee({ type = 'client', dateRef, boutiqueId } = {}) {
    if (!['client', 'fournisseur'].includes(type)) throw new ComptaError('Type invalide (client ou fournisseur)');
    const ref = dateRef ? jourUtc(dateRef, 'Date de référence') : jourUtc(new Date());
    const numeros = type === 'client' ? ['411', '416'] : ['401'];
    const comptes = await this.prisma.comptaCompte.findMany({ where: { numero: { in: numeros } } });
    const where = {
      compteId: { in: comptes.map((c) => c.id) }, tiersType: type, lettrage: null,
      ecriture: { statut: { in: STATUTS }, dateEcriture: { lte: ref } },
    };
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    const lignes = await this.prisma.comptaLigne.findMany({ where, include: { ecriture: { select: { dateEcriture: true, id: true } } } });

    const parTiers = new Map();
    for (const l of lignes) {
      if (!l.tiersId) continue;
      if (!parTiers.has(l.tiersId)) parTiers.set(l.tiersId, []);
      parTiers.get(l.tiersId).push(l);
    }
    const [t1, t2, t3] = config.agees.tranches;
    const noms = type === 'client'
      ? new Map((await this.prisma.client.findMany({ select: { id: true, nom: true, prenom: true } })).map((c) => [c.id, `${c.nom || ''} ${c.prenom || ''}`.trim()]))
      : new Map((await this.prisma.fournisseur.findMany({ select: { id: true, nom: true } })).map((f) => [f.id, f.nom]));

    const sens = type === 'client' ? 1 : -1; // client : débit = créance ; fournisseur : crédit = dette
    const resultat = [];
    for (const [tiersId, ls] of parTiers) {
      const echeances = ls.filter((l) => sens * (l.debit - l.credit) > 0)
        .map((l) => ({ date: l.ecriture.dateEcriture, reste: sens * (l.debit - l.credit), id: l.id }))
        .sort((a, b) => a.date - b.date || a.id - b.id);
      let reglements = ls.filter((l) => sens * (l.debit - l.credit) < 0).reduce((s, l) => s - sens * (l.debit - l.credit), 0);
      for (const e of echeances) {
        const part = Math.min(e.reste, reglements);
        e.reste -= part; reglements -= part;
      }
      const t = { tiersId, nom: noms.get(tiersId) || `#${tiersId}`, courant: 0, tranche1: 0, tranche2: 0, plus: 0, avance: reglements, total: 0 };
      for (const e of echeances) {
        if (e.reste <= 0) continue;
        const age = Math.floor((ref - e.date) / JOUR_MS);
        if (age <= t1) t.courant += e.reste; else if (age <= t2) t.tranche1 += e.reste; else if (age <= t3) t.tranche2 += e.reste; else t.plus += e.reste;
        t.total += e.reste;
      }
      if (t.total !== 0 || t.avance !== 0) resultat.push(t);
    }
    resultat.sort((a, b) => b.total - a.total);
    const total = resultat.reduce((s, t) => ({
      courant: s.courant + t.courant, tranche1: s.tranche1 + t.tranche1, tranche2: s.tranche2 + t.tranche2, plus: s.plus + t.plus, avance: s.avance + t.avance, total: s.total + t.total,
    }), { courant: 0, tranche1: 0, tranche2: 0, plus: 0, avance: 0, total: 0 });
    return { type, dateRef: ref, tranches: config.agees.tranches, tiers: resultat, total };
  }

  // ───────────────────────────── Lettrage ─────────────────────────────

  async _prochainCodeLettrage(compteId) {
    const suffixe = installation.documentSuffix();
    const existants = await this.prisma.comptaLigne.findMany({ where: { compteId, lettrage: { not: null } }, select: { lettrage: true }, distinct: ['lettrage'] });
    const motif = /^L(\d+)(-P\d+)?$/;
    let max = 0;
    for (const { lettrage } of existants) {
      const m = motif.exec(lettrage);
      if (m && (m[2] || '') === suffixe) max = Math.max(max, Number(m[1]));
    }
    return `L${String(max + 1).padStart(5, '0')}${suffixe}`;
  }

  async _enqueueLignes(lignes) {
    const sync = this.compta.syncService;
    if (!sync) return;
    for (const l of lignes) {
      try { await sync.enqueue('compta_lignes', 'UPDATE', l); } catch (e) { console.warn('⚠️  [Compta] synchro du lettrage :', e.message); }
    }
  }

  /** Rapproche des lignes d'un même compte et d'un même tiers dont les débits égalent les crédits */
  async lettrer(ligneIds = []) {
    const ids = [...new Set(ligneIds.map(Number))];
    if (ids.length < 2) throw new ComptaError('Sélectionnez au moins deux lignes à lettrer');
    const lignes = await this.prisma.comptaLigne.findMany({ where: { id: { in: ids } }, include: { ecriture: { select: { statut: true } } } });
    if (lignes.length !== ids.length) throw new ComptaError('Ligne introuvable', 404);
    if (lignes.some((l) => !STATUTS.includes(l.ecriture.statut))) throw new ComptaError('Seules les lignes d\'écritures validées se lettrent');
    if (lignes.some((l) => l.lettrage)) throw new ComptaError('Une ligne est déjà lettrée', 409, 'DEJA_LETTREE');
    const { compteId, tiersType, tiersId } = lignes[0];
    if (!tiersId || lignes.some((l) => l.compteId !== compteId || l.tiersType !== tiersType || l.tiersId !== tiersId)) {
      throw new ComptaError('Les lignes doivent appartenir au même compte et au même client ou fournisseur');
    }
    const debit = lignes.reduce((s, l) => s + l.debit, 0);
    const credit = lignes.reduce((s, l) => s + l.credit, 0);
    if (debit !== credit) throw new ComptaError(`Lettrage impossible : débit ${debit} ≠ crédit ${credit}`, 400, 'LETTRAGE_DESEQUILIBRE');
    const code = await this._prochainCodeLettrage(compteId);
    await this.prisma.comptaLigne.updateMany({ where: { id: { in: ids } }, data: { lettrage: code } });
    const maj = await this.prisma.comptaLigne.findMany({ where: { id: { in: ids } } });
    await this._enqueueLignes(maj);
    return { code, lignes: maj.length, montant: debit };
  }

  async delettrer(code) {
    const lignes = await this.prisma.comptaLigne.findMany({ where: { lettrage: String(code || '') } });
    if (lignes.length === 0) throw new ComptaError('Code de lettrage introuvable', 404);
    await this.prisma.comptaLigne.updateMany({ where: { lettrage: String(code) }, data: { lettrage: null } });
    await this._enqueueLignes(await this.prisma.comptaLigne.findMany({ where: { id: { in: lignes.map((l) => l.id) } } }));
    return { code, lignes: lignes.length };
  }

  /** Lettrage automatique : pour chaque tiers dont les lignes non lettrées s'annulent exactement, tout est lettré */
  async lettrageAutomatique({ type = 'client' } = {}) {
    const numeros = type === 'client' ? ['411'] : ['401'];
    const comptes = await this.prisma.comptaCompte.findMany({ where: { numero: { in: numeros } } });
    const lignes = await this.prisma.comptaLigne.findMany({
      where: { compteId: { in: comptes.map((c) => c.id) }, tiersType: type, tiersId: { not: null }, lettrage: null, ecriture: { statut: { in: STATUTS } } },
    });
    const parTiers = new Map();
    for (const l of lignes) {
      const cle = `${l.compteId}|${l.tiersId}`;
      parTiers.set(cle, [...(parTiers.get(cle) || []), l]);
    }
    const resultats = [];
    for (const ls of parTiers.values()) {
      const debit = ls.reduce((s, l) => s + l.debit, 0);
      const credit = ls.reduce((s, l) => s + l.credit, 0);
      if (ls.length >= 2 && debit === credit && debit > 0) resultats.push(await this.lettrer(ls.map((l) => l.id)));
    }
    return { lettrages: resultats.length, details: resultats };
  }

  // ───────────────────────────── SMT : recettes et dépenses ─────────────────────────────

  /** Livre des recettes et dépenses : tous les mouvements de trésorerie, avec solde, du plus ancien au plus récent */
  async livreRecettesDepenses({ exerciceId, dateDebut, dateFin, boutiqueId } = {}) {
    const { exercice, debut, fin } = await this._periode({ exerciceId, dateDebut, dateFin });
    const comptes = await this.prisma.comptaCompte.findMany({ where: { OR: config.tresorerie.map((p) => ({ numero: { startsWith: p } })) } });
    const ids = comptes.map((c) => c.id);
    const base = { compteId: { in: ids } };
    if (boutiqueId) base.boutiqueId = Number(boutiqueId);

    const avant = await this.prisma.comptaLigne.aggregate({
      where: { ...base, ecriture: { statut: { in: STATUTS }, exerciceId: exercice.id, dateEcriture: { lt: debut } } }, _sum: { debit: true, credit: true },
    });
    const soldeDebut = (avant._sum.debit || 0) - (avant._sum.credit || 0);
    const lignes = await this.prisma.comptaLigne.findMany({
      where: { ...base, ecriture: { statut: { in: STATUTS }, exerciceId: exercice.id, dateEcriture: { gte: debut, lte: fin } } },
      include: { ecriture: { include: { journal: true } } },
      orderBy: [{ ecriture: { dateEcriture: 'asc' } }, { id: 'asc' }],
    });
    let solde = soldeDebut; let recettes = 0; let depenses = 0;
    const mouvements = lignes.map((l) => {
      const net = l.debit - l.credit;
      solde += net;
      if (net > 0) recettes += net; else depenses += -net;
      return { date: l.ecriture.dateEcriture, journal: l.ecriture.journal.code, numeroPiece: l.ecriture.numeroPiece, libelle: l.libelle || l.ecriture.libelle, recette: net > 0 ? net : 0, depense: net < 0 ? -net : 0, solde };
    });
    return { exercice: { id: exercice.id, libelle: exercice.libelle }, debut, fin, soldeDebut, mouvements, totalRecettes: recettes, totalDepenses: depenses, soldeFin: solde };
  }

  /** Lignes d'écritures validées, une par ligne, pour l'export du journal (dans l'esprit du fichier des écritures comptables) */
  async journalLignes({ exerciceId, dateDebut, dateFin, journalCode, boutiqueId } = {}) {
    const { exercice, debut, fin } = await this._periode({ exerciceId, dateDebut, dateFin });
    const where = { ecriture: { statut: { in: STATUTS }, exerciceId: exercice.id, dateEcriture: { gte: debut, lte: fin }, ...(journalCode ? { journal: { code: String(journalCode) } } : {}) } };
    if (boutiqueId) where.boutiqueId = Number(boutiqueId);
    const params = await this.compta.getParametres();
    const lignes = await this.prisma.comptaLigne.findMany({
      where, include: { compte: true, ecriture: { include: { journal: true } } },
      orderBy: [{ ecriture: { dateEcriture: 'asc' } }, { ecriture: { numeroPiece: 'asc' } }, { id: 'asc' }],
    });
    return {
      exercice: { id: exercice.id, libelle: exercice.libelle }, debut, fin,
      lignes: lignes.map((l) => ({
        journal: l.ecriture.journal.code, date: l.ecriture.dateEcriture, numeroPiece: l.ecriture.numeroPiece, compte: l.compte.numero,
        libelleCompte: l.compte.libelle, compteAuxiliaire: l.tiersId ? String(l.compte.numero) + String(l.tiersId).padStart(params.longueurComptesTiers, '0') : '',
        libelle: l.libelle || l.ecriture.libelle, debit: l.debit, credit: l.credit, lettrage: l.lettrage || '', origine: l.ecriture.origine,
      })),
    };
  }

  /** Lignes non lettrées d'un compte de tiers, pour préparer un lettrage à la main */
  async lignesOuvertes({ compteNumero, tiersType, tiersId } = {}) {
    const compte = await this.prisma.comptaCompte.findUnique({ where: { numero: String(compteNumero || '') } });
    if (!compte) throw new ComptaError('Compte introuvable', 404);
    const where = { compteId: compte.id, lettrage: null, tiersId: { not: null }, ecriture: { statut: { in: STATUTS } } };
    if (tiersType) where.tiersType = String(tiersType);
    if (tiersId) where.tiersId = Number(tiersId);
    const lignes = await this.prisma.comptaLigne.findMany({ where, include: { ecriture: { select: { dateEcriture: true, numeroPiece: true, libelle: true } } }, orderBy: { id: 'asc' } });
    return lignes.map((l) => ({ id: l.id, tiersType: l.tiersType, tiersId: l.tiersId, date: l.ecriture.dateEcriture, numeroPiece: l.ecriture.numeroPiece, libelle: l.libelle || l.ecriture.libelle, debit: l.debit, credit: l.credit }));
  }

  // ───────────────────────────── Résumé (mode simple) ─────────────────────────────

  async resume({ boutiqueId, annee, mois } = {}) {
    const maintenant = new Date();
    annee = Number(annee) || maintenant.getUTCFullYear();
    mois = Number(mois) || maintenant.getUTCMonth() + 1;
    const debutMois = new Date(Date.UTC(annee, mois - 1, 1));
    const finMois = new Date(Date.UTC(annee, mois, 0));
    const { exercice } = await this._periode({ dateFin: finMois });

    const soldeMois = await this._soldes({ exerciceId: exercice.id, debut: debutMois, fin: finMois, boutiqueId, exclureCloture: true });
    const cumul = await this._soldes({ exerciceId: exercice.id, debut: exercice.dateDebut, fin: finMois, boutiqueId });
    const somme = (m, test, f) => [...m.values()].filter(test).reduce((s, x) => s + f(x), 0);

    const produits = somme(soldeMois, (s) => s.classe === 7, (s) => -s.net);
    const charges = somme(soldeMois, (s) => s.classe === 6 || s.classe === 8, (s) => s.net);
    const chiffreAffaires = somme(soldeMois, (s) => s.numero.startsWith('70'), (s) => -s.net);
    const topCharges = [...soldeMois.values()].filter((s) => s.classe === 6 && s.net > 0).sort((a, b) => b.net - a.net).slice(0, 5)
      .map((s) => ({ numero: s.numero, libelle: s.libelle, montant: s.net }));
    let tva = null;
    try { tva = await this.declarationTva({ exerciceId: exercice.id, annee, mois, boutiqueId }); } catch { tva = null; }
    const stock = somme(cumul, (s) => s.numero.startsWith('31'), (s) => s.net);

    return {
      exercice: { id: exercice.id, libelle: exercice.libelle }, annee, mois,
      chiffreAffaires, produits, charges, resultat: produits - charges,
      tresorerie: somme(cumul, (s) => commence(s.numero, config.tresorerie), (s) => s.net),
      creancesClients: somme(cumul, (s) => s.numero.startsWith('411') || s.numero.startsWith('416'), (s) => s.net),
      dettesFournisseurs: somme(cumul, (s) => s.numero.startsWith('401'), (s) => -s.net),
      stock,
      tvaAPayer: tva ? tva.tvaDue : 0,
      creditTva: tva ? tva.creditAReporter : 0,
      topCharges,
    };
  }
}

// ───────────────────────────── Export CSV / Excel ─────────────────────────────

/**
 * Un « tableau » est { titre, sousTitre?, colonnes: [{ cle, libelle, type? }], lignes: [{ cle: valeur }] }
 * (type : 'montant' pour les entiers FCFA, 'date' pour les dates).
 */
function formaterCellule(valeur, type) {
  if (valeur === null || valeur === undefined) return '';
  if (type === 'date' || valeur instanceof Date) {
    const d = valeur instanceof Date ? valeur : new Date(valeur);
    return Number.isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
  }
  return valeur;
}

function enCsv(tableau) {
  const echapper = (v) => {
    const s = String(v ?? '');
    return /[";\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const lignes = [tableau.colonnes.map((c) => echapper(c.libelle)).join(';')];
  for (const l of tableau.lignes) lignes.push(tableau.colonnes.map((c) => echapper(formaterCellule(l[c.cle], c.type))).join(';'));
  // BOM UTF-8 : Excel ouvre ainsi les accents correctement ; séparateur « ; » (réglages régionaux français)
  return Buffer.from('﻿' + lignes.join('\r\n') + '\r\n', 'utf8');
}

async function enXlsx(tableau) {
  const classeur = new ExcelJS.Workbook();
  const feuille = classeur.addWorksheet(String(tableau.titre || 'Etat').slice(0, 30).replace(/[\\/?*[\]:]/g, ' '));
  let ligne = 1;
  feuille.getCell(ligne, 1).value = tableau.titre;
  feuille.getCell(ligne, 1).font = { bold: true, size: 14 };
  ligne += 1;
  if (tableau.sousTitre) { feuille.getCell(ligne, 1).value = tableau.sousTitre; ligne += 1; }
  ligne += 1;
  tableau.colonnes.forEach((c, i) => {
    const cell = feuille.getCell(ligne, i + 1);
    cell.value = c.libelle;
    cell.font = { bold: true };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } };
    feuille.getColumn(i + 1).width = c.type === 'montant' ? 16 : c.cle === 'libelle' ? 46 : 20;
  });
  for (const l of tableau.lignes) {
    ligne += 1;
    tableau.colonnes.forEach((c, i) => {
      const cell = feuille.getCell(ligne, i + 1);
      cell.value = c.type === 'date' ? (l[c.cle] ? new Date(l[c.cle]) : null) : (l[c.cle] ?? null);
      if (c.type === 'montant') { cell.numFmt = '#,##0'; cell.alignment = { horizontal: 'right' }; }
      if (c.type === 'date') cell.numFmt = 'dd/mm/yyyy';
      if (l.gras) cell.font = { bold: true };
    });
  }
  return Buffer.from(await classeur.xlsx.writeBuffer());
}

// ───────────────────────────── Tableaux exportables ─────────────────────────────

const colMontant = (cle, libelle) => ({ cle, libelle, type: 'montant' });
const dateFr = (d) => (d instanceof Date ? d.toISOString().slice(0, 10) : String(d || '').slice(0, 10));

const tableaux = {
  tft: (t) => ({
    titre: 'Tableau des flux de trésorerie', sousTitre: `${t.exercice.libelle} — du ${dateFr(t.debut)} au ${dateFr(t.fin)}${t.controle ? '' : ' — CONTRÔLE EN ÉCART'}`,
    colonnes: [{ cle: 'libelle', libelle: 'Rubrique' }, colMontant('montant', 'Montant (FCFA)')],
    lignes: [
      { libelle: "Trésorerie nette à l'ouverture", montant: t.tresorerieOuverture, gras: true },
      { libelle: 'Résultat net (hors opérations hors activités ordinaires)', montant: t.resultat },
      { libelle: 'Dotations et reprises sans effet sur la trésorerie', montant: t.dotationsNettes },
      { libelle: "Capacité d'autofinancement globale (CAFG)", montant: t.cafg, gras: true },
      { libelle: 'Variation des stocks', montant: t.variationStocks },
      { libelle: "Variation des créances et des dettes d'exploitation", montant: t.variationCreancesDettes },
      { libelle: 'A. FLUX DE TRÉSORERIE DES ACTIVITÉS OPÉRATIONNELLES', montant: t.fluxOperationnels, gras: true },
      { libelle: "Variation des immobilisations en valeur brute (acquisitions, sorties)", montant: t.acquisitions },
      { libelle: "Cessions d'immobilisations et opérations hors activités ordinaires", montant: t.cessions },
      { libelle: "B. FLUX DE TRÉSORERIE DES ACTIVITÉS D'INVESTISSEMENT", montant: t.fluxInvestissement, gras: true },
      { libelle: 'Capitaux propres et emprunts (apports, remboursements)', montant: t.capitauxEtEmprunts },
      { libelle: 'Associés et dividendes', montant: t.associesEtDividendes },
      { libelle: 'C. FLUX DE TRÉSORERIE DES ACTIVITÉS DE FINANCEMENT', montant: t.fluxFinancement, gras: true },
      { libelle: 'VARIATION DE LA TRÉSORERIE NETTE (A + B + C)', montant: t.variationTresorerie, gras: true },
      { libelle: 'Trésorerie nette à la clôture', montant: t.tresorerieCloture, gras: true },
    ],
  }),
  journal: (j) => ({
    titre: 'Journal des écritures', sousTitre: `${j.exercice.libelle} — du ${dateFr(j.debut)} au ${dateFr(j.fin)}`,
    colonnes: [{ cle: 'journal', libelle: 'Journal' }, { cle: 'date', libelle: 'Date', type: 'date' }, { cle: 'numeroPiece', libelle: 'Pièce' }, { cle: 'compte', libelle: 'Compte' }, { cle: 'libelleCompte', libelle: 'Libellé du compte' },
      { cle: 'compteAuxiliaire', libelle: 'Compte auxiliaire' }, { cle: 'libelle', libelle: 'Libellé' }, colMontant('debit', 'Débit'), colMontant('credit', 'Crédit'), { cle: 'lettrage', libelle: 'Lettrage' }, { cle: 'origine', libelle: 'Origine' }],
    lignes: j.lignes,
  }),
  resultat: (r) => ({
    titre: 'Compte de résultat', sousTitre: `${r.exercice.libelle} — du ${dateFr(r.debut)} au ${dateFr(r.fin)}`,
    colonnes: [{ cle: 'libelle', libelle: 'Rubrique' }, colMontant('montant', 'Montant (FCFA)')],
    lignes: r.lignes.map((l) => ({ libelle: l.libelle, montant: l.montant, gras: l.type === 'total' })),
  }),
  bilan: (b) => ({
    titre: 'Bilan', sousTitre: `${b.exercice.libelle} — au ${dateFr(b.fin)}${b.equilibre ? '' : ' — NON ÉQUILIBRÉ'}`,
    colonnes: [{ cle: 'cote', libelle: 'Côté' }, { cle: 'libelle', libelle: 'Rubrique' }, colMontant('montant', 'Montant (FCFA)')],
    lignes: [
      ...b.actif.lignes.map((l) => ({ cote: 'Actif', libelle: l.libelle, montant: l.montant })),
      { cote: 'Actif', libelle: 'TOTAL ACTIF', montant: b.actif.total, gras: true },
      ...b.passif.lignes.map((l) => ({ cote: 'Passif', libelle: l.libelle, montant: l.montant })),
      { cote: 'Passif', libelle: 'TOTAL PASSIF', montant: b.passif.total, gras: true },
    ],
  }),
  tva: (t) => ({
    titre: `Déclaration de TVA — ${String(t.mois).padStart(2, '0')}/${t.annee}`,
    colonnes: [{ cle: 'libelle', libelle: 'Libellé' }, colMontant('montant', 'Montant (FCFA)')],
    lignes: [
      { libelle: 'TVA collectée (sur ventes)', montant: t.collectee },
      { libelle: 'TVA déductible (sur achats)', montant: t.deductible },
      { libelle: 'Crédit de TVA reporté du mois précédent', montant: t.creditReporte },
      { libelle: 'TVA DUE', montant: t.tvaDue, gras: true },
      { libelle: 'Crédit de TVA à reporter', montant: t.creditAReporter, gras: true },
    ],
  }),
  balanceAgee: (a) => ({
    titre: a.type === 'client' ? 'Balance âgée des clients' : 'Balance âgée des fournisseurs', sousTitre: `Au ${dateFr(a.dateRef)}`,
    colonnes: [{ cle: 'libelle', libelle: a.type === 'client' ? 'Client' : 'Fournisseur' }, colMontant('courant', `0 - ${a.tranches[0]} j`), colMontant('tranche1', `${a.tranches[0] + 1} - ${a.tranches[1]} j`),
      colMontant('tranche2', `${a.tranches[1] + 1} - ${a.tranches[2]} j`), colMontant('plus', `> ${a.tranches[2]} j`), colMontant('avance', 'Avance'), colMontant('total', 'Total dû')],
    lignes: [...a.tiers.map((t) => ({ libelle: t.nom, ...t })), { libelle: 'TOTAL', ...a.total, gras: true }],
  }),
  livreRecettesDepenses: (l) => ({
    titre: 'Livre des recettes et des dépenses', sousTitre: `${l.exercice.libelle} — du ${dateFr(l.debut)} au ${dateFr(l.fin)}`,
    colonnes: [{ cle: 'date', libelle: 'Date', type: 'date' }, { cle: 'numeroPiece', libelle: 'Pièce' }, { cle: 'libelle', libelle: 'Libellé' }, colMontant('recette', 'Recettes'), colMontant('depense', 'Dépenses'), colMontant('solde', 'Solde')],
    lignes: [
      { libelle: 'Solde à l\'ouverture de la période', solde: l.soldeDebut, gras: true },
      ...l.mouvements,
      { libelle: 'TOTAUX', recette: l.totalRecettes, depense: l.totalDepenses, solde: l.soldeFin, gras: true },
    ],
  }),
  balance: (b) => ({
    titre: 'Balance générale',
    colonnes: [{ cle: 'numero', libelle: 'Compte' }, { cle: 'libelle', libelle: 'Libellé' }, colMontant('debit', 'Débit'), colMontant('credit', 'Crédit'), colMontant('soldeDebiteur', 'Solde débiteur'), colMontant('soldeCrediteur', 'Solde créditeur')],
    lignes: [...b.lignes, { libelle: 'TOTAUX', ...b.total, gras: true }],
  }),
  grandLivre: (g) => ({
    titre: `Grand livre — ${g.compte.numero} ${g.compte.libelle}`,
    colonnes: [{ cle: 'date', libelle: 'Date', type: 'date' }, { cle: 'journal', libelle: 'Journal' }, { cle: 'numeroPiece', libelle: 'Pièce' }, { cle: 'libelle', libelle: 'Libellé' }, { cle: 'compteAuxiliaire', libelle: 'Compte auxiliaire' }, colMontant('debit', 'Débit'), colMontant('credit', 'Crédit'), colMontant('solde', 'Solde'), { cle: 'lettrage', libelle: 'Lettrage' }],
    lignes: [{ libelle: 'Solde reporté', solde: g.soldeDebut, gras: true }, ...g.mouvements, { libelle: 'TOTAUX', debit: g.totalDebit, credit: g.totalCredit, solde: g.soldeFin, gras: true }],
  }),
};

module.exports = { EtatsService, tableaux, enCsv, enXlsx };
