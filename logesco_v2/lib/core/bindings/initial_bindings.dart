import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/authorization_service.dart';
import '../services/permission_service.dart';
import '../services/boutique_context_service.dart';
import '../services/http_boutique_service.dart';
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
import '../../features/subscription/services/implementations/secure_time_service.dart';
import '../../features/subscription/controllers/subscription_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../../features/boutiques/services/boutique_service.dart';
import '../../features/boutiques/controllers/boutique_controller.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/sync/controllers/sync_controller.dart';

/// Bindings initiaux pour l'injection de dépendances avec GetX
class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Utiliser l'URL centralisée depuis AppConfig
    final String baseUrl = AppConfig.currentBaseUrl;

    print('🔧 Configuration API - URL de base: $baseUrl');

    // Services de base
    Get.put<ApiClient>(ApiClient(), permanent: true);
    Get.put<ApiService>(ApiService(baseUrl: baseUrl), permanent: true);

    // Service de contexte boutique (TRÈS IMPORTANT - avant les autres services)
    Get.put<BoutiqueContextService>(BoutiqueContextService(), permanent: true);

    // Service HTTP avec injection automatique du boutiqueId
    Get.put<HttpBoutiqueService>(HttpBoutiqueService(), permanent: true);

    // Services métier
    Get.put<ApiProductService>(ApiProductService(), permanent: true);

    print('🔧 [InitialBindings] Injection de AccountApiService...');
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

    // Service admin
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

    Get.lazyPut(() => Get.find<AuthService>());

    // Services multi-boutique
    Get.put<BoutiqueService>(BoutiqueService(), permanent: true);
    Get.put<BoutiqueController>(BoutiqueController(), permanent: true);

    // Dashboard controller permanent (pour le rechargement lors du switch de boutique)
    Get.put<DashboardController>(DashboardController(), permanent: true);

    // Contrôleur de synchronisation cloud (Type 3 — Neon)
    Get.put<SyncController>(SyncController(), permanent: true);

    // Services d'abonnement
    _configureSubscriptionServices();
  }

  /// Configure les services d'abonnement en tant que singletons permanents
  void _configureSubscriptionServices() {
    print('🔧 [InitialBindings] Configuration des services d\'abonnement...');

    Get.put<FlutterSecureStorage>(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      ),
      permanent: true,
    );

    Get.put<CryptoService>(CryptoService(), permanent: true);
    Get.put<IDeviceService>(DeviceService(), permanent: true);

    Get.put<ILicenseService>(
      LicenseService(
        cryptoService: Get.find<CryptoService>(),
        deviceService: Get.find<IDeviceService>(),
      ),
      permanent: true,
    );

    Get.put<SecureTimeService>(SecureTimeService(), permanent: true);

    Get.put<ISubscriptionManager>(
      SubscriptionManager(
        licenseService: Get.find<ILicenseService>(),
        deviceService: Get.find<IDeviceService>(),
        cryptoService: Get.find<CryptoService>(),
        secureStorage: Get.find<FlutterSecureStorage>(),
        secureTimeService: Get.find<SecureTimeService>(),
      ),
      permanent: true,
    );

    Get.put<SubscriptionController>(
      SubscriptionController(subscriptionManager: Get.find<ISubscriptionManager>()),
      permanent: true,
    );

    print('✅ [InitialBindings] Services d\'abonnement configurés avec succès');
  }
}
