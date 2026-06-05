import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sync_controller.dart';
import '../views/sync_status_page.dart';

/// Indicateur de synchronisation affiché dans l'AppBar ou le drawer
/// Visible uniquement pour les clients Type 3 (cloud activé)
class SyncIndicatorWidget extends StatelessWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) return const SizedBox.shrink();
    final controller = Get.find<SyncController>();

    return Obx(() {
      final s = controller.status.value;
      // Cacher si mode local-only (pas de cloud)
      if (s == null || !s.isType3) return const SizedBox.shrink();

      final pending = s.pendingCount;
      final isOffline = !s.isOnline;

      return GestureDetector(
        onTap: () => Get.to(() => const SyncStatusPage()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isOffline ? Icons.cloud_off : (pending > 0 ? Icons.sync_problem : Icons.cloud_done),
                color: isOffline
                    ? Colors.red[300]
                    : pending > 0
                        ? Colors.orange[300]
                        : Colors.green[300],
                size: 24,
              ),
              if (pending > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      pending > 99 ? '99+' : '$pending',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Item de menu drawer pour la synchronisation
class SyncDrawerMenuItem extends StatelessWidget {
  const SyncDrawerMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) return const SizedBox.shrink();
    final controller = Get.find<SyncController>();

    return Obx(() {
      final s = controller.status.value;
      if (s == null || !s.isType3) return const SizedBox.shrink();

      final pending = s.pendingCount;
      final isOffline = !s.isOnline;

      return ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isOffline ? Icons.cloud_off : (pending > 0 ? Icons.sync_problem : Icons.cloud_done),
              color: isOffline ? Colors.red : (pending > 0 ? Colors.orange : Colors.green),
            ),
            if (pending > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: Text(
                    pending > 99 ? '99+' : '$pending',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text('sync_title'.tr),
        subtitle: Text(
          isOffline
              ? 'sync_neon_offline'.tr
              : pending > 0
                  ? '$pending ${'sync_pending_short'.tr}'
                  : 'sync_up_to_date'.tr,
          style: TextStyle(
            fontSize: 12,
            color: isOffline ? Colors.red : (pending > 0 ? Colors.orange : Colors.green),
          ),
        ),
        onTap: () {
          Navigator.pop(context); // fermer le drawer
          Get.to(() => const SyncStatusPage());
        },
      );
    });
  }
}
