import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../services/inventory_service.dart';
import '../../products/controllers/product_getx_controller.dart';
import '../../products/services/api_product_service.dart';
import '../../products/services/category_service.dart';

/// Binding pour les dépendances du module inventory
class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 Configuration InventoryBinding');

    // Services
    if (!Get.isRegistered<InventoryService>()) {
      Get.lazyPut<InventoryService>(() {
        print('  - Création InventoryService');
        return InventoryService(Get.find());
      });
    }

    if (!Get.isRegistered<ApiProductService>()) {
      Get.lazyPut<ApiProductService>(() {
        print('  - Création ApiProductService');
        return ApiProductService();
      });
    }

    // Service de catégories (partagé avec le module produits)
    if (!Get.isRegistered<CategoryService>()) {
      Get.lazyPut<CategoryService>(
        () {
          print('  - Création CategoryService');
          return CategoryService();
        },
        fenix: true,
      );
    }

    // Contrôleurs
    if (!Get.isRegistered<InventoryGetxController>()) {
      Get.put<InventoryGetxController>(
        InventoryGetxController(),
        permanent: true,
      );
      print('  - Création InventoryGetxController');
    }

    if (!Get.isRegistered<ProductGetxController>()) {
      Get.lazyPut<ProductGetxController>(() {
        print('  - Création ProductGetxController');
        return ProductGetxController();
      });
    }
  }
}
