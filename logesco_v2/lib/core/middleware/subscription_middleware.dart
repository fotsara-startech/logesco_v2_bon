import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import '../../features/subscription/models/license_data.dart';
import '../config/app_config.dart';

/// Middleware pour vérifier les licences et contrôler l'accès aux fonctionnalités.
/// NOTE: Ne pas appeler Get.snackbar() ici — l'Overlay n'est pas encore monté
/// lors de la résolution des routes. Les notifications sont gérées par les pages
/// elles-mêmes via SubscriptionController.checkAndShowNotifications().
class SubscriptionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AppConfig.enableLicenseControl) return null;

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
        _scheduleDelayedCheck(subscriptionController);
        return null;
      }

      if (!status.isActive && !status.isInGracePeriod) {
        return const RouteSettings(name: '/subscription/blocked');
      }

      return null;
    } catch (e) {
      return const RouteSettings(name: '/subscription/activation');
    }
  }

  void _scheduleDelayedCheck(SubscriptionController controller) {
    Future.delayed(const Duration(seconds: 3), () {
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
}

/// Middleware spécifique pour les fonctionnalités premium.
class PremiumFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AppConfig.enableLicenseControl) return null;

    try {
      final subscriptionController = Get.find<SubscriptionController>();
      final status = subscriptionController.currentStatus;

      if (status == null || !status.isActive) {
        return const RouteSettings(name: '/subscription/activation');
      }

      if (status.type == SubscriptionType.trial) {
        final restrictedTrialRoutes = ['/reports/advanced', '/settings/advanced', '/export/bulk'];
        if (route != null && restrictedTrialRoutes.contains(route)) {
          return const RouteSettings(name: '/dashboard');
        }
      }

      return null;
    } catch (e) {
      return const RouteSettings(name: '/subscription/activation');
    }
  }
}
