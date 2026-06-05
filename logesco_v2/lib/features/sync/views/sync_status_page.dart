import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sync_controller.dart';
import '../services/sync_status_service.dart';

class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SyncController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('sync_title'.tr),
        actions: [
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh),
                onPressed: controller.refresh,
                tooltip: 'sync_refresh'.tr,
              )),
        ],
      ),
      body: Obx(() {
        final s = controller.status.value;
        if (s == null) {
          return Center(child: Text('sync_loading'.tr));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(s),
            const SizedBox(height: 16),
            if (s.hasPending) ...[
              _buildPendingCard(s),
              const SizedBox(height: 16),
            ],
            _buildSyncButton(controller, s),
          ],
        );
      }),
    );
  }

  Widget _buildStatusCard(SyncStatus s) {
    final modeColor = s.mode == 'hybrid'
        ? Colors.green
        : s.mode == 'offline-fallback'
            ? Colors.orange
            : Colors.grey;
    final modeIcon = s.mode == 'hybrid'
        ? Icons.cloud_done
        : s.mode == 'offline-fallback'
            ? Icons.cloud_off
            : Icons.storage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(modeIcon, color: modeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeLabelFor(s.mode),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: modeColor,
                        ),
                      ),
                      Text(
                        s.isOnline ? 'sync_neon_connected'.tr : 'sync_neon_offline'.tr,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: s.isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (s.lastSync != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '${'sync_last_sync'.tr}: ${_formatDate(s.lastSync!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(SyncStatus s) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '${'sync_pending_count'.tr}: ${s.pendingCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (s.failedCount > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${s.failedCount} ${'sync_failed_label'.tr}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ...s.pendingByTable.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_tableLabel(e.key), style: const TextStyle(fontSize: 13))),
                      Text(
                        '${e.value} ${'sync_items'.tr}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton(SyncController controller, SyncStatus s) {
    return Obx(() => ElevatedButton.icon(
          onPressed: (!s.isOnline || controller.isSyncing.value) ? null : controller.triggerSync,
          icon: controller.isSyncing.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync),
          label: Text(controller.isSyncing.value ? 'sync_in_progress'.tr : 'sync_now'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ));
  }

  String _modeLabelFor(String mode) {
    switch (mode) {
      case 'hybrid':
        return 'sync_mode_hybrid'.tr;
      case 'offline-fallback':
        return 'sync_mode_offline'.tr;
      default:
        return 'sync_mode_local'.tr;
    }
  }

  String _tableLabel(String table) {
    const labels = {
      'produits': 'Produits',
      'ventes': 'Ventes',
      'details_ventes': 'Détails ventes',
      'clients': 'Clients',
      'fournisseurs': 'Fournisseurs',
      'stock': 'Stock',
      'stock_boutiques': 'Stock boutiques',
      'cash_sessions': 'Sessions caisse',
      'cash_movements': 'Mouvements caisse',
      'financial_movements': 'Mouvements financiers',
      'commandes_approvisionnement': 'Commandes appro.',
      'details_commandes_approvisionnement': 'Détails commandes',
      'mouvements_stock': 'Mouvements stock',
      'utilisateurs': 'Utilisateurs',
      'categories': 'Catégories',
      'boutiques': 'Boutiques',
    };
    return labels[table] ?? table;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
