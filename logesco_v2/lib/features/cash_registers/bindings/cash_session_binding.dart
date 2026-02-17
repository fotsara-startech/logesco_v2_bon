import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';

/// Binding pour les sessions de caisse
class CashSessionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CashSessionController>(() => CashSessionController());
  }
}