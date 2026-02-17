import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';

/// Binding pour l'injection de dépendances du module comptable
class AccountingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountingController>(
      () => AccountingController(),
    );
  }
}
