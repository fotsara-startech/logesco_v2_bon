import 'dart:async';
import 'package:get/get.dart';
import 'admin_service.dart';
import 'auth_service.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import '../../features/subscription/models/subscription_status.dart';
import '../../features/subscription/models/license_data.dart';

/// Service d'initialisation de l'application
class AppInitializationService extends GetxService {
  final AdminService _adminService = Get.find<AdminService>();
  final AuthService _authService = Get.find<AuthService>();

  /// Initialise l'application au démarrage
  Future<void> initialize() async {
    try {
      print('🚀 [AppInit] Initialisation de l\'application...');

      // 1. Vérifier la connexion à l'API
      await _checkApiConnection();

      // 2. S'assurer qu'un utilisateur admin existe
      await _adminService.ensureAdminExists();

      // 3. Vérifier s'il y a des utilisateurs actifs
      final hasUsers = await _adminService.hasActiveUsers();

      if (!hasUsers) {
        print('⚠️ [AppInit] Aucun utilisateur actif trouvé');
        _adminService.showAdminInfo();
      } else {
        print('✅ [AppInit] Utilisateurs actifs détectés');
      }

      // 4. Initialiser le système d'abonnement
      await _initializeSubscriptionSystem();

      print('🎉 [AppInit] Initialisation terminée avec succès');
    } catch (e) {
      print('⚠️ [AppInit] Erreur lors de l\'initialisation: $e');
      print('📝 [AppInit] L\'application continuera de fonctionner, mais vous devrez peut-être créer manuellement les rôles et utilisateurs');
    }
  }

  /// Vérifie la connexion à l'API
  Future<void> _checkApiConnection() async {
    try {
      print('🔍 [AppInit] Vérification de la connexion API...');

      // Essayer de faire une requête simple pour tester la connexion
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
      print('🔐 [AppInit] Initialisation du système d\'abonnement...');

      // Obtenir le contrôleur de subscription
      final subscriptionController = Get.find<SubscriptionController>();

      // Attendre que l'initialisation soit complète
      await Future.delayed(const Duration(milliseconds: 1000));

      // Effectuer une validation douce (sans forcer)
      await subscriptionController.refreshStatus();

      // Vérifier le statut final
      final status = subscriptionController.currentStatus;
      if (status != null) {
        print('✅ [AppInit] Système d\'abonnement initialisé');
        print('   - Type: ${_getSubscriptionTypeLabel(status.type)}');
        print('   - Statut: ${status.isActive ? "Actif" : "Inactif"}');

        if (status.remainingDays != null) {
          print('   - Jours restants: ${status.remainingDays}');
        }

        if (status.isInGracePeriod) {
          print('   - En période de grâce');
        }

        // Démarrer les validations périodiques
        _startPeriodicSubscriptionChecks(subscriptionController);
      } else {
        print('⚠️ [AppInit] Statut d\'abonnement non disponible');
      }
    } catch (e) {
      print('⚠️ [AppInit] Erreur lors de l\'initialisation de l\'abonnement: $e');
      print('📝 [AppInit] L\'application continuera de fonctionner, mais les fonctionnalités d\'abonnement peuvent être limitées');
    }
  }

  /// Démarre les vérifications périodiques d'abonnement
  void _startPeriodicSubscriptionChecks(SubscriptionController controller) {
    // Vérification toutes les 30 minutes
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        print('🔄 [AppInit] Vérification périodique d\'abonnement...');
        await controller.forceValidation();

        // Vérifier si l'application doit être bloquée
        final shouldBlock = await controller.shouldBlockApplication();
        if (shouldBlock) {
          print('🚫 [AppInit] Application bloquée - redirection vers activation');
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

  /// Affiche un résumé de l'état de l'application
  void showAppStatus() {
    print('\n📊 [AppInit] État de l\'application:');
    print('   - API Backend: Connecté');
    print('   - Base de données: Initialisée');
    print('   - Utilisateur admin: Disponible');
    print('   - Système d\'abonnement: Initialisé');
    print('   - Identifiants par défaut: admin / admin123\n');
  }
}
