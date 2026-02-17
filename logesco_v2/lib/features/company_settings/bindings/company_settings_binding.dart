import 'package:get/get.dart';
import '../controllers/company_settings_controller.dart';

class CompanySettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanySettingsController>(
      () => CompanySettingsController(),
    );
  }
}
