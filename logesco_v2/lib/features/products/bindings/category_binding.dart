import 'package:get/get.dart';
import '../services/category_service.dart';
import '../services/category_management_service.dart';
import '../services/category_resolver_service.dart';

/// Binding pour les services de catégories
class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    // Enregistrer le service de base des catégories
    Get.lazyPut<CategoryService>(() => CategoryService());

    // Enregistrer le service de gestion avancée des catégories
    Get.lazyPut<CategoryManagementService>(() => CategoryManagementService());

    // Enregistrer le service de résolution des catégories
    Get.lazyPut<CategoryResolverService>(() => CategoryResolverService());
  }
}
