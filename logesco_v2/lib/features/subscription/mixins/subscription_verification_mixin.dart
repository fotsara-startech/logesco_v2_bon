import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_status.dart';
import '../models/license_data.dart';
import '../views/license_activation_page.dart';

/// Mixin pour ajouter des vérifications d'abonnement aux contrôleurs
mixin SubscriptionVerificationMixin {
  SubscriptionController? _subscriptionController;

  /// Obtient le contrôleur d'abonnement
  SubscriptionController get subscriptionController {
    _subscriptionController ??= Get.find<SubscriptionController>();
    return _subscriptionController!;
  }

  /// Vérifie si l'abonnement est actif avant d'exécuter une action
  Future<bool> verifySubscriptionForAction({
    bool requireActiveSubscription = true,
    bool allowGracePeriod = false,
    String? actionName,
  }) async {
    try {
      final status = subscriptionController.currentStatus;

      // Si pas de statut disponible, bloquer par sécurité
      if (status == null) {
        _showSubscriptionError(
          'Statut d\'abonnement non disponible',
          'Impossible de vérifier votre abonnement. Veuillez réessayer.',
        );
        return false;
      }

      // Si l'abonnement est complètement expiré
      if (!status.isActive && !status.isInGracePeriod) {
        _showSubscriptionError(
          'Abonnement expiré',
          actionName != null ? 'L\'action "$actionName" nécessite un abonnement actif.' : 'Cette action nécessite un abonnement actif.',
        );
        return false;
      }

      // Si en période de grâce et que ce n'est pas autorisé
      if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) {
        _showSubscriptionError(
          'Période de grâce',
          actionName != null ? 'L\'action "$actionName" n\'est pas autorisée en période de grâce.' : 'Cette action n\'est pas autorisée en période de grâce.',
        );
        return false;
      }

      // Vérifier si l'application doit être bloquée
      final shouldBlock = await subscriptionController.shouldBlockApplication();
      if (shouldBlock) {
        _showSubscriptionError(
          'Accès bloqué',
          'L\'application est temporairement bloquée. Activez une licence pour continuer.',
        );
        return false;
      }

      return true;
    } catch (e) {
      print('❌ [SubscriptionVerification] Erreur lors de la vérification: $e');
      _showSubscriptionError(
        'Erreur de vérification',
        'Impossible de vérifier votre abonnement. Veuillez réessayer.',
      );
      return false;
    }
  }

  /// Vérifie l'abonnement pour les opérations de création/modification
  Future<bool> verifySubscriptionForWrite({String? actionName}) async {
    return await verifySubscriptionForAction(
      requireActiveSubscription: true,
      allowGracePeriod: false,
      actionName: actionName,
    );
  }

  /// Vérifie l'abonnement pour les opérations de lecture (plus permissif)
  Future<bool> verifySubscriptionForRead({String? actionName}) async {
    return await verifySubscriptionForAction(
      requireActiveSubscription: false,
      allowGracePeriod: true,
      actionName: actionName,
    );
  }

  /// Vérifie l'abonnement pour les fonctionnalités premium
  Future<bool> verifySubscriptionForPremium({String? featureName}) async {
    final canProceed = await verifySubscriptionForAction(
      requireActiveSubscription: true,
      allowGracePeriod: false,
      actionName: featureName,
    );

    if (!canProceed) return false;

    final status = subscriptionController.currentStatus;

    // Vérifier si c'est une période d'essai avec limitations
    if (status?.type == SubscriptionType.trial) {
      _showSubscriptionError(
        'Fonctionnalité premium',
        featureName != null ? 'La fonctionnalité "$featureName" nécessite un abonnement payant.' : 'Cette fonctionnalité nécessite un abonnement payant.',
      );
      return false;
    }

    return true;
  }

  /// Vérifie l'abonnement et affiche des avertissements si nécessaire
  Future<void> checkAndShowSubscriptionWarnings() async {
    try {
      final status = subscriptionController.currentStatus;
      if (status == null) return;

      // Afficher les notifications critiques si nécessaire
      if (subscriptionController.shouldShowCriticalNotifications()) {
        final notifications = await subscriptionController.getExpirationNotifications();
        if (notifications.isNotEmpty) {
          _showSubscriptionWarning(
            'Attention requise',
            notifications.first,
          );
        }
      }
    } catch (e) {
      print('❌ [SubscriptionVerification] Erreur lors de la vérification des avertissements: $e');
    }
  }

  /// Obtient le statut actuel de l'abonnement
  SubscriptionStatus? get currentSubscriptionStatus {
    try {
      return subscriptionController.currentStatus;
    } catch (e) {
      print('❌ [SubscriptionVerification] Erreur lors de l\'obtention du statut: $e');
      return null;
    }
  }

  /// Vérifie si l'utilisateur est en période d'essai
  bool get isInTrialPeriod {
    final status = currentSubscriptionStatus;
    return status?.type == SubscriptionType.trial && status?.isActive == true;
  }

  /// Vérifie si l'utilisateur est en période de grâce
  bool get isInGracePeriod {
    return currentSubscriptionStatus?.isInGracePeriod == true;
  }

  /// Obtient les jours restants avant expiration
  int? get remainingDays {
    return currentSubscriptionStatus?.remainingDays;
  }

  /// Affiche une erreur d'abonnement avec option d'activation
  void _showSubscriptionError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
      icon: Icon(
        Icons.error,
        color: Get.theme.colorScheme.error,
      ),
      duration: const Duration(seconds: 6),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Fermer le snackbar
          Get.to(() => const LicenseActivationPage());
        },
        child: Text(
          'Activer',
          style: TextStyle(
            color: Get.theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Affiche un avertissement d'abonnement
  void _showSubscriptionWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.secondaryContainer,
      colorText: Get.theme.colorScheme.onSecondaryContainer,
      icon: Icon(
        Icons.warning,
        color: Get.theme.colorScheme.secondary,
      ),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          Get.to(() => const LicenseActivationPage());
        },
        child: Text(
          'Renouveler',
          style: TextStyle(
            color: Get.theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
