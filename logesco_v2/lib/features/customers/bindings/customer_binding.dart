import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../controllers/customer_form_controller.dart';
import '../services/customer_service.dart';
import '../services/api_customer_service.dart';
import '../../../core/config/app_config.dart';

/// Binding pour les dépendances du module customers
class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 Configuration CustomerBinding');
    print('  - UseMockServices: ${AppConfig.useMockServices}');

    // Service - toujours utiliser le vrai service API
    Get.lazyPut<CustomerService>(() {
      print('  - Création ApiCustomerService');
      return ApiCustomerService();
    });

    // Contrôleurs
    Get.lazyPut<CustomerController>(() {
      print('  - Création CustomerController');
      return CustomerController();
    });

    Get.lazyPut<CustomerFormController>(() {
      print('  - Création CustomerFormController');
      return CustomerFormController();
    });
  }
}
