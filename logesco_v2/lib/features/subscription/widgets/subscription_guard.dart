import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_status.dart';
import '../views/subscription_blocked_page.dart';
import '../views/license_activation_page.dart';
import 'degraded_mode_wrapper.dart';
import '../../../../core/config/app_config.dart';

/// Widget qui protège l'accès aux fonctionnalités selon l'état de l'abonnement
class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final bool requireActiveSubscription;
  final bool allowGracePeriod;
  final String? restrictionMessage;

  const SubscriptionGuard({
    super.key,
    required this.child,
    this.requireActiveSubscription = true,
    this.allowGracePeriod = false,
    this.restrictionMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Contrôle de licence désactivé - afficher toujours le contenu
    if (!AppConfig.enableLicenseControl) return child;

    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final status = subscriptionController.currentStatus;

      if (status == null) return const SubscriptionBlockedPage();
      if (!status.isActive && !status.isInGracePeriod) return const SubscriptionBlockedPage();
      if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) return const SubscriptionBlockedPage();

      if (status.isActive || (status.isInGracePeriod && allowGracePeriod)) {
        if (status.isInGracePeriod || subscriptionController.isInDegradedMode()) {
          return DegradedModeWrapper(
            allowModifications: !requireActiveSubscription,
            restrictionMessage: restrictionMessage,
            child: child,
          );
        }
        return child;
      }

      return const SubscriptionBlockedPage();
    });
  }
}

/// Widget pour les actions qui nécessitent un abonnement actif
class SubscriptionProtectedAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool requireActiveSubscription;
  final String? restrictionMessage;

  const SubscriptionProtectedAction({
    super.key,
    required this.child,
    this.onPressed,
    this.requireActiveSubscription = true,
    this.restrictionMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Contrôle de licence désactivé - action toujours disponible
    if (!AppConfig.enableLicenseControl) {
      return GestureDetector(onTap: onPressed, child: child);
    }

    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final status = subscriptionController.currentStatus;
      final canPerformAction = _canPerformAction(status);

      return GestureDetector(
        onTap: canPerformAction ? onPressed : () => _showRestrictionDialog(context),
        child: Opacity(opacity: canPerformAction ? 1.0 : 0.6, child: child),
      );
    });
  }

  bool _canPerformAction(SubscriptionStatus? status) {
    if (status == null) return false;
    if (!requireActiveSubscription) return status.isActive || status.isInGracePeriod;
    return status.isActive && !status.isInGracePeriod;
  }

  void _showRestrictionDialog(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();
    final status = subscriptionController.currentStatus;

    String title;
    String message;

    if (status == null || (!status.isActive && !status.isInGracePeriod)) {
      title = 'Abonnement expiré';
      message = 'Cette fonctionnalité nécessite un abonnement actif.';
    } else if (status.isInGracePeriod) {
      title = 'Période de grâce';
      message = 'Vous êtes en période de grâce. Cette action nécessite un abonnement actif.';
    } else {
      title = 'Accès restreint';
      message = restrictionMessage ?? 'Cette fonctionnalité nécessite un abonnement actif.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(status?.isInGracePeriod == true ? Icons.warning : Icons.lock, color: status?.isInGracePeriod == true ? Colors.orange : Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.to(() => const LicenseActivationPage());
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }
}

/// Mixin pour les pages qui nécessitent des vérifications d'abonnement
mixin SubscriptionAwarePage<T extends StatefulWidget> on State<T> {
  late SubscriptionController _subscriptionController;

  @override
  void initState() {
    super.initState();
    _subscriptionController = Get.find<SubscriptionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionNotifications();
    });
  }

  Future<void> _checkSubscriptionNotifications() async {
    if (!AppConfig.enableLicenseControl) return;
    if (mounted) {
      await _subscriptionController.checkAndShowNotifications(context);
    }
  }

  bool canPerformAction({bool requireActiveSubscription = true}) {
    if (!AppConfig.enableLicenseControl) return true;
    final status = _subscriptionController.currentStatus;
    if (status == null) return false;
    if (!requireActiveSubscription) return status.isActive || status.isInGracePeriod;
    return status.isActive && !status.isInGracePeriod;
  }

  void showRestrictionMessage({String? customMessage}) {
    final status = _subscriptionController.currentStatus;
    String message;
    if (status == null || (!status.isActive && !status.isInGracePeriod)) {
      message = 'Cette fonctionnalité nécessite un abonnement actif.';
    } else if (status.isInGracePeriod) {
      message = 'Action non autorisée en période de grâce.';
    } else {
      message = customMessage ?? 'Action non autorisée.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Activer',
          textColor: Colors.white,
          onPressed: () => Get.to(() => const LicenseActivationPage()),
        ),
      ),
    );
  }
}
