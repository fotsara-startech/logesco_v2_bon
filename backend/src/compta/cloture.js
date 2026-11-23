/**
 * Variation de stocks, clôture annuelle avec à-nouveaux, et rapprochement bancaire (phase 4).
 * Voir docs/CONCEPTION_COMPTABILITE_OHADA.md §6.3 et §6.7.
 */
const { ComptaError, jourUtc, STATUTS_COMPTABILISES: STATUTS } = require('./compta-service');
const { jourComptable } = require('./moteur-auto');
const regles = require('./regles-imputation.json');

const JOUR_MS = 24 * 3600 * 1000;

class ClotureService {
  /**
   * @param {object} prisma
   * @param {ComptaService} comptaService
   * @param {MoteurAuto} moteurAuto rapprochement des documents (variation de stocks)
   * @param {ImmobilisationService} immobilisations dotations de fin d'exercice
   */
  constructor(prisma, comptaService, moteurAuto, immobilisations) {
    this.prisma = prisma;
    this.compta = comptaService;
    this.moteur = moteurAuto;
    this.immobilisations = immobilisations;
  }

  // ───────────────────────────── Stocks ─────────────────────────────

  /** Valeur du stock de marchandises : quantités disponibles × coût moyen pondéré (à défaut, dernier prix d'achat) */
  async valeurStock() {
    const lignes = await this.prisma.stock.findMany({ include: { produit: { select: { cump: true, prixAchat: true, estService: true } } } });
    let total = 0;
    for (const l of lignes) {
      if (!l.produit || l.produit.estService || l.quantiteDisponible <= 0) continue;
      const cout = Number(l.produit.cump) || Number(l.produit.prixAchat) || 0;
      total += l.quantiteDisponible * cout;
    }
    return Math.round(total);
  }

  /**
   * Écriture de variation de stocks d'un exercice (inventaire intermittent) : amène le compte 31 à la valeur
   * du stock constaté, la différence allant au compte 6031. Relançable : l'écriture se régularise.
   * @param {{ exerciceId: number, date?: string, valeur?: number }} p valeur : stock constaté ; par défaut, valorisation CUMP actuelle
   */
  async variationStocks({ exerciceId, date, valeur } = {}) {
    const exercice = await this.prisma.comptaExercice.findUnique({ where: { id: Number(exerciceId) } });
    if (!exercice) throw new ComptaError('Exercice introuvable', 404);
    const params = await this.compta.getParametres();
    if (!params.ouvertureValidee) throw new ComptaError('Enregistrez d\'abord l\'ouverture de la comptabilité', 409);
    const calculee = valeur === undefined || valeur === null;
    const valeurStock = calculee ? await this.valeurStock() : Number(valeur);
    if (!Number.isInteger(valeurStock) || valeurStock < 0) throw new ComptaError('La valeur du stock doit être un entier positif ou nul');
    const jour = date ? jourUtc(date, 'Date d\'inventaire') : exercice.dateFin;

    const compte31 = await this.prisma.comptaCompte.findUnique({ where: { numero: '31' } });
    const agregat = await this.prisma.comptaLigne.aggregate({
      where: { compteId: compte31.id, ecriture: { exerciceId: exercice.id, statut: { in: STATUTS } } }, _sum: { debit: true, credit: true },
    });
    const solde31 = (agregat._sum.debit || 0) - (agregat._sum.credit || 0);
    const deja = await this.moteur._dejaComptabilise('variation_stocks');
    const dejaStock = (deja.get(exercice.id) || []).filter((l) => l.compteNumero === '31').reduce((s, l) => s + l.net, 0);
    const variation = valeurStock - (solde31 - dejaStock); // + : stock en hausse (produit), − : stock en baisse (charge)

    const r = await this.moteur.rapprocherDocument({
      sourceType: 'variation_stocks', sourceId: exercice.id, deja, ouverture: jourComptable(params.dateOuverture),
      journalCode: 'OD', dateDocument: jour, dateModification: null,
      libelle: `Variation de stocks ${exercice.libelle}`, boutiqueId: null,
      cible: variation === 0 ? [] : [{ compteNumero: '31', net: variation }, { compteNumero: '6031', net: -variation }],
    });
    return { valeurStock, valeurCalculee: calculee, variation, ecriture: r === 'cree' };
  }

  // ───────────────────────────── Clôture ─────────────────────────────

  /**
   * Clôture un exercice : dotations, variation de stocks, détermination du résultat (classes 6 à 8 soldées vers 131 ou 139),
   * création de l'exercice suivant, écriture d'à-nouveaux (classes 1 à 5, tiers par tiers), verrouillage. Irréversible.
   * @param {{ exerciceId: number, valeurStock?: number, utilisateurId?: number }} p
   */
  async cloturerExercice({ exerciceId, valeurStock, utilisateurId } = {}) {
    const exercice = await this.prisma.comptaExercice.findUnique({ where: { id: Number(exerciceId) } });
    if (!exercice) throw new ComptaError('Exercice introuvable', 404);
    if (exercice.statut !== 'ouvert') throw new ComptaError('Cet exercice est déjà clôturé', 409, 'EXERCICE_CLOTURE');
    const anterieur = await this.prisma.comptaExercice.findFirst({ where: { dateFin: { lt: exercice.dateDebut }, statut: 'ouvert' } });
    if (anterieur) throw new ComptaError(`Clôturez d'abord « ${anterieur.libelle} »`, 409, 'EXERCICE_ANTERIEUR_OUVERT');
    const brouillons = await this.prisma.comptaEcriture.count({ where: { exerciceId: exercice.id, statut: 'brouillon' } });
    if (brouillons > 0) throw new ComptaError(`${brouillons} écriture(s) en brouillon : validez-les ou supprimez-les avant la clôture`, 409, 'BROUILLONS_EXISTANTS');
    const bal = await this.compta.balance({ exerciceId: exercice.id });
    if (!bal.equilibree) throw new ComptaError('La balance n\'est pas équilibrée : clôture impossible', 409, 'BALANCE_DESEQUILIBREE');

    const resume = { exercice: { id: exercice.id, libelle: exercice.libelle } };
    resume.dotations = await this.immobilisations.dotationsExercice({ exerciceId: exercice.id });
    resume.variationStocks = await this.variationStocks({ exerciceId: exercice.id, valeur: valeurStock });

    // Résultat : solde des comptes de gestion (classes 6 à 8)
    const gestion = await this.prisma.comptaLigne.groupBy({
      by: ['compteId'], _sum: { debit: true, credit: true },
      where: { compte: { classe: { gte: 6, lte: 8 } }, ecriture: { exerciceId: exercice.id, statut: { in: STATUTS } } },
    });
    const comptes = new Map((await this.prisma.comptaCompte.findMany({ where: { id: { in: gestion.map((g) => g.compteId) } } })).map((c) => [c.id, c]));
    const lignes = [];
    let net = 0;
    for (const g of gestion) {
      const solde = (g._sum.debit || 0) - (g._sum.credit || 0);
      if (solde === 0) continue;
      net += solde;
      lignes.push({ compteNumero: comptes.get(g.compteId).numero, debit: solde < 0 ? -solde : 0, credit: solde > 0 ? solde : 0, libelle: 'Solde du compte de gestion' });
    }
    resume.resultat = -net;
    if (lignes.length > 0) {
      lignes.push(net < 0 ? { compteNumero: '131', credit: -net, libelle: 'Résultat de l\'exercice (bénéfice)' } : { compteNumero: '139', debit: net, libelle: 'Résultat de l\'exercice (perte)' });
      resume.ecritureCloture = (await this.compta.creerEcriture({
        journalCode: 'OD', dateEcriture: exercice.dateFin, libelle: `Clôture ${exercice.libelle} : détermination du résultat`, lignes,
        origine: 'cloture', source: { type: 'cloture', id: exercice.id, role: 'resultat' }, utilisateurId, valider: true,
      })).numeroPiece;
    }

    // Exercice suivant
    const debutSuivant = new Date(exercice.dateFin.getTime() + JOUR_MS);
    let suivant = await this.prisma.comptaExercice.findFirst({ where: { dateDebut: debutSuivant } });
    if (!suivant) {
      suivant = await this.compta.creerExercice({
        libelle: `Exercice ${debutSuivant.getUTCFullYear()}`, dateDebut: debutSuivant,
        dateFin: new Date(Date.UTC(debutSuivant.getUTCFullYear() + 1, debutSuivant.getUTCMonth(), debutSuivant.getUTCDate() - 1)),
      });
    }
    resume.exerciceSuivant = { id: suivant.id, libelle: suivant.libelle };

    // À-nouveaux : soldes des classes 1 à 5, compte par compte et tiers par tiers
    const bilan = await this.prisma.comptaLigne.groupBy({
      by: ['compteId', 'tiersType', 'tiersId'], _sum: { debit: true, credit: true },
      where: { compte: { classe: { lte: 5 } }, ecriture: { exerciceId: exercice.id, statut: { in: STATUTS } } },
    });
    const comptesBilan = new Map((await this.prisma.comptaCompte.findMany({ where: { id: { in: bilan.map((g) => g.compteId) } } })).map((c) => [c.id, c]));
    const lignesAN = [];
    for (const g of bilan) {
      const solde = (g._sum.debit || 0) - (g._sum.credit || 0);
      if (solde === 0) continue;
      lignesAN.push({
        compteNumero: comptesBilan.get(g.compteId).numero, tiersType: g.tiersType || undefined, tiersId: g.tiersId || undefined,
        debit: solde > 0 ? solde : 0, credit: solde < 0 ? -solde : 0, libelle: 'À-nouveau',
      });
    }
    if (lignesAN.length >= 2) {
      resume.ecritureANouveaux = (await this.compta.creerEcriture({
        journalCode: 'AN', dateEcriture: suivant.dateDebut, libelle: `À-nouveaux ${suivant.libelle}`, lignes: lignesAN,
        origine: 'ouverture', source: { type: 'ouverture', id: suivant.id, role: 'bilan' }, utilisateurId, valider: true,
      })).numeroPiece;
    }

    // Verrouillage définitif
    await this.prisma.comptaPeriode.updateMany({ where: { exerciceId: exercice.id }, data: { statut: 'verrouillee' } });
    const clos = await this.prisma.comptaExercice.update({ where: { id: exercice.id }, data: { statut: 'cloture', dateCloture: new Date() } });
    await this.compta._enqueue('compta_exercices', 'UPDATE', clos);
    for (const p of await this.prisma.comptaPeriode.findMany({ where: { exerciceId: exercice.id } })) await this.compta._enqueue('compta_periodes', 'UPDATE', p);
    const params = await this.prisma.comptaParametres.update({ where: { id: 1 }, data: { exerciceDefautId: suivant.id } });
    await this.compta._enqueue('compta_parametres', 'UPDATE', params);
    resume.cloture = true;
    return resume;
  }

  // ───────────────────────────── Rapprochement bancaire ─────────────────────────────

  /**
   * Pointage d'un compte de trésorerie (banque, mobile money) contre un relevé : les lignes pointées reçoivent le code
   * « RB » + date du relevé. L'écart est la différence entre le solde du relevé et le solde des lignes pointées.
   */
  async etatRapprochement({ compteNumero = '521', dateReleve, soldeReleve } = {}) {
    const compte = await this.prisma.comptaCompte.findUnique({ where: { numero: String(compteNumero) } });
    if (!compte || compte.classe !== 5) throw new ComptaError('Choisissez un compte de trésorerie (classe 5)', 404);
    const jour = jourUtc(dateReleve || new Date(), 'Date du relevé');
    const lignes = await this.prisma.comptaLigne.findMany({
      where: { compteId: compte.id, ecriture: { statut: { in: STATUTS }, dateEcriture: { lte: jour } } },
      include: { ecriture: { select: { dateEcriture: true, numeroPiece: true, libelle: true } } },
      orderBy: [{ ecriture: { dateEcriture: 'asc' } }, { id: 'asc' }],
    });
    const formater = (l) => ({ id: l.id, date: l.ecriture.dateEcriture, numeroPiece: l.ecriture.numeroPiece, libelle: l.libelle || l.ecriture.libelle, debit: l.debit, credit: l.credit, pointage: l.lettrage });
    const pointee = (l) => {
      const m = /^RB(\d{8})$/.exec(l.lettrage || '');
      return Boolean(m) && m[1] <= jour.toISOString().slice(0, 10).replace(/-/g, '');
    };
    const pointees = lignes.filter(pointee);
    const enAttente = lignes.filter((l) => !pointee(l));
    const net = (ls) => ls.reduce((s, l) => s + l.debit - l.credit, 0);
    const soldeComptable = net(lignes);
    const soldePointe = net(pointees);
    const demande = soldeReleve === undefined || soldeReleve === null || soldeReleve === '' ? null : Number(soldeReleve);
    return {
      compte: { numero: compte.numero, libelle: compte.libelle }, dateReleve: jour,
      soldeComptable, soldePointe, soldeReleve: demande, ecart: demande === null ? null : demande - soldePointe,
      rapproche: demande !== null && demande === soldePointe,
      enAttente: enAttente.map(formater), pointees: pointees.map(formater),
    };
  }

  async pointer({ ligneIds = [], dateReleve } = {}) {
    const ids = [...new Set(ligneIds.map(Number))];
    if (ids.length === 0) throw new ComptaError('Sélectionnez au moins une ligne');
    const jour = jourUtc(dateReleve, 'Date du relevé');
    const lignes = await this.prisma.comptaLigne.findMany({ where: { id: { in: ids } }, include: { compte: true, ecriture: { select: { statut: true } } } });
    if (lignes.length !== ids.length) throw new ComptaError('Ligne introuvable', 404);
    if (lignes.some((l) => l.compte.classe !== 5)) throw new ComptaError('Seules les lignes de comptes de trésorerie se pointent');
    if (lignes.some((l) => !STATUTS.includes(l.ecriture.statut))) throw new ComptaError('Seules les lignes d\'écritures validées se pointent');
    if (lignes.some((l) => l.lettrage)) throw new ComptaError('Une ligne est déjà pointée', 409, 'DEJA_POINTEE');
    const code = `RB${jour.toISOString().slice(0, 10).replace(/-/g, '')}`;
    await this.prisma.comptaLigne.updateMany({ where: { id: { in: ids } }, data: { lettrage: code } });
    await this._enqueueLignes(ids);
    return { code, lignes: ids.length };
  }

  async depointer({ ligneIds = [] } = {}) {
    const ids = [...new Set(ligneIds.map(Number))];
    const lignes = await this.prisma.comptaLigne.findMany({ where: { id: { in: ids }, lettrage: { startsWith: 'RB' } } });
    if (lignes.length === 0) throw new ComptaError('Aucune ligne pointée parmi la sélection', 404);
    await this.prisma.comptaLigne.updateMany({ where: { id: { in: lignes.map((l) => l.id) } }, data: { lettrage: null } });
    await this._enqueueLignes(lignes.map((l) => l.id));
    return { lignes: lignes.length };
  }

  async _enqueueLignes(ids) {
    for (const l of await this.prisma.comptaLigne.findMany({ where: { id: { in: ids } } })) await this.compta._enqueue('compta_lignes', 'UPDATE', l);
  }
}

module.exports = { ClotureService, regles };
