import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/authorization_service.dart';

/// Middleware pour protéger les routes selon les permissions utilisateur
class AuthMiddleware extends GetMiddleware {
  final AuthorizationService _authService = Get.put(AuthorizationService());

  @override
  RouteSettings? redirect(String? route) {
    print('🔐 [AuthMiddleware] Vérification accès route: $route');

    // Vérifier si l'utilisateur est connecté
    if (!_authService.isAuthenticated) {
      print('❌ [AuthMiddleware] Utilisateur non connecté, redirection vers login');
      return const RouteSettings(name: '/login');
    }

    // Vérifier les permissions pour la route
    if (route != null && !_authService.canAccessRoute(route)) {
      print('❌ [AuthMiddleware] Permission refusée pour la route: $route');

      // Afficher un message d'erreur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Accès refusé',
          'Vous n\'avez pas les permissions nécessaires pour accéder à cette page',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.block, color: Colors.red),
        );
      });

      // Rediriger vers le dashboard
      return const RouteSettings(name: '/dashboard');
    }

    print('✅ [AuthMiddleware] Accès autorisé pour la route: $route');
    return null; // Continuer vers la route demandée
  }
}

/// Middleware spécifique pour les routes d'administration
class AdminMiddleware extends GetMiddleware {
  final AuthorizationService _authService = Get.find<AuthorizationService>();

  @override
  RouteSettings? redirect(String? route) {
    print('👑 [AdminMiddleware] Vérification privilèges admin pour: $route');

    if (!_authService.isAuthenticated) {
      print('❌ [AdminMiddleware] Utilisateur non connecté');
      return const RouteSettings(name: '/login');
    }

    if (!_authService.isAdmin) {
      print('❌ [AdminMiddleware] Privilèges administrateur requis');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Accès refusé',
          'Cette page est réservée aux administrateurs',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
        );
      });

      return const RouteSettings(name: '/dashboard');
    }

    print('✅ [AdminMiddleware] Accès administrateur autorisé');
    return null;
  }
}
