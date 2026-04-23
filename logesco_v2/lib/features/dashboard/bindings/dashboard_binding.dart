import 'package:get/get.dart';
import '../../financial_movements/services/movement_report_service.dart';
import '../controllers/dashboard_stats_controller.dart';
import '../../../core/services/auth_service.dart';

/// Binding pour les dépendances du dashboard
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController est permanent — ne jamais le recréer ici
    // Il est déjà enregistré dans InitialBindings

    // Contrôleur des statistiques du dashboard
    Get.lazyPut<DashboardStatsController>(() => DashboardStatsController());

    Get.lazyPut<MovementReportService>(
      () => MovementReportService(
        Get.find<AuthService>(),
      ),
      fenix: true,
    );
  }
}
