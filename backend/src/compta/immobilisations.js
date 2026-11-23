/**
 * Immobilisations et amortissements (phase 4).
 *
 * Amortissement LINÉAIRE au mois près : le mois d'acquisition compte en entier. Le cumul à une date est
 * toujours arrondi au franc sur le cumul (jamais sur chaque dotation), donc la somme des dotations d'un
 * exercice redonne exactement l'écart des cumuls. [À VALIDER] : mode de calcul (prorata en jours, dégressif...)
 * et durées d'usage à confirmer avec un expert-comptable.
 *
 * Les dotations d'un exercice sont rapprochées comme les autres écritures automatiques (voir moteur-auto.js) :
 * relancer ne change rien, et une modification de l'immobilisation produit l'écriture de régularisation.
 */
const { ComptaError, jourUtc } = require('./compta-service');
const { jourComptable } = require('./moteur-auto');

const JOUR_MS = 24 * 3600 * 1000;

/** Nombre de mois, du mois de `debut` à celui de `fin` inclus (0 si fin est avant le mois de début) */
function moisInclus(debut, fin) {
  const n = (fin.getUTCFullYear() * 12 + fin.getUTCMonth()) - (debut.getUTCFullYear() * 12 + debut.getUTCMonth()) + 1;
  return Math.max(0, n);
}

/** Amortissement cumulé à une date (jusqu'à la fin du mois de cette date) */
function amortissementCumule(immo, date) {
  const base = immo.valeur - (immo.valeurResiduelle || 0);
  if (base <= 0 || immo.dureeMois <= 0) return 0;
  const n = moisInclus(immo.dateAcquisition, date);
  if (n <= 0) return 0;
  return Math.min(base, Math.round((base * n) / immo.dureeMois));
}

/** Compte d'amortissement par défaut : 2183 → 28183, 245 → 2845 */
const compteAmortDefaut = (numero) => `28${String(numero).slice(1)}`;

class ImmobilisationService {
  constructor(prisma, comptaService, moteurAuto) {
    this.prisma = prisma;
    this.compta = comptaService;
    this.moteur = moteurAuto;
  }

  async _enqueue(operation, immo) {
    if (this.compta.syncService) await this.compta._enqueue('compta_immobilisations', operation, immo);
  }

  async lister() {
    const liste = await this.prisma.comptaImmobilisation.findMany({ orderBy: [{ dateAcquisition: 'asc' }, { id: 'asc' }] });
    const aujourdhui = jourUtc(new Date());
    return liste.map((i) => {
      const reference = i.dateCession && i.dateCession < aujourdhui ? i.dateCession : aujourdhui;
      const cumul = amortissementCumule(i, reference);
      return { ...i, amortissementCumule: cumul, valeurNette: i.valeur - cumul };
    });
  }

  async creer({ libelle, compteNumero, compteAmortNumero, compteDotationNumero, dateAcquisition, valeur, valeurResiduelle = 0, dureeMois, boutiqueId, utilisateurId } = {}) {
    libelle = String(libelle || '').trim();
    if (!libelle) throw new ComptaError('Le libellé est obligatoire');
    compteNumero = String(compteNumero || '').trim();
    if (!/^2[1-7]\d*$/.test(compteNumero)) throw new ComptaError('Le compte d\'immobilisation doit être un compte 21 à 27');
    valeur = Number(valeur); valeurResiduelle = Number(valeurResiduelle || 0); dureeMois = Number(dureeMois);
    if (!Number.isInteger(valeur) || valeur <= 0) throw new ComptaError('La valeur doit être un entier positif (FCFA)');
    if (!Number.isInteger(valeurResiduelle) || valeurResiduelle < 0 || valeurResiduelle >= valeur) throw new ComptaError('Valeur résiduelle invalide');
    if (!Number.isInteger(dureeMois) || dureeMois < 1 || dureeMois > 600) throw new ComptaError('La durée d\'amortissement doit être de 1 à 600 mois');

    const compte = await this.prisma.comptaCompte.findUnique({ where: { numero: compteNumero } });
    if (!compte) throw new ComptaError(`Le compte ${compteNumero} n'existe pas dans le plan comptable`, 404);
    const amort = String(compteAmortNumero || compteAmortDefaut(compteNumero));
    if (!(await this.prisma.comptaCompte.findUnique({ where: { numero: amort } }))) {
      await this.compta.creerCompte({ numero: amort, libelle: `Amortissements - ${compte.libelle}`, nature: 'actif', sens: 'credit' });
    }
    const dotation = String(compteDotationNumero || '681');
    if (!(await this.prisma.comptaCompte.findUnique({ where: { numero: dotation } }))) throw new ComptaError(`Le compte de dotation ${dotation} n'existe pas`, 404);

    const immo = await this.prisma.comptaImmobilisation.create({
      data: {
        libelle, compteNumero, compteAmortNumero: amort, compteDotationNumero: dotation,
        dateAcquisition: jourUtc(dateAcquisition, 'Date d\'acquisition'), valeur, valeurResiduelle, dureeMois,
        boutiqueId: boutiqueId ? Number(boutiqueId) : null,
      },
    });
    await this._enqueue('INSERT', immo);
    await this.compta.tracer('immobilisation.creee', { utilisateurId, entiteType: 'immobilisation', entiteId: immo.id, details: { libelle, valeur, dureeMois } });
    return immo;
  }

  /** Plan d'amortissement par année civile */
  async plan(id) {
    const immo = await this.prisma.comptaImmobilisation.findUnique({ where: { id: Number(id) } });
    if (!immo) throw new ComptaError('Immobilisation introuvable', 404);
    const fin = immo.dateCession || new Date(Date.UTC(immo.dateAcquisition.getUTCFullYear() + Math.ceil(immo.dureeMois / 12) + 1, 11, 31));
    const lignes = [];
    let precedent = 0;
    for (let an = immo.dateAcquisition.getUTCFullYear(); an <= fin.getUTCFullYear(); an++) {
      const cumul = amortissementCumule(immo, new Date(Date.UTC(an, 11, 31) > fin ? fin : Date.UTC(an, 11, 31)));
      lignes.push({ annee: an, dotation: cumul - precedent, cumul, valeurNette: immo.valeur - cumul });
      precedent = cumul;
      if (cumul >= immo.valeur - immo.valeurResiduelle && an >= immo.dateAcquisition.getUTCFullYear()) break;
    }
    return { immobilisation: immo, lignes };
  }

  /** Dotations de l'exercice : une écriture (régularisée si besoin) par immobilisation */
  async dotationsExercice({ exerciceId } = {}) {
    const exercice = await this.prisma.comptaExercice.findUnique({ where: { id: Number(exerciceId) } });
    if (!exercice) throw new ComptaError('Exercice introuvable', 404);
    const params = await this.compta.getParametres();
    if (!params.ouvertureValidee || !params.dateOuverture) throw new ComptaError('Enregistrez d\'abord l\'ouverture de la comptabilité', 409);
    const ouverture = jourComptable(params.dateOuverture);
    const veille = new Date(exercice.dateDebut.getTime() - JOUR_MS);
    const deja = await this.moteur._dejaComptabilise('amortissement');
    const immos = await this.prisma.comptaImmobilisation.findMany({ where: { dateAcquisition: { lte: exercice.dateFin } }, orderBy: { id: 'asc' } });

    const resultat = { exercice: { id: exercice.id, libelle: exercice.libelle }, ecritures: 0, dotations: [], erreurs: [] };
    for (const immo of immos) {
      const refFin = immo.dateCession && immo.dateCession < exercice.dateFin ? immo.dateCession : exercice.dateFin;
      const refDebut = immo.dateCession && immo.dateCession < veille ? immo.dateCession : veille;
      const dotation = Math.max(0, amortissementCumule(immo, refFin) - amortissementCumule(immo, refDebut));
      resultat.dotations.push({ immobilisationId: immo.id, libelle: immo.libelle, dotation });
      try {
        const r = await this.moteur.rapprocherDocument({
          sourceType: 'amortissement', sourceId: exercice.id * 1000000 + immo.id, deja, ouverture,
          journalCode: 'OD', dateDocument: refFin, dateModification: null,
          libelle: `Dotation aux amortissements ${exercice.libelle} — ${immo.libelle}`, boutiqueId: immo.boutiqueId,
          cible: dotation > 0 ? [
            { compteNumero: immo.compteDotationNumero, net: dotation },
            { compteNumero: immo.compteAmortNumero, net: -dotation },
          ] : [],
        });
        if (r === 'cree') resultat.ecritures += 1;
      } catch (e) {
        resultat.erreurs.push({ immobilisationId: immo.id, message: e.message, code: e.code || null });
      }
    }
    return resultat;
  }

  /**
   * Cession : arrête l'amortissement à la date de cession, sort l'immobilisation (valeur d'origine, amortissements
   * cumulés, valeur nette comptable en charge) et constate le prix de vente en produit de cession encaissé en caisse.
   */
  async ceder(id, { date, prix = 0, utilisateurId } = {}) {
    const immo = await this.prisma.comptaImmobilisation.findUnique({ where: { id: Number(id) } });
    if (!immo) throw new ComptaError('Immobilisation introuvable', 404);
    if (immo.statut === 'cedee') throw new ComptaError('Cette immobilisation est déjà cédée', 409, 'DEJA_CEDEE');
    const jour = jourUtc(date, 'Date de cession');
    if (jour < immo.dateAcquisition) throw new ComptaError('La cession ne peut précéder l\'acquisition');
    prix = Number(prix || 0);
    if (!Number.isInteger(prix) || prix < 0) throw new ComptaError('Le prix de cession doit être un entier positif ou nul');

    const maj = await this.prisma.comptaImmobilisation.update({ where: { id: immo.id }, data: { statut: 'cedee', dateCession: jour, prixCession: prix } });
    // La dotation de l'exercice jusqu'à la date de cession doit être comptabilisée avant la sortie
    const contexte = await this.compta._exerciceEtPeriode(this.prisma, jour);
    await this.dotationsExercice({ exerciceId: contexte.exercice.id });

    const cumul = amortissementCumule(maj, jour);
    const vnc = immo.valeur - cumul;
    const lignes = [
      { compteNumero: immo.compteAmortNumero, debit: cumul },
      { compteNumero: '81', debit: vnc },
      { compteNumero: immo.compteNumero, credit: immo.valeur },
      ...(prix > 0 ? [{ compteNumero: '571', debit: prix }, { compteNumero: '82', credit: prix }] : []),
    ].filter((l) => (l.debit || 0) > 0 || (l.credit || 0) > 0);
    const ecriture = await this.compta.creerEcriture({
      journalCode: 'OD', dateEcriture: jour, libelle: `Cession ${immo.libelle}`, lignes, origine: 'auto',
      source: { type: 'cession', id: immo.id, role: 'sortie' }, utilisateurId, valider: true,
    });
    await this._enqueue('UPDATE', maj);
    await this.compta.tracer('immobilisation.cedee', { utilisateurId, entiteType: 'immobilisation', entiteId: immo.id, details: { prix, valeurNetteComptable: vnc } });
    return { immobilisation: maj, ecriture, amortissementCumule: cumul, valeurNetteComptable: vnc, plusOuMoinsValue: prix - vnc };
  }
}

module.exports = { ImmobilisationService, amortissementCumule, moisInclus, compteAmortDefaut };
