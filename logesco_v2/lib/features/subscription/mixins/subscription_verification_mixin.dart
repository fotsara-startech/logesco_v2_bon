import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_status.dart';
import '../models/license_data.dart';
import '../views/license_activation_page.dart';
import '../../../../core/config/app_config.dart';

/// Mixin pour ajouter des vrifications d'abonnement aux contrleurs
mixin SubscriptionVerificationMixin {
  SubscriptionController? _subscriptionController;

  SubscriptionController get subscriptionController {
    _subscriptionController ??= Get.find<SubscriptionController>();
    return _subscriptionController!;
  }

  /// Vrifie si l'abonnement est actif avant d'excuter une action
  Future<bool> verifySubscriptionForAction({
    bool requireActiveSubscription = true,
    bool allowGracePeriod = false,
    String? actionName,
  }) async {
    // Contrle de licence dÊtesactiv - toujours autoriser
    if (!AppConfig.enableLicenseControl) return true;

    try {
      final status = subscriptionController.currentStatus;

      if (status == null) {
        _showSubscriptionError('Statut d\'abonnement non disponible', 'Impossible de vérifier votre abonnement.');
        return false;
      }

      if (!status.isActive && !status.isInGracePeriod) {
        _showSubscriptionError(
          'Abonnement expir',
          actionName != null ? 'L\'action "$actionName" nécessite un abonnement actif.' : 'Cette action nécessite un abonnement actif.',
        );
        return false;
      }

      if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) {
        _showSubscriptionError(
          'Période de grâce',
          actionName != null ? 'L\'action "$actionName" n\'est pas autorise en Période de grâce.' : 'Cette action n\'est pas autorise en Période de grâce.',
        );
        return false;
      }

      final shouldBlock = await subscriptionController.shouldBlockApplication();
      if (shouldBlock) {
        _showSubscriptionError('AccÊtes BLOQUÉ', 'L\'application est temporairement BLOQUÉe. Activez une licence pour continuer.');
        return false;
      }

      return true;
    } catch (e) {
      _showSubscriptionError('Erreur de vrification', 'Impossible de vérifier votre abonnement.');
      return false;
    }
  }

  Future<bool> verifySubscriptionForWrite({String? actionName}) async {
    return await verifySubscriptionForAction(requireActiveSubscription: true, allowGracePeriod: false, actionName: actionName);
  }

  Future<bool> verifySubscriptionForRead({String? actionName}) async {
    return await verifySubscriptionForAction(requireActiveSubscription: false, allowGracePeriod: true, actionName: actionName);
  }

  Future<bool> verifySubscriptionForPremium({String? featureName}) async {
    if (!AppConfig.enableLicenseControl) return true;

    final canProceed = await verifySubscriptionForAction(requireActiveSubscription: true, allowGracePeriod: false, actionName: featureName);
    if (!canProceed) return false;

    final status = subscriptionController.currentStatus;
    if (status?.type == SubscriptionType.trial) {
      _showSubscriptionError(
        'Fonctionnalit premium',
        featureName != null ? 'La fonctionnalit "$featureName" nécessite un abonnement payant.' : 'Cette fonctionnalit nécessite un abonnement payant.',
      );
      return false;
    }

    return true;
  }

  Future<void> checkAndShowSubscriptionWarnings() async {
    if (!AppConfig.enableLicenseControl) return;

    try {
      final status = subscriptionController.currentStatus;
      if (status == null) return;

      if (subscriptionController.shouldShowCriticalNotifications()) {
        final notifications = await subscriptionController.getExpirationNotifications();
        if (notifications.isNotEmpty) {
          _showSubscriptionWarning('Attention requise', notifications.first);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  SubscriptionStatus? get currentSubscriptionStatus {
    try {
      return subscriptionController.currentStatus;
    } catch (e) {
      return null;
    }
  }

  bool get isInTrialPeriod {
    final status = currentSubscriptionStatus;
    return status?.type == SubscriptionType.trial && status?.isActive == true;
  }

  bool get isInGracePeriod => currentSubscriptionStatus?.isInGracePeriod == true;

  int? get remainingDays => currentSubscriptionStatus?.remainingDays;

  void _showSubscriptionError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
      icon: Icon(Icons.error, color: Get.theme.colorScheme.error),
      duration: const Duration(seconds: 6),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          Get.to(() => const LicenseActivationPage());
        },
        child: Text('Activer', style: TextStyle(color: Get.theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showSubscriptionWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.secondaryContainer,
      colorText: Get.theme.colorScheme.onSecondaryContainer,
      icon: Icon(Icons.warning, color: Get.theme.colorScheme.secondary),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          Get.to(() => const LicenseActivationPage());
        },
        child: Text('Renouveler', style: TextStyle(color: Get.theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
