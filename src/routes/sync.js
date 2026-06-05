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
   * Retourne l'état de la sync_queue et le mode de connexion
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

      // Lire la queue en attente depuis la BD locale
      const pending = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT table_name, COUNT(*) as count
         FROM sync_queue
         WHERE synced = 0
         GROUP BY table_name
         ORDER BY count DESC`
      );

      const failed = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT COUNT(*) as count FROM sync_queue WHERE error IS NOT NULL AND synced = 0`
      );

      const lastPullMeta = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT value FROM sync_meta WHERE key = 'last_pull' LIMIT 1`
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

      res.json({
        success: true,
        data: {
          mode: status.mode,
          cloudEnabled: status.cloudEnabled,
          cloudAvailable: status.cloudAvailable,
          pendingCount: totalPending,
          pendingByTable,
          failedCount,
          lastSync: lastPullMeta[0]?.value || null,
        }
      });
    } catch (e) {
      console.error('Erreur GET /sync/status:', e.message);
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

      if (!status.cloudAvailable) {
        return res.json({ success: false, message: 'Neon inaccessible — vérifiez la connexion internet' });
      }

      // Déclencher le cycle de sync
      await syncService._syncCycle();

      // Relire le statut après sync
      const pendingAfter = await syncService.localPrisma.$queryRawUnsafe(
        `SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0`
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
