import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import 'license_activation_page.dart';

/// Bannière affichée en mode dégradé pour indiquer les limitations
class DegradedModeBanner extends StatelessWidget {
  final bool isInGracePeriod;
  final int? remainingGraceDays;

  const DegradedModeBanner({
    super.key,
    this.isInGracePeriod = false,
    this.remainingGraceDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isInGracePeriod ? 'subscription_degraded_mode'.tr : 'subscription_read_only_mode'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                if (isInGracePeriod && remainingGraceDays != null)
                  Text(
                    'subscription_days_remaining'.trParams({'days': remainingGraceDays.toString()}),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'subscription_activate'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui encapsule le contenu avec les restrictions du mode dégradé
class DegradedModeWrapper extends StatelessWidget {
  final Widget child;
  final bool allowModifications;
  final String? restrictionMessage;

  const DegradedModeWrapper({
    super.key,
    required this.child,
    this.allowModifications = false,
    this.restrictionMessage,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final status = subscriptionController.currentStatus;
      final shouldShowBanner = status != null && (!status.isActive || status.isInGracePeriod);

      return Column(
        children: [
          // Bannière de mode dégradé
          if (shouldShowBanner)
            DegradedModeBanner(
              isInGracePeriod: status.isInGracePeriod,
              remainingGraceDays: status.isInGracePeriod ? 3 : null, // TODO: Calculer les jours restants de grâce
            ),

          // Contenu principal
          Expanded(
            child: Stack(
              children: [
                child,

                // Overlay de restriction si nécessaire
                if (!allowModifications && shouldShowBanner) _buildRestrictionOverlay(context),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRestrictionOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'subscription_restricted_feature'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  restrictionMessage ?? 'subscription_restricted_message'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Fermer l'overlay (retour en mode consultation)
                      },
                      child: Text('close'.tr),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LicenseActivationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('subscription_activate_license'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin pour ajouter facilement les vérifications de mode dégradé
mixin DegradedModeCheck {
  /// Vérifie si une action est autorisée en mode dégradé
  bool canPerformAction(BuildContext context, {bool showDialog = true}) {
    final subscriptionController = Get.find<SubscriptionController>();
    final status = subscriptionController.currentStatus;

    // Si l'abonnement est actif et pas en période de grâce, autoriser
    if (status != null && status.isActive && !status.isInGracePeriod) {
      return true;
    }

    // Si en période de grâce, autoriser seulement la consultation
    if (status != null && status.isInGracePeriod) {
      if (showDialog) {
        _showGracePeriodDialog(context);
      }
      return false;
    }

    // Sinon, bloquer complètement
    if (showDialog) {
      _showBlockedDialog(context);
    }
    return false;
  }

  void _showGracePeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('subscription_grace_period'.tr),
          ],
        ),
        content: Text('subscription_grace_period_restriction'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            child: Text('subscription_activate'.tr),
          ),
        ],
      ),
    );
  }

  void _showBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            Text('subscription_access_blocked'.tr),
          ],
        ),
        content: Text('subscription_access_blocked_message'.tr),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('subscription_activate_license'.tr),
          ),
        ],
      ),
    );
  }
}
