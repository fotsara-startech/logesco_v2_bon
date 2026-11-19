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
        _showSubscriptionError('Statut d\'abonnement non disponible', 'subscription_impossible_verifier_votre_abonnement'.tr);
        return false;
      }

      if (!status.isActive && !status.isInGracePeriod) {
        _showSubscriptionError(
          'subscription_expired_title'.tr,
          actionName != null ? 'subscription_action_named_requires_active'.trParams({'action': actionName}) : 'subscription_action_necessite_abonnement_actif_2'.tr,
        );
        return false;
      }

      if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) {
        _showSubscriptionError(
          'subscription_grace_period'.tr,
          actionName != null ? 'subscription_action_named_not_allowed_grace'.trParams({'action': actionName}) : 'subscription_action_n_est_pas_autorise_periode'.tr,
        );
        return false;
      }

      final shouldBlock = await subscriptionController.shouldBlockApplication();
      if (shouldBlock) {
        _showSubscriptionError('subscription_accetes_bloque'.tr, 'subscription_application_est_temporairement_bloquee_activez_licence'.tr);
        return false;
      }

      return true;
    } catch (e) {
      _showSubscriptionError('subscription_erreur_vrification'.tr, 'subscription_impossible_verifier_votre_abonnement'.tr);
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
        'subscription_premium_feature_title'.tr,
        featureName != null ? 'subscription_feature_named_requires_paid'.trParams({'feature': featureName}) : 'subscription_fonctionnalit_necessite_abonnement_payant'.tr,
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
          _showSubscriptionWarning('lbl_attention_required'.tr, notifications.first);
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
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Get.theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message),
              ],
            )),
          ],
        ),
        backgroundColor: Get.theme.colorScheme.errorContainer,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Activer',
          textColor: Get.theme.colorScheme.primary,
          onPressed: () => Get.to(() => const LicenseActivationPage()),
        ),
      ),
    );
  }

  void _showSubscriptionWarning(String title, String message) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Get.theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message),
              ],
            )),
          ],
        ),
        backgroundColor: Get.theme.colorScheme.secondaryContainer,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Renouveler',
          textColor: Get.theme.colorScheme.primary,
          onPressed: () => Get.to(() => const LicenseActivationPage()),
        ),
      ),
    );
  }
}
