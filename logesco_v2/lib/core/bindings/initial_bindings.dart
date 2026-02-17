import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../api/api_client.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/authorization_service.dart';
import '../services/permission_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/products/services/api_product_service.dart';
import '../../features/accounts/services/account_service.dart';
import '../../features/accounts/services/account_api_service.dart';
import '../../features/inventory/services/inventory_service.dart';
import '../../features/inventory/controllers/inventory_controller.dart';
import '../../features/financial_movements/services/financial_movement_cache_service.dart';
import '../../features/financial_movements/services/financial_movement_service.dart';
import '../../features/financial_movements/services/movement_report_service.dart';
import '../../features/users/services/user_service.dart';
import '../../features/users/services/role_service.dart';
import '../services/admin_service.dart';
import '../services/app_initialization_service.dart';
import '../../features/dashboard/services/dashboard_stats_service.dart';
import '../../features/reports/services/discount_report_service.dart';
import '../../features/expenses/services/expense_category_service.dart';
import '../../features/cash_registers/controllers/cash_session_controller.dart';

import '../../features/subscription/services/interfaces/i_subscription_manager.dart';
import '../../features/subscription/services/interfaces/i_license_service.dart';
import '../../features/subscription/services/interfaces/i_device_service.dart';
import '../../features/subscription/services/implementations/subscription_manager.dart';
import '../../features/subscription/services/implementations/license_service.dart';
import '../../features/subscription/services/implementations/device_service.dart';
import '../../features/subscription/services/implementations/crypto_service.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bindings initiaux pour l'injection de dépendances avec GetX
class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Déterminer l'URL de base selon la plateforme
    String baseUrl;
    if (kIsWeb) {
      // Flutter Web
      baseUrl = 'http://localhost:8080/api/v1';
    } else if (Platform.isAndroid) {
      // Émulateur Android utilise 10.0.2.2 pour accéder à localhost de l'hôte
      baseUrl = 'http://10.0.2.2:8080/api/v1';
    } else {
      // iOS, Desktop, etc.
      baseUrl = 'http://localhost:8080/api/v1';
    }

    print('🔍 Configuration API - Plateforme: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    print('🔍 Configuration API - URL de base: $baseUrl');

    // Services de base
    Get.put<ApiClient>(ApiClient(), permanent: true);
    Get.put<ApiService>(ApiService(baseUrl: baseUrl), permanent: true);

    // Services métier - utilisation d'ApiProductService pour de vraies données
    Get.put<ApiProductService>(ApiProductService(), permanent: true);

    print('🔍 [InitialBindings] Injection de AccountApiService...');
    final accountService = AccountApiService();
    Get.put<AccountService>(accountService, permanent: true);
    print('✅ [InitialBindings] AccountApiService injecté avec succès: ${accountService.runtimeType}');

    // Services d'authentification
    Get.put<AuthService>(AuthService(), permanent: true);

    // Contrôleurs d'authentification (AVANT AuthorizationService)
    Get.put<AuthController>(AuthController(), permanent: true);

    // Service d'autorisation (APRÈS AuthController)
    Get.put<AuthorizationService>(AuthorizationService(), permanent: true);

    // Service de permissions (APRÈS AuthController)
    Get.put<PermissionService>(PermissionService(), permanent: true);

    // Services utilisateurs et rôles
    Get.lazyPut(() => UserService(), fenix: true);
    Get.lazyPut(() => RoleService(), fenix: true);

    // Service admin (pour s'assurer qu'un admin existe toujours)
    Get.put<AdminService>(AdminService(), permanent: true);

    // Service d'initialisation de l'application
    Get.put<AppInitializationService>(AppInitializationService(), permanent: true);

    // Service de statistiques du dashboard
    Get.lazyPut(() => DashboardStatsService(), fenix: true);

    // Services d'inventaire
    Get.put<InventoryService>(InventoryService(Get.find<AuthService>()), permanent: true);
    Get.put<InventoryController>(InventoryController(Get.find<InventoryService>()), permanent: true);

    // Services de mouvements financiers
    Get.putAsync<FinancialMovementCacheService>(() async {
      final cacheService = FinancialMovementCacheService();
      await cacheService.init();
      return cacheService;
    }, permanent: true);

    Get.lazyPut<FinancialMovementService>(() {
      return FinancialMovementService(Get.find<AuthService>(), Get.find<FinancialMovementCacheService>());
    }, fenix: true);

    Get.put<MovementReportService>(MovementReportService(Get.find<AuthService>()), permanent: true);

    // Service de rapports de remises
    Get.put<DiscountReportService>(DiscountReportService(Get.find<AuthService>()), permanent: true);

    // Service de catégories de dépenses
    Get.put<ExpenseCategoryService>(ExpenseCategoryService(Get.find<AuthService>()), permanent: true);

    // Contrôleur de session de caisse
    Get.put<CashSessionController>(CashSessionController(), permanent: true);

    // Contrôleur de stock pour les ventes
    Get.lazyPut(() => Get.find<AuthService>());

    // Services d'abonnement - Configuration en tant que singletons permanents
    _configureSubscriptionServices();
  }

  /// Configure les services d'abonnement en tant que singletons permanents
  void _configureSubscriptionServices() {
    print('🔐 [InitialBindings] Configuration des services d\'abonnement...');

    // Services de base - singletons permanents pour la stabilité
    Get.put<FlutterSecureStorage>(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
      permanent: true,
    );

    // Services d'infrastructure - permanents pour éviter les reinitialisations
    Get.put<CryptoService>(CryptoService(), permanent: true);
    Get.put<IDeviceService>(DeviceService(), permanent: true);

    Get.put<ILicenseService>(
      LicenseService(
        cryptoService: Get.find<CryptoService>(),
        deviceService: Get.find<IDeviceService>(),
      ),
      permanent: true,
    );

    // Gestionnaire principal d'abonnements - singleton permanent
    Get.put<ISubscriptionManager>(
      SubscriptionManager(
        licenseService: Get.find<ILicenseService>(),
        deviceService: Get.find<IDeviceService>(),
        cryptoService: Get.find<CryptoService>(),
        secureStorage: Get.find<FlutterSecureStorage>(),
      ),
      permanent: true,
    );

    // Contrôleur d'abonnement - singleton permanent pour maintenir l'état
    Get.put<SubscriptionController>(
      SubscriptionController(
        subscriptionManager: Get.find<ISubscriptionManager>(),
      ),
      permanent: true,
    );

    print('✅ [InitialBindings] Services d\'abonnement configurés avec succès');
  }
}
