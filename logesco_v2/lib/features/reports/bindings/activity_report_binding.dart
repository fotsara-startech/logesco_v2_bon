import 'package:get/get.dart';
import 'package:logesco_v2/features/accounts/services/account_service.dart';
import '../controllers/activity_report_controller.dart';
import '../services/activity_report_service.dart';
import '../services/pdf_export_service.dart';
import '../../../core/services/auth_service.dart';

/// Binding pour le module de bilan comptable d'activités
class ActivityReportBinding extends Bindings {
  @override
  void dependencies() {
    print('📊 [ActivityReportBinding] Initialisation des dépendances...');
    
    // Vérifier que les services de base sont disponibles
    try {
      final authService = Get.find<AuthService>();
      print('✅ [ActivityReportBinding] AuthService trouvé: ${authService.runtimeType}');
    } catch (e) {
      print('❌ [ActivityReportBinding] AuthService non trouvé: $e');
    }
    
    try {
      final accountService = Get.find<AccountService>();
      print('✅ [ActivityReportBinding] AccountService trouvé: ${accountService.runtimeType}');
    } catch (e) {
      print('❌ [ActivityReportBinding] AccountService non trouvé: $e');
    }
    
    // Services
    Get.lazyPut<ActivityReportService>(
      () => ActivityReportService(Get.find<AuthService>()),
    );
    
    Get.lazyPut<PdfExportService>(
      () => PdfExportService(),
    );
    
    // Contrôleur
    Get.lazyPut<ActivityReportController>(
      () => ActivityReportController(
        Get.find<ActivityReportService>(),
        Get.find<PdfExportService>(),
      ),
    );
    
    print('✅ [ActivityReportBinding] Toutes les dépendances initialisées');
  }
}