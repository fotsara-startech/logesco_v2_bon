/**
 * Routes de synchronisation — statut et déclenchement manuel
 * Utilisé par les clients Type 3 (hybride local + Neon)
 */

const express = require('express');
const syncService = require('../services/sync-service');
const { getSyncDetails } = require('../services/sync-detail');
const { renvoyerVersCloud } = require('../services/sync-resend');
const { ignorerEcarts, restaurerEcarts } = require('../services/sync-health');
const { DecisionCenter } = require('../services/decision-center');

/** Résumé du dernier contrôle d'écart (null tant qu'aucun contrôle n'a abouti) */
function driftSummary() {
  const r = syncService.driftReport;
  if (!r) return null;
  return { verifieLe: r.verifieLe, inexpliques: r.resume.inexpliques, anciens: r.resume.anciens, connus: r.resume.connus, ignores: r.resume.ignores || 0 };
}

function createSyncRouter({ authService }) {
  const router = express.Router();
  const { authenticateToken } = require('../middleware/auth');

  /**
   * GET /sync/status
   * Retourne l'état de l'operation_log (Event Sourcing V2)
   */
  router.get('/status', authenticateToken(authService), async (req, res) => {
    try {
      const status = syncService.getStatus();

      // Si mode local-only, pas de sync cloud
      if (!status.cloudEnabled) {
        return res.json({
          success: true,
          data: {
            mode: 'local-only',
            cloudEnabled: false,
            cloudAvailable: false,
            pendingCount: 0,
            pendingByTable: {},
            failedCount: 0,
            lastSync: null,
          }
        });
      }

      // Vraie date de dernière synchro réussie : celle de ce démarrage, sinon la
      // dernière opération confirmée par Neon (journal local)
      let lastSync = status.lastSuccessfulSyncAt;
      if (!lastSync) {
        const row = await syncService.localPrisma.$queryRawUnsafe(
          `SELECT MAX(synced_at) as last FROM operation_log WHERE status = 'synced'`
        );
        const v = row[0]?.last;
        if (v) {
          // synced_at est stocké en UTC ("YYYY-MM-DD HH:MM:SS") ou en ms epoch selon l'écriture
          const d = typeof v === 'number' || typeof v === 'bigint'
            ? new Date(Number(v))
            : new Date(String(v).includes('T') ? v : String(v).replace(' ', 'T') + 'Z');
          if (!isNaN(d)) lastSync = d.toISOString();
        }
      }

      // Lire l'operation_log en attente depuis la BD locale (V2 Event Sourcing)
      const pending = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT table_name, COUNT(*) as count
         FROM operation_log
         WHERE status IN ('pending', 'failed')
         GROUP BY table_name
         ORDER BY count DESC`
      );

      const failed = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT COUNT(*) as count FROM operation_log WHERE status = 'failed'`
      );

      // Ancienneté de la plus vieille opération qui n'est pas partie vers Neon :
      // sert à alerter quand la synchro est bloquée depuis longtemps.
      const oldestRow = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT MIN(timestamp) as oldest FROM operation_log WHERE status IN ('pending', 'failed')`
      );
      let oldestPendingAt = null;
      const o = oldestRow[0]?.oldest;
      if (o) {
        // "YYYY-MM-DD HH:MM:SS" (UTC, datetime('now') de SQLite) ou époque en ms
        const d = typeof o === 'number' || typeof o === 'bigint'
          ? new Date(Number(o))
          : new Date(String(o).includes('T') ? o : String(o).replace(' ', 'T') + 'Z');
        if (!isNaN(d)) oldestPendingAt = d.toISOString();
      }

      const pendingByTable = {};
      let totalPending = 0;
      for (const row of pending) {
        const count = typeof row.count === 'bigint' ? Number(row.count) : row.count;
        pendingByTable[row.table_name] = count;
        totalPending += count;
      }

      const failedCount = typeof failed[0]?.count === 'bigint'
        ? Number(failed[0].count)
        : (failed[0]?.count || 0);

      // Lignes reçues de Neon mais non appliquées (conflits, dépendances)
      const pullIssues = await syncService.getPullIssues();

      res.json({
        success: true,
        data: {
          mode: status.mode,
          cloudEnabled: status.cloudEnabled,
          cloudAvailable: status.cloudAvailable,
          installationId: status.installationId,
          pendingCount: totalPending,
          pendingByTable,
          failedCount,
          pullIssues,
          pullIssuesCount: pullIssues.reduce((n, i) => n + i.enAttente, 0),
          lastSync,
          oldestPendingAt,
          lastError: status.lastError,
          drift: driftSummary(),
        }
      });
    } catch (e) {
      console.error('⚠️  Erreur GET /sync/status:', e.message);
      res.status(500).json({ success: false, message: 'Erreur lecture statut sync: ' + e.message });
    }
  });

  /**
   * GET /sync/drift
   * Contrôle d'écart avec le cloud : lignes présentes d'un seul côté, valeurs de stock ou de solde différentes.
   * Renvoie le dernier rapport ; ?refresh=1 relance la comparaison (quelques secondes).
   */
  router.get('/drift', authenticateToken(authService), async (req, res) => {
    try {
      const status = syncService.getStatus();
      if (!status.cloudEnabled) {
        return res.json({ success: true, data: { actif: false, rapport: null } });
      }
      let rapport = syncService.driftReport;
      if (req.query.refresh === '1' || !rapport) {
        rapport = await syncService.checkDrift();
      }
      res.json({
        success: true,
        data: { actif: true, rapport, erreur: syncService.lastDriftError || null },
      });
    } catch (e) {
      console.error('⚠️  Erreur GET /sync/drift:', e.message);
      res.status(500).json({ success: false, message: "Erreur du contrôle d'écart: " + e.message });
    }
  });

  /** Administrateur seulement (les actions ci-dessous modifient ce qui part vers le cloud ou ce qui est signalé) */
  async function estAdmin(userId) {
    const user = await syncService.localPrisma.utilisateur.findUnique({ where: { id: Number(userId) }, include: { role: true } });
    return !!(user && user.role && user.role.isAdmin);
  }

  /** Trace d'une décision prise sur un écart (même journal que le centre de décisions ; SQLite local seulement) */
  async function tracer(caseKey, optionId, userId, details) {
    try {
      const centre = new DecisionCenter({ prisma: syncService.localPrisma });
      if (!centre.journalDisponible) return;
      await centre._assurerJournal();
      await syncService.localPrisma.$executeRawUnsafe(
        `INSERT INTO decision_log (case_key, type, option_id, status, user_id, details) VALUES (?, 'sync_ecart', ?, 'applique', ?, ?)`,
        caseKey, optionId, userId || null, JSON.stringify(details)
      );
    } catch (e) {
      console.warn('⚠️  Décision appliquée mais trace non enregistrée:', e.message);
    }
  }

  /**
   * POST /sync/drift/resend   { dryRun?: boolean, forcer?: [{table, id}] }
   * Renvoie vers le cloud les lignes locales que le système n'a jamais envoyées, mais seulement celles dont le
   * renvoi est sans risque (voir sync-resend.js). dryRun : aperçu sans rien envoyer.
   * forcer : lignes à envoyer malgré le seul refus levable (mouvement de stock alors que le cloud a déjà un
   * historique pour ce produit). Réservé aux administrateurs.
   */
  router.post('/drift/resend', authenticateToken(authService), async (req, res) => {
    let client = null;
    let perdue = false;
    try {
      const status = syncService.getStatus();
      if (!status.cloudEnabled || !syncService.cloudPool) {
        return res.status(409).json({ success: false, message: 'Pas de cloud configuré sur ce poste.' });
      }
      if (!(await estAdmin(req.user.id))) {
        return res.status(403).json({ success: false, message: 'Seul un administrateur peut renvoyer des données vers le cloud.' });
      }
      const dryRun = !!(req.body && req.body.dryRun === true);
      const forcer = Array.isArray(req.body && req.body.forcer) ? req.body.forcer : [];
      client = await syncService.cloudPool.connect();
      const resultat = await renvoyerVersCloud({
        prisma: syncService.localPrisma,
        client,
        logOperation: (t, o, d) => syncService.logOperation(t, o, d, Number(req.user.id)),
        dryRun,
        forcer,
        isConnectionError: (e) => syncService._isConnectionError(e),
      });
      if (!dryRun && resultat.envoyes > 0) {
        await tracer('sync_ecart:renvoi', forcer.length ? 'renvoyer_force' : 'renvoyer', req.user.id, {
          envoyes: resultat.details.envoyables.map((e) => `${e.table}#${e.id}`),
          forces: forcer.map((f) => `${f.table}#${f.id}`),
        });
      }
      res.json({ success: true, message: dryRun ? 'Aperçu' : `${resultat.envoyes} élément(s) mis en file d'envoi`, data: resultat });
    } catch (e) {
      perdue = syncService._isConnectionError(e);
      console.error('⚠️  Erreur POST /sync/drift/resend:', e.message);
      res.status(perdue ? 503 : 500).json({ success: false, message: perdue ? 'Cloud injoignable : réessayez dans un instant.' : 'Erreur lors du renvoi: ' + e.message });
    } finally {
      if (client) client.release(perdue ? true : undefined);
    }
  });

  /**
   * POST /sync/drift/ignore   { items: [{table, id, sens}], note? }
   * Déclare des écarts de présence « vus, volontaires » : ils ne sont plus signalés tant qu'ils existent (compte à
   * part dans le rapport) et sont oubliés dès qu'ils disparaissent. Les valeurs différentes ne s'ignorent pas.
   * POST /sync/drift/ignore   { restaurer: true }  réaffiche tout ce qui avait été ignoré. Administrateurs seulement.
   */
  router.post('/drift/ignore', authenticateToken(authService), async (req, res) => {
    try {
      if (!(await estAdmin(req.user.id))) {
        return res.status(403).json({ success: false, message: 'Seul un administrateur peut ignorer un écart.' });
      }
      const corps = req.body || {};
      let nombre;
      if (corps.restaurer === true) {
        nombre = await restaurerEcarts(syncService.localPrisma);
        await tracer('sync_ecart:ignore', 'restaurer', req.user.id, { restaures: nombre });
      } else {
        const items = Array.isArray(corps.items) ? corps.items.slice(0, 500) : [];
        if (!items.length) return res.status(400).json({ success: false, message: 'Aucun élément à ignorer.' });
        nombre = await ignorerEcarts(syncService.localPrisma, items, { userId: Number(req.user.id), note: corps.note ? String(corps.note).slice(0, 300) : null });
        await tracer('sync_ecart:ignore', 'ignorer', req.user.id, { ignores: items.map((i) => `${i.table}#${i.id}:${i.sens}`), note: corps.note || null });
      }
      // le rapport affiché doit refléter le choix tout de suite
      const rapport = await syncService.checkDrift();
      res.json({ success: true, message: corps.restaurer === true ? 'Écarts réaffichés' : 'Écart ignoré', data: { nombre, rapport } });
    } catch (e) {
      console.error('⚠️  Erreur POST /sync/drift/ignore:', e.message);
      res.status(500).json({ success: false, message: "Erreur lors de la prise en compte de l'écart: " + e.message });
    }
  });

  /**
   * GET /sync/details
   * Détail de chaque élément non synchronisé : quel produit / quelle vente...,
   * l'opération, et l'erreur expliquée en clair (cause + action à mener).
   * Regroupe les envois en attente ou refusés ET les lignes reçues du cloud
   * qui n'ont pas pu être appliquées.
   */
  router.get('/details', authenticateToken(authService), async (req, res) => {
    try {
      const status = syncService.getStatus();
      if (!status.cloudEnabled) {
        return res.json({ success: true, data: { items: [], total: 0, genereLe: new Date().toISOString() } });
      }
      const limit = Math.min(parseInt(req.query.limit, 10) || 200, 500);
      const items = await getSyncDetails(syncService.localPrisma, { limit });
      res.json({
        success: true,
        data: {
          items,
          total: items.length,
          erreurs: items.filter((i) => i.status === 'failed').length,
          genereLe: new Date().toISOString(),
        }
      });
    } catch (e) {
      console.error('⚠️  Erreur GET /sync/details:', e.message);
      res.status(500).json({ success: false, message: 'Erreur lecture du détail de synchronisation: ' + e.message });
    }
  });

  /**
   * POST /sync/trigger
   * Force un cycle de synchronisation immédiat
   */
  router.post('/trigger', authenticateToken(authService), async (req, res) => {
    try {
      const status = syncService.getStatus();

      if (!status.cloudEnabled) {
        return res.json({ success: false, message: 'Mode local uniquement — pas de cloud configuré' });
      }

      // Si le poste est passé « hors ligne » sur une micro-coupure, on retente
      // la connexion tout de suite au lieu de bloquer l'utilisateur
      if (!status.cloudAvailable) {
        const reconnecte = await syncService._checkCloudConnection();
        if (!reconnecte) {
          const err = syncService.getStatus().lastError;
          const motif = err ? ` (${err.code || 'erreur'} : ${err.message})` : '';
          return res.json({
            success: false,
            message: 'Neon inaccessible — vérifiez la connexion internet' + motif
          });
        }
      }

      // Déclencher le cycle de sync
      await syncService._syncCycle();

      // Relire le statut après sync (V2 Event Sourcing)
      const pendingAfter = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT COUNT(*) as count FROM operation_log WHERE status IN ('pending', 'failed')`
      );
      const remainingCount = typeof pendingAfter[0]?.count === 'bigint'
        ? Number(pendingAfter[0].count)
        : (pendingAfter[0]?.count || 0);

      res.json({
        success: true,
        message: 'Synchronisation effectuée',
        data: { remainingPending: remainingCount }
      });
    } catch (e) {
      console.error('Erreur POST /sync/trigger:', e.message);
      res.status(500).json({ success: false, message: 'Erreur lors de la synchronisation: ' + e.message });
    }
  });

  return router;
}

module.exports = { createSyncRouter };
