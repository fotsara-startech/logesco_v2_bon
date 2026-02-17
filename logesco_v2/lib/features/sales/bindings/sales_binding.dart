import 'package:get/get.dart';
import '../controllers/sales_controller.dart';

import '../../customers/controllers/customer_controller.dart';
import '../../customers/services/customer_service.dart';
import '../../customers/services/api_customer_service.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/services/api_product_service.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/services/printing_service.dart';
import '../../company_settings/controllers/company_settings_controller.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../../core/services/auth_service.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 Configuration SalesBinding');

    // Services nécessaires pour les ventes (création immédiate)
    if (!Get.isRegistered<CustomerService>()) {
      print('  - Création CustomerService');
      Get.put<CustomerService>(ApiCustomerService());
    }

    if (!Get.isRegistered<ApiProductService>()) {
      print('  - Création ApiProductService');
      Get.put<ApiProductService>(ApiProductService());
    }

    // Contrôleurs nécessaires (création immédiate)
    if (!Get.isRegistered<CustomerController>()) {
      print('  - Création CustomerController');
      Get.put<CustomerController>(CustomerController());
    }

    if (!Get.isRegistered<ProductController>()) {
      print('  - Création ProductController');
      Get.put<ProductController>(ProductController());
    }

    // Services et contrôleurs pour l'impression
    if (!Get.isRegistered<PrintingService>()) {
      print('  - Création PrintingService');
      Get.put<PrintingService>(PrintingService(Get.find<AuthService>()));
    }

    if (!Get.isRegistered<PrintingController>()) {
      print('  - Création PrintingController');
      Get.put<PrintingController>(PrintingController());
    }

    // Services et contrôleurs pour les paramètres d'entreprise
    if (!Get.isRegistered<CompanySettingsService>()) {
      print('  - Création CompanySettingsService');
      Get.put<CompanySettingsService>(CompanySettingsService(Get.find<AuthService>()));
    }

    if (!Get.isRegistered<CompanySettingsController>()) {
      print('  - Création CompanySettingsController');
      Get.put<CompanySettingsController>(CompanySettingsController());
    }

    // Contrôleur principal des ventes
    if (!Get.isRegistered<SalesController>()) {
      print('  - Création SalesController');
      Get.put<SalesController>(SalesController());
    }

    print('✅ SalesBinding configuré');
  }
}
