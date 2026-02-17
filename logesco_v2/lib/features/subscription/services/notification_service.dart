import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_status.dart';
import '../views/expiration_notification_dialog.dart';
import '../views/blocked_page.dart';

/// Service de gestion des notifications d'expiration
class SubscriptionNotificationService {
  static const String _lastNotificationKey = 'last_notification_date';
  static const String _notificationCountKey = 'notification_count';

  /// Vérifie et affiche les notifications appropriées selon le statut
  static Future<void> checkAndShowNotifications(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    // Si l'abonnement est complètement expiré (pas en période de grâce)
    if (!status.isActive && !status.isInGracePeriod) {
      await _showBlockedScreen(context, status);
      return;
    }

    // Si en période de grâce
    if (status.isInGracePeriod) {
      await _showGracePeriodNotification(context, status);
      return;
    }

    // Si l'abonnement est actif mais expire bientôt
    if (status.isActive && status.remainingDays != null) {
      await _checkExpirationWarnings(context, status);
    }
  }

  /// Affiche l'écran de blocage
  static Future<void> _showBlockedScreen(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => SubscriptionBlockedPage(
          status: status,
          isInGracePeriod: false,
        ),
      ),
      (route) => false, // Supprime toutes les routes précédentes
    );
  }

  /// Affiche la notification de période de grâce
  static Future<void> _showGracePeriodNotification(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    // Vérifier si on doit afficher la notification aujourd'hui
    if (!await _shouldShowNotificationToday()) {
      return;
    }

    await ExpirationNotificationDialog.show(
      context,
      status,
      isUrgent: true,
    );

    await _markNotificationShown();
  }

  /// Vérifie et affiche les avertissements d'expiration
  static Future<void> _checkExpirationWarnings(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    final remainingDays = status.remainingDays!;

    // Notification urgente (1 jour ou moins)
    if (remainingDays <= 1) {
      await _showUrgentNotification(context, status);
    }
    // Notification d'avertissement (3 jours ou moins)
    else if (remainingDays <= 3) {
      await _showWarningNotification(context, status);
    }
  }

  /// Affiche une notification urgente
  static Future<void> _showUrgentNotification(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    // Toujours afficher les notifications urgentes
    await ExpirationNotificationDialog.show(
      context,
      status,
      isUrgent: true,
    );
  }

  /// Affiche une notification d'avertissement
  static Future<void> _showWarningNotification(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    // Vérifier si on doit afficher la notification aujourd'hui
    if (!await _shouldShowNotificationToday()) {
      return;
    }

    await ExpirationNotificationDialog.show(
      context,
      status,
      isUrgent: false,
    );

    await _markNotificationShown();
  }

  /// Vérifie si une notification doit être affichée aujourd'hui
  static Future<bool> _shouldShowNotificationToday() async {
    try {
      final prefs = Get.find<dynamic>(); // Remplacer par votre service de préférences
      final lastNotificationDate = prefs.getString(_lastNotificationKey);
      final today = DateTime.now().toIso8601String().split('T')[0];

      return lastNotificationDate != today;
    } catch (e) {
      // En cas d'erreur, afficher la notification par sécurité
      return true;
    }
  }

  /// Marque qu'une notification a été affichée aujourd'hui
  static Future<void> _markNotificationShown() async {
    try {
      final prefs = Get.find<dynamic>(); // Remplacer par votre service de préférences
      final today = DateTime.now().toIso8601String().split('T')[0];

      await prefs.setString(_lastNotificationKey, today);

      // Incrémenter le compteur de notifications
      final currentCount = prefs.getInt(_notificationCountKey) ?? 0;
      await prefs.setInt(_notificationCountKey, currentCount + 1);
    } catch (e) {
      // Ignorer les erreurs de stockage
    }
  }

  /// Réinitialise les compteurs de notification (à appeler après activation)
  static Future<void> resetNotificationCounters() async {
    try {
      final prefs = Get.find<dynamic>(); // Remplacer par votre service de préférences
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_notificationCountKey);
    } catch (e) {
      // Ignorer les erreurs de stockage
    }
  }

  /// Affiche une notification de succès après activation
  static void showActivationSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Licence activée avec succès !',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Affiche une notification d'erreur
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Vérifie si l'application doit être bloquée
  static bool shouldBlockApplication(SubscriptionStatus? status) {
    if (status == null) return true;

    // Bloquer si l'abonnement est expiré et pas en période de grâce
    return !status.isActive && !status.isInGracePeriod;
  }

  /// Vérifie si l'application est en mode dégradé
  static bool isInDegradedMode(SubscriptionStatus? status) {
    if (status == null) return true;

    // Mode dégradé si en période de grâce ou si expire très bientôt
    return status.isInGracePeriod || (status.isActive && status.remainingDays != null && status.remainingDays! <= 1);
  }
}
