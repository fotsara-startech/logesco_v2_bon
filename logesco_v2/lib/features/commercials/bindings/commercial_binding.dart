import 'package:get/get.dart';
import '../controllers/commercial_controller.dart';
import '../controllers/commercial_form_controller.dart';
import '../controllers/commercial_report_controller.dart';
import '../services/commercial_service.dart';
import '../services/api_commercial_service.dart';
import '../services/commercial_report_service.dart';

/// Binding pour les dépendances du module commercials (villes/zones/commerciaux)
class CommercialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommercialService>(() => ApiCommercialService());
    Get.lazyPut<CommercialController>(() => CommercialController());
    Get.lazyPut<CommercialFormController>(() => CommercialFormController());
    Get.lazyPut<CommercialReportService>(() => CommercialReportService());
    Get.lazyPut<CommercialReportController>(() => CommercialReportController());
  }
}
