/**
 * Routes de synchronisation — statut et déclenchement manuel
 * Utilisé par les clients Type 3 (hybride local + Neon)
 */

const express = require('express');
const syncService = require('../services/sync-service');

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
          lastError: status.lastError,
        }
      });
    } catch (e) {
      console.error('⚠️  Erreur GET /sync/status:', e.message);
      res.status(500).json({ success: false, message: 'Erreur lecture statut sync: ' + e.message });
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
