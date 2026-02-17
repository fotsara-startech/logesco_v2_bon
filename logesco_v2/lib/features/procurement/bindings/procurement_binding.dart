/**
 * Binding GetX pour les approvisionnements
 */

import 'package:get/get.dart';
import '../controllers/procurement_controller.dart';
import '../services/procurement_service.dart';
import '../../suppliers/controllers/supplier_controller.dart';
import '../../suppliers/services/supplier_service.dart';
import '../../suppliers/services/api_supplier_service.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/services/api_product_service.dart';

class ProcurementBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<ProcurementService>(
      () => ProcurementService(),
    );
    Get.lazyPut<SupplierService>(
      () => ApiSupplierService(),
    );
    Get.lazyPut<ApiProductService>(
      () => ApiProductService(),
    );

    // Contrôleurs
    Get.lazyPut<SupplierController>(
      () => SupplierController(),
    );
    Get.lazyPut<ProductController>(
      () => ProductController(),
    );
    Get.lazyPut<ProcurementController>(
      () => ProcurementController(Get.find<ProcurementService>()),
    );
  }
}
