import 'package:get/get.dart';
import '../controllers/financial_movement_controller.dart';
import '../controllers/movement_category_controller.dart';
import '../controllers/movement_report_controller.dart';

/// Binding pour les mouvements financiers
class FinancialMovementBinding extends Bindings {
  @override
  void dependencies() {
    // Les services sont déjà disponibles via les bindings initiaux
    // Pas besoin de les recréer ici

    // Contrôleurs
    Get.lazyPut<MovementCategoryController>(
      () => MovementCategoryController(),
      fenix: true,
    );

    Get.lazyPut<MovementReportController>(
      () => MovementReportController(),
      fenix: true,
    );

    Get.lazyPut<FinancialMovementController>(
      () => FinancialMovementController(),
      fenix: true,
    );
  }
}
