import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../services/account_service.dart';
import '../services/account_api_service.dart';

/// Binding pour les dépendances du module accounts
class AccountBinding extends Bindings {
  @override
  void dependencies() {
    // Service
    Get.lazyPut<AccountService>(() => AccountApiService());

    // Contrôleur
    Get.lazyPut<AccountController>(() => AccountController());
  }
}
