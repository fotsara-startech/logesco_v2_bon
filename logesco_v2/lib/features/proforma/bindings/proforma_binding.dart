import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../customers/services/customer_service.dart';
import '../../customers/services/api_customer_service.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/services/api_product_service.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/services/printing_service.dart';
import '../../company_settings/controllers/company_settings_controller.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../controllers/proforma_controller.dart';

class ProformaBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomerService>()) {
      Get.put<CustomerService>(ApiCustomerService());
    }
    if (!Get.isRegistered<ApiProductService>()) {
      Get.put<ApiProductService>(ApiProductService());
    }
    if (!Get.isRegistered<CustomerController>()) {
      Get.put<CustomerController>(CustomerController());
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put<ProductController>(ProductController());
    }
    if (!Get.isRegistered<SalesController>()) {
      Get.put<SalesController>(SalesController());
    }
    if (!Get.isRegistered<PrintingService>()) {
      Get.put<PrintingService>(PrintingService(Get.find<AuthService>()));
    }
    if (!Get.isRegistered<PrintingController>()) {
      Get.put<PrintingController>(PrintingController());
    }
    if (!Get.isRegistered<CompanySettingsService>()) {
      Get.put<CompanySettingsService>(CompanySettingsService(Get.find<AuthService>()));
    }
    if (!Get.isRegistered<CompanySettingsController>()) {
      Get.put<CompanySettingsController>(CompanySettingsController());
    }
    if (!Get.isRegistered<ProformaController>()) {
      Get.put<ProformaController>(ProformaController());
    }
  }
}
