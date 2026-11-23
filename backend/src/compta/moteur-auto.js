/**
 * Moteur d'écritures automatiques (phase 2) — voir docs/CONCEPTION_COMPTABILITE_OHADA.md §6 et §7.
 *
 * PRINCIPE : on ne rejoue pas l'historique des opérations (une vente peut être modifiée, partiellement
 * annulée, réglée par plusieurs chemins...). Pour chaque DOCUMENT source (vente, commande, dépense...) on
 * calcule la situation comptable qu'il doit produire AUJOURD'HUI (« cible » : un solde net par compte et par
 * tiers), on la compare à ce qui est déjà comptabilisé pour ce document, et on enregistre UNIQUEMENT la
 * différence. Conséquences :
 *   - idempotent : relancer ne change rien tant que le document ne bouge pas ;
 *   - une annulation ou une correction produit son écriture inverse sans logique propre à chaque cas ;
 *   - l'ordre dans lequel les postes ont synchronisé leurs données n'a pas d'importance.
 *
 * Ne s'exécute que sur le poste de référence (voir peutGenerer) : les autres reçoivent les écritures
 * par synchronisation. Ignore tout ce qui est antérieur à la date d'ouverture de la comptabilité.
 */
const installation = require('../utils/installation');
const regles = require('./regles-imputation.json');
const { STATUTS_COMPTABILISES: STATUTS } = require('./compta-service');

const DECALAGE_DOUALA_MS = 60 * 60 * 1000; // UTC+1 (Cameroun) : un jour comptable = un jour local
const C = regles.comptes;

/** Jour comptable (minuit UTC du jour local camerounais) d'un instant */
function jourComptable(date) {
  const d = new Date(new Date(date).getTime() + DECALAGE_DOUALA_MS);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

const entier = (x) => Math.round(Number(x) || 0);

/** Poste habilité à générer : le poste 1 (ou sans identité de poste : serveur cloud, mode autonome) */
function peutGenerer() {
  const id = installation.getInstallationId();
  return !id || id === 1;
}

const sansAccent = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/** Compte de charge d'une catégorie de dépense (surcharge par catégorie, sinon mots-clés, sinon compte par défaut) */
function compteDepense(categorie) {
  const par = regles.depenses.parCategorie || {};
  if (categorie && par[categorie.nom]) return par[categorie.nom];
  const texte = sansAccent(`${categorie?.nom || ''} ${categorie?.displayName || ''}`);
  for (const [mot, compte] of regles.depenses.motsCles) if (texte.includes(sansAccent(mot))) return compte;
  return regles.depenses.compteParDefaut;
}

/** Agrège des lignes {compteNumero, tiersType, tiersId, net} (net = débit − crédit) en supprimant les nuls */
function agreger(lignes) {
  const m = new Map();
  for (const l of lignes) {
    const cle = `${l.compteNumero}|${l.tiersType || ''}|${l.tiersId || ''}`;
    const e = m.get(cle) || { compteNumero: l.compteNumero, tiersType: l.tiersType || null, tiersId: l.tiersId || null, net: 0 };
    e.net += entier(l.net);
    m.set(cle, e);
  }
  return [...m.values()].filter((l) => l.net !== 0);
}

// ───────────────────────────── Cibles par type de document ─────────────────────────────

/** Vente : chiffre d'affaires et TVA, créance client, avance consommée, encaissement en caisse */
function cibleVente(v) {
  if (v.statut !== 'terminee') return [];
  const total = Math.max(0, entier(v.montantTotal));
  const tva = Math.min(total, Math.max(0, entier(v.montantTva)));
  const ht = total - tva;
  const paye = Math.min(total, Math.max(0, entier(v.montantPaye)));
  const avance = Math.min(paye, Math.max(0, entier(v.avanceUtilisee)));
  const caisse = paye - avance;
  const client = v.clientId ? { tiersType: 'client', tiersId: v.clientId } : {};
  return agreger([
    { compteNumero: C.ventesMarchandises, net: -ht },
    { compteNumero: C.tvaFacturee, net: -tva },
    { compteNumero: C.clients, net: total - paye, ...client },
    { compteNumero: C.avancesClients, net: avance, ...client },
    { compteNumero: C.caisse, net: caisse },
  ]);
}

/** Commande fournisseur : achats reçus, dette (ou avance versée) et règlements déjà effectués */
function cibleCommande(c) {
  if (c.statut === 'annulee') return [];
  const valeur = entier(c.details.reduce((s, d) => s + (Number(d.quantiteRecue) || 0) * (Number(d.coutUnitaire) || 0), 0));
  const paye = Math.max(0, entier(c.montantPaye));
  if (valeur === 0 && paye === 0) return [];
  const dette = Math.max(0, valeur - paye);
  const avance = Math.max(0, paye - valeur);
  const tiers = { tiersType: 'fournisseur', tiersId: c.fournisseurId };
  return agreger([
    { compteNumero: C.achatsMarchandises, net: valeur },
    { compteNumero: C.fournisseurs, net: -dette, ...tiers },
    { compteNumero: C.avancesFournisseurs, net: avance, ...tiers },
    { compteNumero: C.caisse, net: -paye },
  ]);
}

function cibleDepense(m, categorie) {
  if (m.statut === 'annule') return [];
  const montant = Math.max(0, entier(m.montant));
  return agreger([
    { compteNumero: compteDepense(categorie), net: montant },
    { compteNumero: C.caisse, net: -montant },
  ]);
}

function cibleEcartCaisse(s) {
  const ecart = entier(s.ecart);
  if (!s.dateFermeture || ecart === 0) return [];
  return ecart < 0
    ? agreger([{ compteNumero: C.ecartCaisseNegatif, net: -ecart }, { compteNumero: C.caisse, net: ecart }])
    : agreger([{ compteNumero: C.caisse, net: ecart }, { compteNumero: C.ecartCaissePositif, net: -ecart }]);
}

/** Argent versé en caisse par un client sans lien avec une vente (dette, dépôt d'avance) */
function cibleCaisseClient(montant, compteCredite, clientId) {
  const m = Math.max(0, entier(montant));
  return agreger([{ compteNumero: C.caisse, net: m }, { compteNumero: compteCredite, net: -m, tiersType: 'client', tiersId: clientId }]);
}

function cibleReglementFournisseur(montant, fournisseurId) {
  const m = Math.max(0, entier(montant));
  return agreger([
    { compteNumero: C.fournisseurs, net: m, tiersType: 'fournisseur', tiersId: fournisseurId },
    { compteNumero: C.caisse, net: -m },
  ]);
}

// ───────────────────────────── Moteur ─────────────────────────────

class MoteurAuto {
  constructor(prisma, comptaService) {
    this.prisma = prisma;
    this.compta = comptaService;
    this.dernierRapport = null;
    this._enCours = false;
    this._timer = null;
  }

  /** Net (débit − crédit) déjà comptabilisé, par document source puis par compte/tiers */
  async _dejaComptabilise(sourceType) {
    const numeros = new Map((await this.prisma.comptaCompte.findMany({ select: { id: true, numero: true } })).map((c) => [c.id, c.numero]));
    const lignes = await this.prisma.comptaLigne.findMany({
      where: { ecriture: { sourceType, statut: { in: STATUTS } } },
      select: { compteId: true, tiersType: true, tiersId: true, debit: true, credit: true, ecriture: { select: { sourceId: true } } },
    });
    const cumul = new Map();
    for (const l of lignes) {
      const cle = `${l.ecriture.sourceId}|${l.compteId}|${l.tiersType || ''}|${l.tiersId || ''}`;
      const e = cumul.get(cle) || { sourceId: l.ecriture.sourceId, compteNumero: numeros.get(l.compteId), tiersType: l.tiersType || null, tiersId: l.tiersId || null, net: 0 };
      e.net += l.debit - l.credit;
      cumul.set(cle, e);
    }
    const parDoc = new Map();
    for (const e of cumul.values()) {
      if (e.net === 0) continue;
      const liste = parDoc.get(e.sourceId) || [];
      liste.push({ compteNumero: e.compteNumero, tiersType: e.tiersType, tiersId: e.tiersId, net: e.net });
      parDoc.set(e.sourceId, liste);
    }
    return parDoc;
  }

  /**
   * Met la comptabilité d'UN document en conformité avec sa cible.
   * @returns {Promise<'cree'|'inchange'>}
   */
  async rapprocherDocument({ sourceType, sourceId, journalCode, dateDocument, dateModification, libelle, boutiqueId, cible, deja, ouverture }) {
    const jourDoc = jourComptable(dateDocument);
    if (jourDoc < ouverture) return 'inchange'; // antérieur à l'ouverture : hors comptabilité

    // Différence cible − déjà comptabilisé
    const ecarts = new Map();
    const ajouter = (l, signe) => {
      const cle = `${l.compteNumero}|${l.tiersType || ''}|${l.tiersId || ''}`;
      const e = ecarts.get(cle) || { compteNumero: l.compteNumero, tiersType: l.tiersType, tiersId: l.tiersId, net: 0 };
      e.net += signe * l.net;
      ecarts.set(cle, e);
    };
    for (const l of cible) ajouter(l, 1);
    const existant = deja.get(sourceId) || [];
    for (const l of existant) ajouter(l, -1);
    const lignes = [...ecarts.values()].filter((l) => l.net !== 0);
    if (lignes.length === 0) return 'inchange';

    const somme = lignes.reduce((s, l) => s + l.net, 0);
    if (somme !== 0) throw new Error(`cible déséquilibrée (${somme}) pour ${sourceType} ${sourceId}`);

    // Première écriture : à la date du document. Correction ultérieure : à la date de modification du document
    // (jamais avant lui), ou aujourd'hui si cette période est verrouillée.
    const premiere = existant.length === 0;
    let date = jourDoc;
    if (!premiere) {
      const modif = dateModification ? jourComptable(dateModification) : jourComptable(new Date());
      date = modif > jourDoc ? modif : jourDoc;
    }

    const nbExistantes = await this.prisma.comptaEcriture.count({ where: { sourceType, sourceId } });
    const creer = (dateEcriture) => this.compta.creerEcriture({
      journalCode,
      dateEcriture,
      libelle: premiere ? libelle : `${libelle} (régularisation)`,
      lignes: lignes.map((l) => ({
        compteNumero: l.compteNumero,
        tiersType: l.tiersType || undefined,
        tiersId: l.tiersId || undefined,
        debit: l.net > 0 ? l.net : 0,
        credit: l.net < 0 ? -l.net : 0,
        boutiqueId: boutiqueId || undefined,
      })),
      boutiqueId: boutiqueId || undefined,
      origine: 'auto',
      source: { type: sourceType, id: sourceId, role: `r${nbExistantes + 1}` },
      valider: true,
    });
    try {
      await creer(date);
    } catch (e) {
      // Période verrouillée : la correction est datée d'aujourd'hui, dans la première période ouverte
      if (e.code === 'PERIODE_VERROUILLEE' && !premiere) await creer(jourComptable(new Date()));
      else throw e;
    }
    return 'cree';
  }

  async _traiter(rapport, type, documents, extraire) {
    const deja = await this._dejaComptabilise(type);
    for (const doc of documents) {
      const bilan = (rapport.parType[type] ||= { examines: 0, ecritures: 0, erreurs: 0 });
      bilan.examines += 1;
      try {
        const resultat = await this.rapprocherDocument({ sourceType: type, deja, ouverture: rapport.ouverture, ...extraire(doc) });
        if (resultat === 'cree') bilan.ecritures += 1;
      } catch (e) {
        bilan.erreurs += 1;
        rapport.erreurs.push({ type, id: doc.id, message: e.message, code: e.code || null });
      }
    }
  }

  /**
   * Passe complète : rattrape tous les documents depuis la date d'ouverture.
   * @param {{ force?: boolean }} opts force : ignore le contrôle « poste de référence »
   */
  async generer({ force = false } = {}) {
    if (this._enCours) return { ignore: 'génération déjà en cours' };
    if (!force && !peutGenerer()) return { ignore: 'ce poste n\'est pas le poste de référence' };
    this._enCours = true;
    const debut = Date.now();
    try {
      const params = await this.compta.getParametres();
      if (!params.ouvertureValidee || !params.dateOuverture) return { ignore: 'ouverture de la comptabilité non enregistrée' };
      const ouverture = jourComptable(params.dateOuverture);
      const depuis = new Date(ouverture.getTime() - 2 * 24 * 3600 * 1000);
      const rapport = { ouverture, parType: {}, erreurs: [], debut: new Date(debut) };
      const p = this.prisma;

      // Ventes
      await this._traiter(rapport, 'vente', await p.vente.findMany({ where: { dateVente: { gte: depuis } }, orderBy: { id: 'asc' } }), (v) => ({
        sourceId: v.id, journalCode: regles.journaux.ventes, dateDocument: v.dateVente, dateModification: v.dateModification,
        libelle: `Vente ${v.numeroVente}`, boutiqueId: v.boutiqueId, cible: cibleVente(v),
      }));

      // Commandes fournisseurs
      await this._traiter(rapport, 'achat', await p.commandeApprovisionnement.findMany({ where: { dateCommande: { gte: depuis } }, include: { details: true }, orderBy: { id: 'asc' } }), (c) => ({
        sourceId: c.id, journalCode: regles.journaux.achats, dateDocument: c.dateCommande, dateModification: c.dateModification,
        libelle: `Commande ${c.numeroCommande}`, boutiqueId: c.boutiqueId, cible: cibleCommande(c),
      }));

      // Dépenses
      const categories = new Map((await p.movementCategory.findMany()).map((c) => [c.id, c]));
      await this._traiter(rapport, 'depense', await p.financialMovement.findMany({ where: { date: { gte: depuis } }, orderBy: { id: 'asc' } }), (m) => ({
        sourceId: m.id, journalCode: regles.journaux.caisse, dateDocument: m.date, dateModification: m.dateModification,
        libelle: `Dépense ${m.reference} — ${m.description}`, boutiqueId: m.boutiqueId, cible: cibleDepense(m, categories.get(m.categorieId)),
      }));

      // Écarts de caisse à la fermeture des sessions
      await this._traiter(rapport, 'ecart_caisse', await p.cashSession.findMany({ where: { dateFermeture: { gte: depuis } }, orderBy: { id: 'asc' } }), (s) => ({
        sourceId: s.id, journalCode: regles.journaux.caisse, dateDocument: s.dateFermeture, dateModification: s.dateModification,
        libelle: `Écart de caisse — session ${s.id}`, boutiqueId: s.boutiqueId, cible: cibleEcartCaisse(s),
      }));

      // Paiements directs d'un client (hors vente) : mouvement de caisse « paiement_client »
      const entrees = await p.cashMovement.findMany({ where: { type: 'entree', dateCreation: { gte: depuis } }, orderBy: { id: 'asc' } });
      const paiementsClients = [];
      for (const m of entrees) {
        let meta = null;
        try { meta = m.metadata ? JSON.parse(m.metadata) : null; } catch { meta = null; }
        if (meta && meta.categorie === 'paiement_client' && meta.clientId) paiementsClients.push({ m, clientId: Number(meta.clientId) });
      }
      await this._traiter(rapport, 'reglement_client', paiementsClients.map((x) => ({ id: x.m.id, ...x })), (x) => ({
        sourceId: x.m.id, journalCode: regles.journaux.caisse, dateDocument: x.m.dateCreation, dateModification: null,
        libelle: x.m.description || `Règlement client ${x.clientId}`, boutiqueId: x.m.boutiqueId,
        cible: cibleCaisseClient(x.m.montant, C.clients, x.clientId),
      }));

      // Mouvements du compte client : dépôts d'avance (hors paiement de dette, déjà porté par les ventes)
      const comptesClients = new Map((await p.compteClient.findMany()).map((c) => [c.id, c.clientId]));
      const depots = (await p.transactionCompte.findMany({
        where: { typeCompte: 'client', typeTransaction: 'depot', dateTransaction: { gte: depuis } }, orderBy: { id: 'asc' },
      })).filter((t) => comptesClients.has(t.compteId));
      await this._traiter(rapport, 'depot_client', depots, (t) => ({
        sourceId: t.id, journalCode: regles.journaux.caisse, dateDocument: t.dateTransaction, dateModification: null,
        libelle: t.description || 'Dépôt client', boutiqueId: t.boutiqueId,
        cible: cibleCaisseClient(t.montant, C.avancesClients, comptesClients.get(t.compteId)),
      }));

      // Règlements fournisseurs non rattachés à une commande (ceux d'une commande sont dans montantPaye)
      const comptesFournisseurs = new Map((await p.compteFournisseur.findMany()).map((c) => [c.id, c.fournisseurId]));
      const reglements = (await p.transactionCompte.findMany({
        where: { typeCompte: 'fournisseur', typeTransaction: { in: ['paiement', 'credit'] }, dateTransaction: { gte: depuis } }, orderBy: { id: 'asc' },
      })).filter((t) => comptesFournisseurs.has(t.compteId) && t.referenceType !== 'approvisionnement');
      await this._traiter(rapport, 'reglement_fournisseur', reglements, (t) => ({
        sourceId: t.id, journalCode: regles.journaux.caisse, dateDocument: t.dateTransaction, dateModification: null,
        libelle: t.description || 'Règlement fournisseur', boutiqueId: t.boutiqueId,
        cible: cibleReglementFournisseur(t.montant, comptesFournisseurs.get(t.compteId)),
      }));

      rapport.duree = Date.now() - debut;
      rapport.fin = new Date();
      this.dernierRapport = rapport;
      return rapport;
    } finally {
      this._enCours = false;
    }
  }

  /** Lance une génération périodique (poste de référence uniquement) */
  demarrer(intervalleMs = 5 * 60 * 1000) {
    if (this._timer) return;
    this._timer = setInterval(() => {
      this.generer().catch((e) => console.warn('⚠️  [Compta] génération automatique :', e.message));
    }, intervalleMs);
    if (this._timer.unref) this._timer.unref();
  }

  arreter() {
    if (this._timer) clearInterval(this._timer);
    this._timer = null;
  }

  // ───────────────────────────── Contrôles de cohérence ─────────────────────────────

  /**
   * Compare les soldes tenus en comptabilité aux soldes « de gestion » : comptes clients, comptes
   * fournisseurs et caisses. Un écart signale une opération que le moteur ne sait pas (encore) traduire.
   */
  async controles() {
    const comptes = new Map((await this.prisma.comptaCompte.findMany({ select: { id: true, numero: true } })).map((x) => [x.numero, x.id]));
    // Net (débit − crédit) d'un compte, par tiers (null = tous les tiers confondus)
    const net = async (numero, tiersType) => {
      const groupes = await this.prisma.comptaLigne.groupBy({
        by: ['tiersId'],
        where: { compteId: comptes.get(numero), ecriture: { statut: { in: STATUTS } }, ...(tiersType ? { tiersType } : {}) },
        _sum: { debit: true, credit: true },
      });
      return new Map(groupes.map((g) => [g.tiersId === null ? null : Number(g.tiersId), (g._sum.debit || 0) - (g._sum.credit || 0)]));
    };

    // Clients : position comptable = créance (411, débit) − avance (4191, crédit) ; gestion : −solde
    const [creances, avances] = [await net(C.clients, 'client'), await net(C.avancesClients, 'client')];
    const clients = [];
    for (const cc of await this.prisma.compteClient.findMany({ include: { client: { select: { nom: true, prenom: true } } } })) {
      const comptable = (creances.get(cc.clientId) || 0) + (avances.get(cc.clientId) || 0);
      const gestion = -entier(cc.soldeActuel);
      if (comptable !== gestion) {
        clients.push({ clientId: cc.clientId, nom: `${cc.client?.nom || ''} ${cc.client?.prenom || ''}`.trim(), comptabilite: comptable, gestion, ecart: comptable - gestion });
      }
    }

    // Fournisseurs : position comptable = dette (401, crédit) − avance versée (4091, débit) ; gestion : solde (dette > 0)
    const [dettes, avancesF] = [await net(C.fournisseurs, 'fournisseur'), await net(C.avancesFournisseurs, 'fournisseur')];
    const fournisseurs = [];
    for (const cf of await this.prisma.compteFournisseur.findMany({ include: { fournisseur: { select: { nom: true } } } })) {
      const comptable = -((dettes.get(cf.fournisseurId) || 0) + (avancesF.get(cf.fournisseurId) || 0));
      const gestion = entier(cf.soldeActuel);
      if (comptable !== gestion) {
        fournisseurs.push({ fournisseurId: cf.fournisseurId, nom: cf.fournisseur?.nom || '', comptabilite: comptable, gestion, ecart: comptable - gestion });
      }
    }

    // Caisse : compte 571 (tous tiers confondus) contre la somme des caisses
    const caisseComptable = [...(await net(C.caisse)).values()].reduce((x, y) => x + y, 0);
    const caisseGestion = entier((await this.prisma.cashRegister.aggregate({ _sum: { soldeActuel: true } }))._sum.soldeActuel);

    return {
      clients,
      fournisseurs,
      caisse: { comptabilite: caisseComptable, gestion: caisseGestion, ecart: caisseComptable - caisseGestion },
      coherent: clients.length === 0 && fournisseurs.length === 0 && caisseComptable === caisseGestion,
    };
  }
}

module.exports = {
  MoteurAuto, peutGenerer, jourComptable, compteDepense,
  cibleVente, cibleCommande, cibleDepense, cibleEcartCaisse, cibleCaisseClient, cibleReglementFournisseur,
};
