import 'package:get/get.dart';
import '../controllers/ledger_controller.dart';

/// Injection du contrôleur de la comptabilité en partie double
class LedgerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LedgerController>(() => LedgerController());
  }
}
