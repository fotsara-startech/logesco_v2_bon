import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../views/license_activation_page.dart';

/// Widget qui affiche une bannière d'avertissement en mode dégradé
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
      final shouldShowBanner = status?.isInGracePeriod == true || subscriptionController.isInDegradedMode();

      if (!shouldShowBanner) {
        return child;
      }

      return Column(
        children: [
          // Bannière d'avertissement
          _buildWarningBanner(context, status),
          // Contenu principal
          Expanded(child: child),
        ],
      );
    });
  }

  Widget _buildWarningBanner(BuildContext context, dynamic status) {
    String message;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (status?.isInGracePeriod == true) {
      message = 'Période de grâce active - Renouvelez votre abonnement';
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.error;
    } else {
      message = restrictionMessage ?? 'Mode dégradé - Fonctionnalités limitées';
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.warning;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: textColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.to(() => const LicenseActivationPage());
            },
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text(
              'Activer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour bloquer les actions de modification en mode dégradé
class ReadOnlyOverlay extends StatelessWidget {
  final Widget child;
  final String? message;

  const ReadOnlyOverlay({
    super.key,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final shouldBlock = !subscriptionController.isSubscriptionActive;

      if (!shouldBlock) {
        return child;
      }

      return Stack(
        children: [
          // Contenu original avec opacité réduite
          Opacity(
            opacity: 0.6,
            child: AbsorbPointer(
              absorbing: true,
              child: child,
            ),
          ),
          // Overlay de blocage
          Positioned.fill(
            child: Container(
              color: Colors.grey.withOpacity(0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message ?? 'Fonctionnalité verrouillée',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Activez une licence pour débloquer cette fonctionnalité',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Get.to(() => const LicenseActivationPage());
                        },
                        child: const Text('Activer une licence'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
