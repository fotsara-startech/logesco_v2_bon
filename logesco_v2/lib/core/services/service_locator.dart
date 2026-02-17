import 'package:get/get.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'error_service.dart';
import '../../features/inventory/services/inventory_service.dart';
import '../../features/inventory/controllers/inventory_controller.dart';

class ServiceLocator {
  static void init() {
    // Services de base
    Get.lazyPut<ErrorService>(
      () => ErrorService(),
      fenix: true,
    );

    Get.lazyPut<ApiService>(
      () => ApiService(
        baseUrl: ApiConfig.currentBaseUrl,
        defaultHeaders: ApiConfig.defaultHeaders,
      ),
      fenix: true,
    );

    Get.lazyPut<AuthService>(
      () => AuthService(),
      fenix: true,
    );

    // Services métier
    Get.lazyPut<InventoryService>(
      () => InventoryService(Get.find<AuthService>()),
      fenix: true,
    );



    // Contrôleurs
    Get.lazyPut<InventoryController>(
      () => InventoryController(Get.find<InventoryService>()),
      fenix: true,
    );
  }

  /// Nettoie tous les services (utile pour les tests)
  static void reset() {
    Get.reset();
  }
}
