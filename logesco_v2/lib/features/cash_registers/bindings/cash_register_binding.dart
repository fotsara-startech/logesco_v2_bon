import 'package:get/get.dart';
import '../controllers/cash_register_controller.dart';
import '../controllers/cash_session_controller.dart';

/// Binding pour les caisses et sessions
class CashRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CashRegisterController>(() => CashRegisterController());
    Get.lazyPut<CashSessionController>(() => CashSessionController());
  }
}
