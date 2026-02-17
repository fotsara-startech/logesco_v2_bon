import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../services/user_service.dart';

/// Binding pour l'injection de dépendances du module utilisateurs
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserService>(() => UserService());
    Get.lazyPut<UserController>(() => UserController());
  }
}
