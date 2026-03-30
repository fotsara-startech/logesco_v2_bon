import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import '../../features/subscription/views/license_activation_page.dart';
import '../../features/subscription/models/license_data.dart';
import '../config/app_config.dart';

/// Middleware pour vrifier les licences et contrler l'accÊtes aux fonctionnalitÊtes
class SubscriptionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Contrle de licence dÊtesactiv - accÊtes complet
    if (!AppConfig.enableLicenseControl) {
      return null;
    }

    final exemptedRoutes = [
      '/login',
      '/splash',
      '/subscription/activation',
      '/subscription/status',
      '/subscription/blocked',
    ];

    if (route != null && exemptedRoutes.contains(route)) return null;

    try {
      final subscriptionController = Get.find<SubscriptionController>();
      final status = subscriptionController.currentStatus;

      if (status == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleDelayedCheck(subscriptionController, route);
        });
        return null;
      }

      if (!status.isActive && !status.isInGracePeriod) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Abonnement expir',
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

      if (subscriptionController.shouldShowCriticalNotifications()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCriticalNotifications(subscriptionController);
        });
      }

      return null;
    } catch (e) {
      return const RouteSettings(name: '/subscription/activation');
    }
  }

  void _scheduleDelayedCheck(SubscriptionController controller, String? route) {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final status = controller.currentStatus;
        if (status != null && !status.isActive && !status.isInGracePeriod) {
          Get.offAllNamed('/subscription/activation');
        }
      } catch (e) {
        // ignore
      }
    });
  }

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
      message = 'Votre abonnement est en Période de grâce. Renouvelez maintenant.';
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
            Get.back();
            Get.to(() => const LicenseActivationPage());
          },
          child: Text('Activer', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}

/// Middleware spcifique pour les fonctionnalitÊtes premium
class PremiumFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Contrle de licence dÊtesactiv - accÊtes complet
    if (!AppConfig.enableLicenseControl) {
      return null;
    }

    try {
      final subscriptionController = Get.find<SubscriptionController>();
      final status = subscriptionController.currentStatus;

      if (status == null || !status.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Fonctionnalit premium',
            'Cette fonctionnalit nécessite un abonnement actif.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber.shade100,
            colorText: Colors.amber.shade800,
            icon: const Icon(Icons.star, color: Colors.amber),
            mainButton: TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => const LicenseActivationPage());
              },
              child: const Text('Activer', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          );
        });
        return const RouteSettings(name: '/subscription/activation');
      }

      if (status.type == SubscriptionType.trial) {
        final restrictedTrialRoutes = ['/reports/advanced', '/settings/advanced', '/export/bulk'];
        if (route != null && restrictedTrialRoutes.contains(route)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              'Fonctionnalit limite',
              'Cette fonctionnalit avance nécessite un abonnement payant.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade100,
              colorText: Colors.blue.shade800,
              icon: const Icon(Icons.info, color: Colors.blue),
            );
          });
          return const RouteSettings(name: '/dashboard');
        }
      }

      return null;
    } catch (e) {
      return const RouteSettings(name: '/subscription/activation');
    }
  }
}
