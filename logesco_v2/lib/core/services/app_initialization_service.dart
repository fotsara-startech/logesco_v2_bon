import 'dart:async';
import 'package:get/get.dart';
import 'admin_service.dart';
import 'auth_service.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import '../../features/subscription/models/license_data.dart';
import '../config/app_config.dart';

/// Service d'initialisation de l'application
class AppInitializationService extends GetxService {
  final AdminService _adminService = Get.find<AdminService>();
  final AuthService _authService = Get.find<AuthService>();

  /// Initialise l'application au démarrage
  Future<void> initialize() async {
    try {
      print('🚀 [AppInit] Initialisation de l\'application...');
      print('🔧 [AppInit] Mode: ${AppConfig.isClientMode ? "CLIENT" : "SERVEUR"}');

      if (AppConfig.isClientMode) {
        // MODE CLIENT — se connecte simplement au serveur distant
        // Pas d'initialisation de base de données, pas de création d'admin
        await _initializeSubscriptionSystem();
        print('✅ [AppInit] Initialisation client terminée');
      } else {
        // MODE SERVEUR — initialisation complète
        await _checkApiConnection();
        await _adminService.ensureAdminExists();

        final hasUsers = await _adminService.hasActiveUsers();
        if (!hasUsers) {
          print('⚠️ [AppInit] Aucun utilisateur actif trouvé');
          _adminService.showAdminInfo();
        } else {
          print('✅ [AppInit] Utilisateurs actifs détectés');
        }

        await _initializeSubscriptionSystem();
        print('🎉 [AppInit] Initialisation serveur terminée avec succès');
      }
    } catch (e) {
      print('⚠️ [AppInit] Erreur lors de l\'initialisation: $e');
    }
  }

  /// Vérifie la connexion à l'API (mode serveur uniquement)
  Future<void> _checkApiConnection() async {
    try {
      print('🔍 [AppInit] Vérification de la connexion API...');
      final response = await _authService.testConnection();
      if (response) {
        print('✅ [AppInit] Connexion API établie');
      } else {
        print('⚠️ [AppInit] Connexion API non disponible');
      }
    } catch (e) {
      print('❌ [AppInit] Erreur de connexion API: $e');
      rethrow;
    }
  }

  /// Initialise le système d'abonnement
  Future<void> _initializeSubscriptionSystem() async {
    try {
      print('🔍 [AppInit] Initialisation du système d\'abonnement...');

      final subscriptionController = Get.find<SubscriptionController>();
      await Future.delayed(const Duration(milliseconds: 500));
      await subscriptionController.refreshStatus();

      final status = subscriptionController.currentStatus;
      if (status != null) {
        print('✅ [AppInit] Système d\'abonnement initialisé');
        print('   - Type: ${_getSubscriptionTypeLabel(status.type)}');
        print('   - Statut: ${status.isActive ? "Actif" : "Inactif"}');
        if (status.remainingDays != null) {
          print('   - Jours restants: ${status.remainingDays}');
        }
        _startPeriodicSubscriptionChecks(subscriptionController);
      } else {
        print('⚠️ [AppInit] Statut d\'abonnement non disponible');
      }
    } catch (e) {
      print('⚠️ [AppInit] Erreur lors de l\'initialisation de l\'abonnement: $e');
    }
  }

  /// Démarre les vérifications périodiques d'abonnement
  void _startPeriodicSubscriptionChecks(SubscriptionController controller) {
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        await controller.forceValidation();
        final shouldBlock = await controller.shouldBlockApplication();
        if (shouldBlock) {
          Get.offAllNamed('/subscription/blocked');
        }
      } catch (e) {
        print('⚠️ [AppInit] Erreur lors de la vérification périodique: $e');
      }
    });
  }

  /// Obtient le libellé du type d'abonnement
  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Période d\'essai';
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.annual:
        return 'Annuel';
      case SubscriptionType.lifetime:
        return 'Vie entière';
      default:
        return 'Inconnu';
    }
  }
}
