import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../views/subscription_status_page.dart';
import '../views/license_activation_page.dart';

/// Widget compact pour afficher le statut d'abonnement dans l'interface
class SubscriptionStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool compact;

  const SubscriptionStatusWidget({
    super.key,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final status = subscriptionController.currentStatus;

      if (status == null) {
        return const SizedBox.shrink();
      }

      // Ne pas afficher si tout va bien et en mode compact
      if (compact && status.isActive && !subscriptionController.shouldShowNotifications()) {
        return const SizedBox.shrink();
      }

      return _buildStatusCard(context, status, subscriptionController);
    });
  }

  Widget _buildStatusCard(BuildContext context, dynamic status, SubscriptionController controller) {
    final isActive = status.isActive;
    final isInGracePeriod = status.isInGracePeriod;
    final remainingDays = status.remainingDays ?? 0;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String? subtitle;

    if (!isActive && !isInGracePeriod) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.error;
      title = 'Abonnement expiré';
      subtitle = 'Activez une licence pour continuer';
    } else if (isInGracePeriod) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.warning;
      title = 'Période de grâce';
      subtitle = 'Renouvelez maintenant';
    } else if (remainingDays <= 1) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.warning;
      title = remainingDays == 0 ? 'Expire aujourd\'hui' : 'Expire demain';
      subtitle = 'Renouvelez votre abonnement';
    } else if (remainingDays <= 3) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.info;
      title = 'Expire dans $remainingDays jours';
      subtitle = 'Pensez à renouveler';
    } else {
      // Abonnement actif, ne pas afficher en mode compact
      if (compact) return const SizedBox.shrink();

      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
      title = 'Abonnement actif';
      subtitle = showDetails ? 'Expire dans $remainingDays jours' : null;
    }

    if (compact) {
      return _buildCompactCard(context, backgroundColor, textColor, icon, title);
    } else {
      return _buildFullCard(context, backgroundColor, textColor, icon, title, subtitle);
    }
  }

  Widget _buildCompactCard(BuildContext context, Color backgroundColor, Color textColor, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => Get.to(() => const SubscriptionStatusPage()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, Color backgroundColor, Color textColor, IconData icon, String title, String? subtitle) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Get.to(() => const SubscriptionStatusPage()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Get.to(() => const SubscriptionStatusPage()),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                    ),
                    child: const Text('Détails'),
                  ),
                  if (!Get.find<SubscriptionController>().isSubscriptionActive) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Get.to(() => const LicenseActivationPage()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor,
                        foregroundColor: backgroundColor,
                      ),
                      child: const Text('Activer'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher le statut dans la barre d'applications
class SubscriptionAppBarWidget extends StatelessWidget {
  const SubscriptionAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubscriptionStatusWidget(
      compact: true,
      showDetails: false,
    );
  }
}

/// Widget pour afficher les notifications d'expiration
class SubscriptionNotificationBanner extends StatelessWidget {
  const SubscriptionNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      if (!subscriptionController.shouldShowCriticalNotifications()) {
        return const SizedBox.shrink();
      }

      final status = subscriptionController.currentStatus;
      if (status == null) return const SizedBox.shrink();

      String message;
      Color backgroundColor;
      Color textColor;

      if (!status.isActive && !status.isInGracePeriod) {
        message = 'Votre abonnement a expiré. Activez une licence pour continuer.';
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
      } else if (status.isInGracePeriod) {
        message = 'Vous êtes en période de grâce. Renouvelez votre abonnement maintenant.';
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
      } else if (status.remainingDays != null && status.remainingDays! <= 1) {
        message = status.remainingDays == 0 ? 'Votre abonnement expire aujourd\'hui!' : 'Votre abonnement expire demain!';
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
      } else {
        return const SizedBox.shrink();
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
            Icon(Icons.warning, color: textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const LicenseActivationPage()),
              style: TextButton.styleFrom(
                foregroundColor: textColor,
              ),
              child: const Text(
                'Activer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }
}
