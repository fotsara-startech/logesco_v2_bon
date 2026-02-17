import 'package:get/get.dart';
import '../controllers/printing_controller.dart';
import '../services/printing_service.dart';
import '../services/receipt_generation_service.dart';
import '../services/receipt_preview_service.dart';
import '../services/template_service.dart';
import '../../../core/services/auth_service.dart';

/// Binding pour l'injection de dépendances du module d'impression
class PrintingBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<PrintingService>(
      () => PrintingService(Get.find<AuthService>()),
    );

    Get.lazyPut<ReceiptGenerationService>(
      () => ReceiptGenerationService(),
    );

    Get.lazyPut<ReceiptPreviewService>(
      () => ReceiptPreviewService(),
    );

    Get.lazyPut<TemplateService>(
      () => TemplateService(),
    );

    // Contrôleur principal
    Get.lazyPut<PrintingController>(
      () => PrintingController(),
    );
  }
}
