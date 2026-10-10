/**
 * Centre de décisions : cas ambigus que l'application ne peut pas trancher seule.
 *
 *   GET  /decisions         liste des cas à décider (faits + options chiffrées)
 *   POST /decisions/apply   applique la décision prise sur un cas
 *
 * Lire la liste est ouvert à tout utilisateur connecté (elle alimente l'alerte) ; APPLIQUER une
 * décision modifie le stock : réservé aux administrateurs.
 */
const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const { DecisionCenter } = require('../services/decision-center');
const { SyncConflictCenter } = require('../services/sync-conflicts');

function createDecisionsRouter({ authService, prisma, syncService }) {
  const router = express.Router();
  const centre = new DecisionCenter({ prisma, syncService });
  // Conflits de synchronisation (même fiche sur deux postes) : trace dans le même journal que le stock
  const conflits = new SyncConflictCenter({
    prisma,
    syncService,
    journal: async (caseKey, optionId, details) => {
      if (!centre.journalDisponible) return;
      await centre._assurerJournal();
      await prisma.$executeRawUnsafe(
        `INSERT INTO decision_log (case_key, type, option_id, status, user_id, details) VALUES (?, 'sync', ?, 'applique', ?, ?)`,
        caseKey, optionId, details.userId || null, JSON.stringify(details)
      );
    },
  });

  async function estAdmin(userId) {
    // Jeton de test (développement uniquement) : utilisateur 1
    const user = await prisma.utilisateur.findUnique({ where: { id: Number(userId) }, include: { role: true } });
    return !!(user && user.role && user.role.isAdmin);
  }

  router.get('/', authenticateToken(authService), async (req, res) => {
    try {
      const { cases, total } = await centre.listCases();
      // Les conflits demandent d'interroger le cloud : une panne ne doit jamais masquer les cas de stock
      let sync = { conflits: [], total: 0, cloud: 'inactif' };
      try { sync = await conflits.listConflicts(); } catch (e) { console.warn('Conflits de synchro illisibles:', e.message); }
      res.json({ success: true, data: { cases, total, conflits: sync.conflits, totalConflits: sync.total, cloud: sync.cloud } });
    } catch (e) {
      console.error('Erreur GET /decisions:', e);
      res.status(500).json({ success: false, message: 'Erreur lors de la recherche des cas à décider' });
    }
  });

  router.post('/apply', authenticateToken(authService), async (req, res) => {
    try {
      if (!(await estAdmin(req.user.id))) {
        return res.status(403).json({ success: false, message: 'Seul un administrateur peut appliquer une décision de correction.' });
      }
      const { caseKey, optionId, cible, marquerPhysique, stockVu, valeur } = req.body || {};
      if (String(caseKey || '').startsWith('sync:')) {
        if (!optionId) return res.status(400).json({ success: false, message: 'optionId est requis' });
        const resultat = await conflits.apply({ caseKey, optionId, valeur, userId: req.user.id });
        return res.json({ success: true, message: 'Décision appliquée', data: resultat });
      }
      if (!caseKey || !optionId || stockVu === undefined || stockVu === null) {
        return res.status(400).json({ success: false, message: 'caseKey, optionId et stockVu sont requis' });
      }
      const resultat = await centre.apply({ caseKey, optionId, cible, marquerPhysique, stockVu, userId: req.user.id });
      res.json({ success: true, message: resultat.statut === 'ignore' ? 'Cas laissé tel quel' : 'Décision appliquée', data: resultat });
    } catch (e) {
      if (e.status) return res.status(e.status).json({ success: false, message: e.message });
      console.error('Erreur POST /decisions/apply:', e);
      res.status(500).json({ success: false, message: 'Erreur lors de l\'application de la décision' });
    }
  });

  return router;
}

module.exports = { createDecisionsRouter };
