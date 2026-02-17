import 'package:get/get.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import 'category_management_service.dart';

/// Service pour résoudre les noms de catégories à partir des IDs
class CategoryResolverService extends GetxService {
  final CategoryManagementService _categoryManagementService = Get.find<CategoryManagementService>();

  /// Résout le nom de la catégorie pour un produit
  Future<Product> resolveProductCategory(Product product) async {
    // Si le produit a déjà un nom de catégorie, le retourner tel quel
    if (product.categorie != null && product.categorie!.isNotEmpty) {
      return product;
    }

    // Si le produit a un categorieId, résoudre le nom
    if (product.categorieId != null) {
      try {
        final categories = await _categoryManagementService.getCategories();
        final category = categories.firstWhereOrNull((cat) => cat.id == product.categorieId);
        
        if (category != null) {
          print('🔍 Catégorie résolue: ID ${product.categorieId} → "${category.nom}"');
          return product.copyWith(categorie: category.nom);
        } else {
          print('⚠️ Catégorie ID ${product.categorieId} non trouvée');
        }
      } catch (e) {
        print('❌ Erreur résolution catégorie ID ${product.categorieId}: $e');
      }
    }

    return product;
  }

  /// Résout les noms de catégories pour une liste de produits
  Future<List<Product>> resolveProductsCategories(List<Product> products) async {
    final List<Product> resolvedProducts = [];

    // Récupérer toutes les catégories une seule fois
    final categories = await _categoryManagementService.getCategories();
    final categoryMap = {for (var cat in categories) cat.id: cat.nom};

    for (final product in products) {
      // Si le produit a déjà un nom de catégorie, le garder
      if (product.categorie != null && product.categorie!.isNotEmpty) {
        resolvedProducts.add(product);
        continue;
      }

      // Si le produit a un categorieId, résoudre le nom
      if (product.categorieId != null && categoryMap.containsKey(product.categorieId)) {
        final categoryName = categoryMap[product.categorieId]!;
        print('🔍 Catégorie résolue: ID ${product.categorieId} → "$categoryName"');
        resolvedProducts.add(product.copyWith(categorie: categoryName));
      } else {
        // Garder le produit sans catégorie
        resolvedProducts.add(product);
        if (product.categorieId != null) {
          print('⚠️ Catégorie ID ${product.categorieId} non trouvée pour ${product.reference}');
        }
      }
    }

    return resolvedProducts;
  }

  /// Trouve l'ID d'une catégorie par son nom
  Future<int?> findCategoryIdByName(String categoryName) async {
    if (categoryName.trim().isEmpty) return null;

    try {
      final categories = await _categoryManagementService.getCategories();
      final category = categories.firstWhereOrNull(
        (cat) => cat.nom.toLowerCase().trim() == categoryName.toLowerCase().trim()
      );
      
      return category?.id;
    } catch (e) {
      print('❌ Erreur recherche ID catégorie "$categoryName": $e');
      return null;
    }
  }

  /// Prépare un ProductForm avec l'ID de catégorie résolu
  Future<ProductForm> prepareProductFormWithCategoryId(ProductForm productForm) async {
    // Si pas de catégorie, retourner tel quel
    if (productForm.categorie == null || productForm.categorie!.trim().isEmpty) {
      return productForm;
    }

    // Essayer de trouver l'ID de la catégorie
    final categoryId = await findCategoryIdByName(productForm.categorie!);
    
    if (categoryId != null) {
      print('🔍 Catégorie "${productForm.categorie}" → ID: $categoryId');
      // Créer un nouveau ProductForm avec l'ID (si le modèle le supporte)
      // Pour l'instant, on garde juste le nom
      return productForm;
    } else {
      print('⚠️ Catégorie "${productForm.categorie}" non trouvée, création automatique recommandée');
      return productForm;
    }
  }
}