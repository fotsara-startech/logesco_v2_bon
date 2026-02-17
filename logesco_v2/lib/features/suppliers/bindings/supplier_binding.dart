import 'package:get/get.dart';
import '../controllers/supplier_controller.dart';
import '../controllers/supplier_form_controller.dart';
import '../services/supplier_service.dart';
import '../services/api_supplier_service.dart';
import '../../../core/config/app_config.dart';

/// Binding pour les dépendances du module suppliers
class SupplierBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 Configuration SupplierBinding');
    print('  - UseMockServices: ${AppConfig.useMockServices}');

    // Service - toujours utiliser le vrai service API
    Get.lazyPut<SupplierService>(() {
      print('  - Création ApiSupplierService');
      return ApiSupplierService();
    });

    // Contrôleurs
    Get.lazyPut<SupplierController>(() {
      print('  - Création SupplierController');
      return SupplierController();
    });

    Get.lazyPut<SupplierFormController>(() {
      print('  - Création SupplierFormController');
      return SupplierFormController();
    });
  }
}
