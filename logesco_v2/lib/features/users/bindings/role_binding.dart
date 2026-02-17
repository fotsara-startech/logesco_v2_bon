import 'package:get/get.dart';
import '../controllers/role_controller.dart';
import '../services/role_service.dart';

/// Binding pour l'injection de dépendances des rôles
class RoleBinding extends Bindings {
  @override
  void dependencies() {
    print('🔍 RoleBinding - Injection des dépendances');

    // Service des rôles
    Get.lazyPut<RoleService>(
      () {
        print('🔍 RoleBinding - Création du RoleService');
        return RoleService();
      },
      fenix: true,
    );

    // Contrôleur des rôles
    Get.lazyPut<RoleController>(
      () {
        print('🔍 RoleBinding - Création du RoleController');
        return RoleController();
      },
      fenix: true,
    );

    print('🔍 RoleBinding - Injection terminée');
  }
}
