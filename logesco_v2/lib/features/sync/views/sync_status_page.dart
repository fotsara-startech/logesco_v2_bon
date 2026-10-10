import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../controllers/sync_controller.dart';
import '../services/sync_status_service.dart';
import '../widgets/sync_drift_card.dart';

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
            if (s.isStale) ...[
              _buildStaleBanner(s),
              const SizedBox(height: 16),
            ],
            _buildStatusCard(s),
            const SizedBox(height: 16),
            if (controller.details.isNotEmpty) ...[
              _buildDetailsCard(controller.details),
              const SizedBox(height: 16),
            ] else if (s.hasPending) ...[
              _buildPendingCard(s),
              const SizedBox(height: 16),
            ],
            if (s.isType3) ...[
              SyncDriftCard(
                report: controller.drift.value,
                checking: controller.isCheckingDrift.value,
                onCheck: controller.verifierEcart,
                onResend: () => _renvoyer(context, controller),
              ),
              const SizedBox(height: 16),
            ],
            _buildSyncButton(controller, s),
          ],
        );
      }),
    );
  }

  /// Aperçu de ce qui peut être renvoyé vers le cloud, confirmation, puis envoi
  Future<void> _renvoyer(BuildContext context, SyncController controller) async {
    SyncResendResult apercu;
    try {
      apercu = await controller.apercuRenvoi();
    } catch (e) {
      SnackbarHelper.error(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!context.mounted) return;
    if (apercu.aEnvoyer == 0 && apercu.refuses.isEmpty) {
      SnackbarHelper.warning('Rien à renvoyer.');
      return;
    }
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renvoyer vers le cloud ?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${apercu.aEnvoyer} élément(s) peuvent être envoyés sans risque (rien n\'est écrasé dans le cloud).',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ...apercu.envoyables.take(6).map((l) => Text('• ${l.resume}', style: const TextStyle(fontSize: 12))),
              if (apercu.envoyables.length > 6) Text('… et ${apercu.envoyables.length - 6} autre(s)', style: const TextStyle(fontSize: 12)),
              if (apercu.refuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${apercu.refuses.length} élément(s) NE seront PAS envoyés :', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                ...apercu.refuses.take(6).map((l) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${l.resume}\n   ${l.raison ?? ''}', style: const TextStyle(fontSize: 12)),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          if (apercu.aEnvoyer > 0) ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirme == true) await controller.renvoyer();
  }

  /// Alerte : des données restent sans partir vers le cloud depuis plus de 24 h
  Widget _buildStaleBanner(SyncStatus s) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synchronisation bloquée depuis ${s.pendingAgeLabel}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${s.pendingCount} opération(s) n'ont pas encore été envoyées vers le cloud. "
                    'Vos données sont conservées sur ce poste, mais les autres postes ne les voient pas. '
                    'Vérifiez la connexion internet puis appuyez sur « Synchroniser maintenant ».',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            if (!s.isOnline && s.lastErrorMessage != null) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dernière erreur de connexion : ${s.lastErrorMessage}',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ],
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

  /// Détail de chaque élément non synchronisé, avec la cause du blocage en clair
  Widget _buildDetailsCard(List<SyncDetailItem> items) {
    final erreurs = items.where((i) => i.isFailed).length;
    // Les éléments refusés d'abord : ce sont eux qui demandent une attention
    final tries = [...items]..sort((a, b) {
        if (a.isFailed != b.isFailed) return a.isFailed ? -1 : 1;
        return (a.createdAt ?? DateTime(2100)).compareTo(b.createdAt ?? DateTime(2100));
      });

    return Card(
      color: erreurs > 0 ? Colors.red.shade50 : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: erreurs > 0 ? Colors.red.shade700 : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Détail de ce qui n\'est pas synchronisé (${items.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier le détail (pour le support)',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () async {
                    final texte = 'Synchronisation — ${items.length} élément(s) non synchronisé(s)\n${tries.map((i) => i.toReportLine()).join('\n')}';
                    await Clipboard.setData(ClipboardData(text: texte));
                    SnackbarHelper.success('Détail copié dans le presse-papiers');
                  },
                ),
              ],
            ),
            if (erreurs > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '$erreurs élément(s) refusé(s) par le cloud. Touchez un élément pour voir pourquoi et que faire.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 4),
            ...tries.map((i) => _SyncDetailTile(item: i)),
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
          onPressed: (!s.cloudEnabled || controller.isSyncing.value) ? null : controller.triggerSync,
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

/// Un élément non synchronisé : titre clair, puis cause et action au toucher
class _SyncDetailTile extends StatelessWidget {
  final SyncDetailItem item;
  const _SyncDetailTile({required this.item});

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = item.isFailed ? Colors.red : Colors.orange;
    final statut = item.isFailed ? (item.isReception ? 'Non appliqué' : 'Refusé') : 'En attente';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: item.isFailed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(item.isFailed ? Icons.error_outline : Icons.hourglass_top, color: color.shade700),
          title: Text(
            item.summary.isEmpty ? item.tableLabel : item.summary,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${item.tableLabel} · ${item.operationLabel}${item.createdAt != null ? ' · ${_date(item.createdAt!)}' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.shade100, borderRadius: BorderRadius.circular(10)),
            child: Text(statut, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800)),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.error.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(item.error.explication, style: const TextStyle(fontSize: 13)),
            if (item.error.action.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.green.shade800),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.error.action, style: TextStyle(fontSize: 12, color: Colors.green.shade900))),
                  ],
                ),
              ),
            ],
            if (item.isReception && item.attempts > 0) ...[
              const SizedBox(height: 6),
              Text('Application tentée ${item.attempts} fois', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
            if ((item.error.technique ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Message technique', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              SelectableText(item.error.technique!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Consolas')),
            ],
          ],
        ),
      ),
    );
  }
}
