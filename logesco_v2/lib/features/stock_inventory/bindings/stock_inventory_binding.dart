import 'package:get/get.dart';
import '../controllers/stock_inventory_controller.dart';
import '../../products/services/category_service.dart';

/// Binding pour l'inventaire de stock
class StockInventoryBinding extends Bindings {
  @override
  void dependencies() {
    // Service de catégories (partagé avec le module produits)
    Get.lazyPut<CategoryService>(
      () => CategoryService(),
      fenix: true,
    );
    
    // Contrôleur d'inventaire de stock
    Get.lazyPut<StockInventoryController>(() => StockInventoryController());
  }
}
