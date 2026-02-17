import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../financial_movements/services/movement_report_service.dart';
import '../controllers/dashboard_stats_controller.dart';
import '../../../core/services/auth_service.dart';

/// Binding pour les dépendances du dashboard
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Contrôleur d'authentification (si pas déjà créé)
    Get.lazyPut<AuthController>(() => AuthController());

    // Contrôleur des statistiques du dashboard
    Get.lazyPut<DashboardStatsController>(() => DashboardStatsController());

    // Le service de cache est déjà disponible via les bindings initiaux
    // Pas besoin de le recréer ici

    Get.lazyPut<MovementReportService>(
      () => MovementReportService(
        Get.find<AuthService>(),
      ),
      fenix: true,
    );
  }
}
