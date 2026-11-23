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

function createComptaRouter({ authService, prisma, comptaService }) {
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

  // ── États ──
  router.get('/grand-livre', auth, droit('READ'), gerer('Grand livre', (req) => comptaService.grandLivre({
    compteNumero: req.query.compte,
    exerciceId: req.query.exerciceId,
    dateDebut: req.query.dateDebut,
    dateFin: req.query.dateFin,
    boutiqueId: boutique(req),
    tiersType: req.query.tiersType,
    tiersId: req.query.tiersId,
  })));
  router.get('/balance', auth, droit('READ'), gerer('Balance', (req) => comptaService.balance({
    exerciceId: req.query.exerciceId,
    dateDebut: req.query.dateDebut,
    dateFin: req.query.dateFin,
    boutiqueId: boutique(req),
    inclureSoldesNuls: req.query.inclureSoldesNuls === 'true',
  })));

  return router;
}

module.exports = { createComptaRouter, aPrivilege };
