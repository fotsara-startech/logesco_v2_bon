import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/product_form_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/category_controller.dart';
import '../services/api_product_service.dart';
import '../services/category_service.dart';
import '../services/category_management_service.dart';
import '../services/category_resolver_service.dart';

/// Binding pour l'injection de dépendances des produits
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    // Service produit (singleton)
    Get.lazyPut<ApiProductService>(
      () => ApiProductService(),
      fenix: true,
    );

    // Service catégorie (singleton)
    Get.lazyPut<CategoryService>(
      () => CategoryService(),
      fenix: true,
    );

    // Service de gestion avancée des catégories (singleton)
    Get.lazyPut<CategoryManagementService>(
      () => CategoryManagementService(),
      fenix: true,
    );

    // Service de résolution des catégories (singleton)
    Get.lazyPut<CategoryResolverService>(
      () => CategoryResolverService(),
      fenix: true,
    );

    // Contrôleur principal des produits (NE PAS initialiser automatiquement)
    // IMPORTANT: Pas de fenix: true pour éviter le partage d'état entre les modules
    Get.lazyPut<ProductController>(
      () => ProductController(),
      fenix: false, // Permet la création d'une nouvelle instance quand le contrôleur est supprimé
    );

    // Contrôleur de formulaire (créé à la demande)
    Get.lazyPut<ProductFormController>(
      () => ProductFormController(),
      fenix: true,
    );

    // Contrôleur de détail (créé à la demande)
    Get.lazyPut<ProductDetailController>(
      () => ProductDetailController(),
      fenix: true,
    );

    // Contrôleur des catégories (créé à la demande)
    Get.lazyPut<CategoryController>(
      () => CategoryController(),
      fenix: true,
    );
  }
}
