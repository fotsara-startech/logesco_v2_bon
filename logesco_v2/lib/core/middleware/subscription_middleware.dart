import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import '../../features/subscription/views/license_activation_page.dart';
import '../../features/subscription/models/license_data.dart';

/// Middleware pour vérifier les licences et contrôler l'accès aux fonctionnalités
class SubscriptionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    print('🔐 [SubscriptionMiddleware] Vérification licence pour route: $route');

    // Routes exemptées de la vérification de licence
    final exemptedRoutes = [
      '/login',
      '/splash',
      '/subscription/activation',
      '/subscription/status',
      '/subscription/blocked',
    ];

    if (route != null && exemptedRoutes.contains(route)) {
      print('✅ [SubscriptionMiddleware] Route exemptée: $route');
      return null;
    }

    try {
      // Obtenir le contrôleur de subscription
      final subscriptionController = Get.find<SubscriptionController>();

      // Vérifier si l'application doit être bloquée (synchrone pour le middleware)
      final status = subscriptionController.currentStatus;

      // Si le statut n'est pas encore disponible, permettre l'accès temporairement
      // Le système d'abonnement se chargera de la validation en arrière-plan
      if (status == null) {
        print('⚠️ [SubscriptionMiddleware] Statut de licence non encore disponible - accès temporaire accordé');

        // Programmer une vérification différée
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleDelayedCheck(subscriptionController, route);
        });

        return null;
      }

      // Vérifier si l'abonnement est actif
      if (!status.isActive && !status.isInGracePeriod) {
        print('❌ [SubscriptionMiddleware] Abonnement expiré, redirection vers activation');

        // Afficher un message d'information
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Abonnement expiré',
            'Votre abonnement a expiré. Activez une licence pour continuer.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
            duration: const Duration(seconds: 5),
          );
        });

        return const RouteSettings(name: '/subscription/blocked');
      }

      // Vérifier les notifications critiques
      if (subscriptionController.shouldShowCriticalNotifications()) {
        print('⚠️ [SubscriptionMiddleware] Notifications critiques détectées');

        // Afficher les notifications critiques mais permettre l'accès
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCriticalNotifications(subscriptionController);
        });
      }

      print('✅ [SubscriptionMiddleware] Accès autorisé pour la route: $route');
      return null;
    } catch (e) {
      print('❌ [SubscriptionMiddleware] Erreur lors de la vérification: $e');

      // En cas d'erreur, rediriger vers l'activation par sécurité
      return const RouteSettings(name: '/subscription/activation');
    }
  }

  /// Programme une vérification différée du statut d'abonnement
  void _scheduleDelayedCheck(SubscriptionController controller, String? route) {
    // Attendre que le système soit initialisé
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final status = controller.currentStatus;

        if (status != null && !status.isActive && !status.isInGracePeriod) {
          print('❌ [SubscriptionMiddleware] Vérification différée: abonnement expiré');

          // Rediriger vers l'activation seulement si nécessaire
          Get.offAllNamed('/subscription/activation');
        } else if (status != null) {
          print('✅ [SubscriptionMiddleware] Vérification différée: abonnement valide');
        }
      } catch (e) {
        print('⚠️ [SubscriptionMiddleware] Erreur lors de la vérification différée: $e');
      }
    });
  }

  /// Affiche les notifications critiques à l'utilisateur
  void _showCriticalNotifications(SubscriptionController controller) {
    final status = controller.currentStatus;
    if (status == null) return;

    String title = 'Attention requise';
    String message = '';
    Color backgroundColor = Colors.orange.shade100;
    Color textColor = Colors.orange.shade800;
    IconData icon = Icons.warning;

    if (status.isInGracePeriod) {
      title = 'Période de grâce';
      message = 'Votre abonnement est en période de grâce. Renouvelez maintenant pour éviter l\'interruption du service.';
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.error;
    } else if (status.remainingDays != null && status.remainingDays! <= 1) {
      title = 'Expiration imminente';
      message = status.remainingDays == 0 ? 'Votre abonnement expire aujourd\'hui!' : 'Votre abonnement expire demain!';
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.error;
    } else if (status.remainingDays != null && status.remainingDays! <= 3) {
      message = 'Votre abonnement expire dans ${status.remainingDays} jours.';
    }

    if (message.isNotEmpty) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: backgroundColor,
        colorText: textColor,
        icon: Icon(icon, color: textColor),
        duration: const Duration(seconds: 8),
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // Fermer le snackbar
            Get.to(() => const LicenseActivationPage());
          },
          child: Text(
            'Activer',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}

/// Middleware spécifique pour les fonctionnalités premium
class PremiumFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    print('💎 [PremiumFeatureMiddleware] Vérification accès premium pour: $route');

    try {
      final subscriptionController = Get.find<SubscriptionController>();
      final status = subscriptionController.currentStatus;

      if (status == null || !status.isActive) {
        print('❌ [PremiumFeatureMiddleware] Accès premium refusé');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Fonctionnalité premium',
            'Cette fonctionnalité nécessite un abonnement actif.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber.shade100,
            colorText: Colors.amber.shade800,
            icon: const Icon(Icons.star, color: Colors.amber),
            mainButton: TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => const LicenseActivationPage());
              },
              child: const Text(
                'Activer',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          );
        });

        return const RouteSettings(name: '/subscription/activation');
      }

      // Vérifier si c'est une période d'essai avec limitations
      if (status.type == SubscriptionType.trial) {
        // Certaines fonctionnalités peuvent être limitées en période d'essai
        final restrictedTrialRoutes = [
          '/reports/advanced',
          '/settings/advanced',
          '/export/bulk',
        ];

        if (route != null && restrictedTrialRoutes.contains(route)) {
          print('⚠️ [PremiumFeatureMiddleware] Fonctionnalité limitée en période d\'essai');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              'Fonctionnalité limitée',
              'Cette fonctionnalité avancée nécessite un abonnement payant.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade100,
              colorText: Colors.blue.shade800,
              icon: const Icon(Icons.info, color: Colors.blue),
              mainButton: TextButton(
                onPressed: () {
                  Get.back();
                  Get.to(() => const LicenseActivationPage());
                },
                child: const Text(
                  'Mettre à niveau',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            );
          });

          return const RouteSettings(name: '/dashboard');
        }
      }

      print('✅ [PremiumFeatureMiddleware] Accès premium autorisé');
      return null;
    } catch (e) {
      print('❌ [PremiumFeatureMiddleware] Erreur: $e');
      return const RouteSettings(name: '/subscription/activation');
    }
  }
}
