/**
 * Routes de la comptabilité SYSCOHADA (phase 1) — /api/<version>/compta
 *
 * Droits (module « accounting » dans les privilèges du rôle ; un administrateur a tout) :
 *   READ     consulter plan, écritures, journaux, grand livre, balance
 *   CREATE   saisir, modifier et supprimer des brouillons, créer des comptes
 *   VALIDATE valider et contre-passer des écritures
 *   CLOSE    verrouiller / rouvrir une période
 *   MANAGE   paramètres (régime, mode, TVA), exercices, assistant d'ouverture
 */
const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO } = require('../dto');
const { ComptaError } = require('../compta/compta-service');
const { tableaux, enCsv, enXlsx } = require('../compta/etats');

const MODULE = 'accounting';

/** Vrai si l'utilisateur est administrateur ou possède le privilège demandé sur le module comptabilité */
async function aPrivilege(prisma, user, privilege) {
  if (!user) return false;
  // Jeton de développement (voir middleware/auth.js) : jamais accepté en production
  if (user.nomUtilisateur === 'test-user' && process.env.NODE_ENV !== 'production') return true;
  const complet = await prisma.utilisateur.findUnique({ where: { id: user.id }, include: { role: true } });
  if (!complet || !complet.isActive) return false;
  if (complet.role && complet.role.isAdmin) return true;
  if (!complet.role || !complet.role.privileges) return false;
  try {
    const privileges = JSON.parse(complet.role.privileges);
    const liste = Array.isArray(privileges[MODULE]) ? privileges[MODULE] : [];
    // Toute permission comptable donne aussi la lecture
    return privilege === 'READ' ? liste.length > 0 : liste.includes(privilege);
  } catch {
    return false;
  }
}

function createComptaRouter({ authService, prisma, comptaService, moteurAuto, etatsService, immobilisationService, clotureService }) {
  const router = express.Router();
  const auth = authenticateToken(authService);

  const droit = (privilege) => async (req, res, next) => {
    try {
      if (await aPrivilege(prisma, req.user, privilege)) return next();
      return res.status(403).json(BaseResponseDTO.error('Droit insuffisant pour la comptabilité'));
    } catch (e) {
      console.error('Erreur contrôle des droits comptabilité :', e);
      return res.status(500).json(BaseResponseDTO.error('Erreur lors de la vérification des droits'));
    }
  };

  /** Enveloppe commune : succès → data ; ComptaError → statut métier ; autre → 500 */
  const gerer = (message, fn, statutSucces = 200) => async (req, res) => {
    try {
      const data = await fn(req);
      res.status(statutSucces).json(BaseResponseDTO.success(data, message));
    } catch (e) {
      if (e instanceof ComptaError) {
        return res.status(e.status).json({ success: false, message: e.message, code: e.code });
      }
      console.error(`Erreur comptabilité (${message}) :`, e);
      res.status(500).json(BaseResponseDTO.error('Erreur interne de la comptabilité'));
    }
  };

  /** Réponse d'un état : JSON par défaut, ou fichier CSV / Excel avec ?format=csv|xlsx */
  const etat = (message, calcul, nomTableau, nomFichier) => async (req, res) => {
    try {
      const data = await calcul(req);
      const format = String(req.query.format || 'json').toLowerCase();
      if (format === 'json') return res.json(BaseResponseDTO.success(data, message));
      if (format === 'tableau') return res.json(BaseResponseDTO.success(tableaux[nomTableau](data), message));
      const tableau = tableaux[nomTableau](data);
      const base = `${nomFichier}-${new Date().toISOString().slice(0, 10)}`;
      if (format === 'csv') {
        res.set({ 'Content-Type': 'text/csv; charset=utf-8', 'Content-Disposition': `attachment; filename="${base}.csv"` });
        return res.send(enCsv(tableau));
      }
      if (format === 'xlsx') {
        res.set({ 'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'Content-Disposition': `attachment; filename="${base}.xlsx"` });
        return res.send(await enXlsx(tableau));
      }
      throw new ComptaError('Format invalide (json, csv ou xlsx)');
    } catch (e) {
      if (e instanceof ComptaError) return res.status(e.status).json({ success: false, message: e.message, code: e.code });
      console.error(`Erreur comptabilité (${message}) :`, e);
      return res.status(500).json(BaseResponseDTO.error('Erreur interne de la comptabilité'));
    }
  };

  const boutique = (req) => (req.query.boutiqueId ? Number(req.query.boutiqueId) : undefined);

  // ── Paramètres et ouverture ──
  router.get('/parametres', auth, droit('READ'), gerer('Paramètres comptables', () => comptaService.getParametres()));
  router.put('/parametres', auth, droit('MANAGE'), gerer('Paramètres mis à jour', (req) => comptaService.updateParametres(req.body)));
  router.post('/ouverture', auth, droit('MANAGE'),
    gerer('Ouverture enregistrée', (req) => comptaService.enregistrerOuverture({ ...req.body, utilisateurId: req.user.id }), 201));

  // ── Plan comptable ──
  router.get('/comptes', auth, droit('READ'), gerer('Plan comptable', (req) => comptaService.listerComptes(req.query)));
  router.post('/comptes', auth, droit('CREATE'), gerer('Compte créé', (req) => comptaService.creerCompte(req.body), 201));
  router.put('/comptes/:id', auth, droit('CREATE'), gerer('Compte mis à jour', (req) => comptaService.modifierCompte(req.params.id, req.body)));

  // ── Journaux ──
  router.get('/journaux', auth, droit('READ'), gerer('Journaux', () => prisma.comptaJournal.findMany({ orderBy: { code: 'asc' } })));

  // ── Exercices et périodes ──
  router.get('/exercices', auth, droit('READ'), gerer('Exercices', () => comptaService.listerExercices()));
  router.post('/exercices', auth, droit('MANAGE'), gerer('Exercice créé', (req) => comptaService.creerExercice(req.body), 201));
  router.put('/exercices/:id/periodes/:mois', auth, droit('CLOSE'),
    gerer('Période mise à jour', (req) => comptaService.changerStatutPeriode(req.params.id, req.params.mois, req.body.statut)));

  // ── Écritures ──
  router.get('/ecritures', auth, droit('READ'), gerer('Écritures', (req) => comptaService.listerEcritures(req.query)));
  router.get('/ecritures/:id', auth, droit('READ'), gerer('Écriture', (req) => comptaService.getEcriture(req.params.id)));
  router.post('/ecritures', auth, droit('CREATE'),
    gerer('Écriture enregistrée', (req) => {
      // Champs autorisés uniquement : origine, source et contre-passation ne se choisissent pas depuis l'API
      const { journalId, journalCode, dateEcriture, libelle, lignes, boutiqueId } = req.body || {};
      return comptaService.creerEcriture({
        journalId, journalCode, dateEcriture, libelle, lignes, boutiqueId,
        origine: 'manuelle',
        valider: false,
        utilisateurId: req.user.id,
      });
    }, 201));
  router.put('/ecritures/:id', auth, droit('CREATE'), gerer('Brouillon mis à jour', (req) => {
    const { journalId, journalCode, dateEcriture, libelle, lignes } = req.body || {};
    return comptaService.modifierBrouillon(req.params.id, { journalId, journalCode, dateEcriture, libelle, lignes });
  }));
  router.delete('/ecritures/:id', auth, droit('CREATE'), gerer('Brouillon supprimé', (req) => comptaService.supprimerBrouillon(req.params.id)));
  router.post('/ecritures/:id/valider', auth, droit('VALIDATE'),
    gerer('Écriture validée', (req) => comptaService.validerEcriture(req.params.id, { utilisateurId: req.user.id })));
  router.post('/ecritures/:id/contrepasser', auth, droit('VALIDATE'),
    gerer('Écriture contre-passée', (req) => comptaService.contrepasser(req.params.id, { ...req.body, utilisateurId: req.user.id }), 201));

  // ── Écritures automatiques (poste de référence) ──
  router.post('/generer', auth, droit('MANAGE'), gerer('Génération terminée', () => {
    if (!moteurAuto) throw new ComptaError('Moteur automatique indisponible', 503);
    return moteurAuto.generer({ force: true });
  }));
  router.get('/generation', auth, droit('READ'), gerer('Dernière génération', () => (moteurAuto && moteurAuto.dernierRapport) || null));
  router.get('/controles', auth, droit('READ'), gerer('Contrôles de cohérence', () => {
    if (!moteurAuto) throw new ComptaError('Moteur automatique indisponible', 503);
    return moteurAuto.controles();
  }));

  // ── États ──
  const q = (req) => ({ exerciceId: req.query.exerciceId, dateDebut: req.query.dateDebut, dateFin: req.query.dateFin, boutiqueId: boutique(req) });
  router.get('/grand-livre', auth, droit('READ'), etat('Grand livre', (req) => comptaService.grandLivre({ ...q(req), compteNumero: req.query.compte, tiersType: req.query.tiersType, tiersId: req.query.tiersId }), 'grandLivre', 'grand-livre'));
  router.get('/balance', auth, droit('READ'), etat('Balance', (req) => comptaService.balance({ ...q(req), inclureSoldesNuls: req.query.inclureSoldesNuls === 'true' }), 'balance', 'balance'));
  router.get('/etats/journal', auth, droit('READ'), etat('Journal', (req) => etatsService.journalLignes({ ...q(req), journalCode: req.query.journalCode }), 'journal', 'journal'));
  router.get('/etats/resultat', auth, droit('READ'), etat('Compte de résultat', (req) => etatsService.compteDeResultat(q(req)), 'resultat', 'compte-de-resultat'));
  router.get('/etats/bilan', auth, droit('READ'), etat('Bilan', (req) => etatsService.bilan(q(req)), 'bilan', 'bilan'));
  router.get('/etats/tva', auth, droit('READ'), etat('Déclaration de TVA', (req) => etatsService.declarationTva({ ...q(req), annee: req.query.annee, mois: req.query.mois }), 'tva', 'tva'));
  router.get('/etats/balance-agee', auth, droit('READ'), etat('Balance âgée', (req) => etatsService.balanceAgee({ type: req.query.type, dateRef: req.query.dateRef, boutiqueId: boutique(req) }), 'balanceAgee', 'balance-agee'));
  router.get('/etats/recettes-depenses', auth, droit('READ'), etat('Livre des recettes et dépenses', (req) => etatsService.livreRecettesDepenses(q(req)), 'livreRecettesDepenses', 'recettes-depenses'));
  router.get('/resume', auth, droit('READ'), gerer('Résumé', (req) => etatsService.resume({ boutiqueId: boutique(req), annee: req.query.annee, mois: req.query.mois })));

  router.get('/etats/tft', auth, droit('READ'), etat('Tableau des flux de trésorerie', (req) => etatsService.fluxTresorerie(q(req)), 'tft', 'tableau-flux-tresorerie'));

  // ── Immobilisations et amortissements ──
  router.get('/immobilisations', auth, droit('READ'), gerer('Immobilisations', () => immobilisationService.lister()));
  router.post('/immobilisations', auth, droit('CREATE'), gerer('Immobilisation créée', (req) => immobilisationService.creer(req.body || {}), 201));
  router.get('/immobilisations/:id/plan', auth, droit('READ'), gerer('Plan d\'amortissement', (req) => immobilisationService.plan(req.params.id)));
  router.post('/immobilisations/:id/ceder', auth, droit('VALIDATE'), gerer('Cession enregistrée', (req) => immobilisationService.ceder(req.params.id, { ...(req.body || {}), utilisateurId: req.user.id }), 201));
  router.post('/exercices/:id/dotations', auth, droit('VALIDATE'), gerer('Dotations calculées', (req) => immobilisationService.dotationsExercice({ exerciceId: req.params.id })));

  // ── Stocks et clôture annuelle ──
  router.get('/stocks/valeur', auth, droit('READ'), gerer('Valeur du stock', async () => ({ valeur: await clotureService.valeurStock() })));
  router.post('/stocks/variation', auth, droit('VALIDATE'), gerer('Variation de stocks enregistrée', (req) => clotureService.variationStocks(req.body || {})));
  router.post('/exercices/:id/cloturer', auth, droit('CLOSE'), gerer('Exercice clôturé', (req) => clotureService.cloturerExercice({ exerciceId: req.params.id, valeurStock: (req.body || {}).valeurStock, utilisateurId: req.user.id })));

  // ── Rapprochement bancaire ──
  router.get('/rapprochement', auth, droit('READ'), gerer('État de rapprochement', (req) => clotureService.etatRapprochement({ compteNumero: req.query.compte, dateReleve: req.query.dateReleve, soldeReleve: req.query.soldeReleve })));
  router.post('/rapprochement/pointer', auth, droit('VALIDATE'), gerer('Lignes pointées', (req) => clotureService.pointer(req.body || {}), 201));
  router.post('/rapprochement/depointer', auth, droit('VALIDATE'), gerer('Pointage annulé', (req) => clotureService.depointer(req.body || {})));

  // ── Lettrage (rapprochement factures / règlements d'un tiers) ──
  router.get('/lettrage/lignes', auth, droit('READ'), gerer('Lignes à lettrer', (req) => etatsService.lignesOuvertes({ compteNumero: req.query.compte, tiersType: req.query.tiersType, tiersId: req.query.tiersId })));
  router.post('/lettrage', auth, droit('VALIDATE'), gerer('Lettrage enregistré', (req) => etatsService.lettrer((req.body || {}).ligneIds || []), 201));
  router.post('/lettrage/auto', auth, droit('VALIDATE'), gerer('Lettrage automatique', (req) => etatsService.lettrageAutomatique({ type: (req.body || {}).type })));
  router.delete('/lettrage/:code', auth, droit('VALIDATE'), gerer('Lettrage annulé', (req) => etatsService.delettrer(req.params.code)));

  return router;
}

module.exports = { createComptaRouter, aPrivilege };
