import 'package:get/get.dart';
import '../services/analytics_service.dart';
import '../../../core/services/api_service.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    // Enregistrer le service analytics
    Get.lazyPut<AnalyticsService>(
      () => AnalyticsService(Get.find<ApiService>()),
      fenix: true,
    );
  }
}