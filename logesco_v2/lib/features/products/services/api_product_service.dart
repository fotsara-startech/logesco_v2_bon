import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/product.dart';
import 'category_resolver_service.dart';

/// Service pour la gestion des produits via l'API
class ApiProductService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  CategoryResolverService? _categoryResolver;

  @override
  void onInit() {
    super.onInit();
    try {
      _categoryResolver = Get.find<CategoryResolverService>();
    } catch (e) {
      print('⚠️ CategoryResolverService non disponible: $e');
    }
  }

  /// Récupère la liste des produits avec pagination et recherche
  Future<List<Product>> getProducts({
    String? search,
    String? categorie,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }

    if (categorie != null && categorie.isNotEmpty) {
      queryParams['categorie'] = categorie;
    }

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/products?$queryString',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les produits directement dans 'data'
      final productsData = response.data!['data'] as List<dynamic>;
      return productsData.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Récupère un produit par son ID
  Future<Product?> getProductById(int id) async {
    print('🔍 ApiProductService.getProductById($id) - Début');

    final response = await _apiClient.get<Map<String, dynamic>>('/products/$id');

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le produit directement dans 'data'
      final productData = response.data!['data'] as Map<String, dynamic>;
      print('🔍 Données produit reçues: $productData');

      final product = Product.fromJson(productData);
      print('🔍 Produit parsé - categorie: "${product.categorie}", categorieId: ${product.categorieId}');

      // Résoudre le nom de la catégorie si le service est disponible
      if (_categoryResolver != null) {
        print('🔍 CategoryResolver disponible, résolution en cours...');
        final resolvedProduct = await _categoryResolver!.resolveProductCategory(product);
        print('🔍 Produit résolu - categorie: "${resolvedProduct.categorie}", categorieId: ${resolvedProduct.categorieId}');
        return resolvedProduct;
      } else {
        print('⚠️ CategoryResolver non disponible');
      }

      return product;
    }

    print('❌ Erreur API ou données nulles');
    return null;
  }

  /// Crée un nouveau produit
  Future<Product> createProduct(ProductForm productForm) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/products',
      productForm.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le produit créé directement dans 'data'
      final productData = response.data!['data'] as Map<String, dynamic>;
      return Product.fromJson(productData);
    }

    throw Exception('Erreur lors de la création du produit');
  }

  /// Met à jour un produit existant
  Future<Product> updateProduct(int id, ProductForm productForm) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/products/$id',
      productForm.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le produit mis à jour directement dans 'data'
      final productData = response.data!['data'] as Map<String, dynamic>;
      return Product.fromJson(productData);
    }

    throw Exception('Erreur lors de la mise à jour du produit');
  }

  /// Supprime un produit
  Future<bool> deleteProduct(int id) async {
    print('🗑️ Appel API DELETE /products/$id');
    print('🔑 Token présent: ${_apiClient.hasAuthToken}');

    try {
      final response = await _apiClient.delete<Map<String, dynamic>>('/products/$id');

      print('📡 Réponse DELETE:');
      print('  - Success: ${response.isSuccess}');
      print('  - Data: ${response.data}');

      return response.isSuccess;
    } catch (e) {
      print('❌ Erreur DELETE: $e');
      rethrow;
    }
  }

  /// Recherche des produits par référence, nom ou code-barre
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/products/search?q=${Uri.encodeComponent(query)}',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les produits directement dans 'data'
      final productsData = response.data!['data'] as List<dynamic>;
      return productsData.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Recherche un produit par code-barre
  Future<Product?> getProductByBarcode(String barcode) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/products/barcode/${Uri.encodeComponent(barcode)}',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le produit directement dans 'data'
      final productData = response.data!['data'] as Map<String, dynamic>;
      return Product.fromJson(productData);
    }

    return null;
  }

  /// Récupère les catégories disponibles
  Future<List<String>> getCategories() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/products/categories');

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les catégories directement dans 'data'
      final categoriesData = response.data!['data'] as List<dynamic>;
      return categoriesData.cast<String>();
    }

    return [];
  }

  /// Vérifie si une référence produit est unique
  Future<bool> isReferenceUnique(String reference, {int? excludeId}) async {
    final queryParams = <String, String>{
      'reference': reference,
    };

    if (excludeId != null) {
      queryParams['exclude_id'] = excludeId.toString();
    }

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/products/check-reference?$queryString',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne la réponse dans 'data'
      final responseData = response.data!['data'] as Map<String, dynamic>;
      return responseData['is_unique'] as bool;
    }

    return false;
  }

  /// Génère automatiquement une nouvelle référence produit
  Future<String> generateProductReference() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/products/generate-reference');

    if (response.isSuccess && response.data != null) {
      final responseData = response.data!['data'] as Map<String, dynamic>;
      return responseData['reference'] as String;
    }

    throw Exception('Erreur lors de la génération de la référence');
  }

  /// Importe des produits en lot
  Future<List<Product>> importProducts(List<ProductForm> products) async {
    final productsData = products.map((p) => p.toJson()).toList();

    print('🔄 Import de ${products.length} produits...');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/products/import',
      {'products': productsData},
    );

    print('📡 Réponse import: Success=${response.isSuccess}, Data=${response.data}');

    if (response.isSuccess && response.data != null) {
      try {
        // Vérifier si la réponse contient les données attendues
        if (response.data!.containsKey('data')) {
          final responseData = response.data!['data'] as Map<String, dynamic>;

          // Vérifier s'il y a des erreurs dans la réponse
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'] as List<dynamic>;
            if (errors.isNotEmpty) {
              print('❌ Erreurs détectées dans l\'import:');
              for (var error in errors) {
                print('  - ${error['reference']}: ${error['error']}');
              }

              // Vérifier le résumé
              if (responseData.containsKey('summary')) {
                final summary = responseData['summary'] as Map<String, dynamic>;
                final imported = summary['imported'] as int;
                final errorCount = summary['errors'] as int;

                if (imported == 0 && errorCount > 0) {
                  throw Exception('Aucun produit n\'a pu être importé. Erreur backend: ${errors.first['error']}');
                } else if (errorCount > 0) {
                  print('⚠️ Import partiel: $imported produits importés, $errorCount erreurs');
                }
              }
            }
          }

          if (responseData.containsKey('imported')) {
            final importedProducts = responseData['imported'] as List<dynamic>;

            // Si la liste est vide mais qu'il y a des erreurs, lever une exception
            if (importedProducts.isEmpty && responseData.containsKey('errors')) {
              final errors = responseData['errors'] as List<dynamic>;
              if (errors.isNotEmpty) {
                throw Exception('Import échoué: ${errors.first['error']}');
              }
            }

            return importedProducts.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
          } else if (responseData.containsKey('products')) {
            // Alternative: si les produits sont dans 'products'
            final importedProducts = responseData['products'] as List<dynamic>;
            return importedProducts.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
          }
        }

        // Si la structure est différente, essayer de parser directement
        if (response.data!.containsKey('imported')) {
          final importedProducts = response.data!['imported'] as List<dynamic>;
          return importedProducts.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
        }

        // Si aucune structure connue, retourner une liste vide mais considérer comme succès
        print('⚠️ Structure de réponse inattendue, mais import réussi');
        return [];
      } catch (e) {
        print('❌ Erreur parsing réponse import: $e');
        print('📄 Données reçues: ${response.data}');
        rethrow; // Relancer l'exception pour qu'elle soit gérée par le contrôleur
      }
    }

    throw Exception('Erreur lors de l\'import des produits: ${response.message ?? 'Réponse invalide'}');
  }

  /// Récupère tous les produits pour l'export
  Future<List<Product>> getAllProducts() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/products/all');

    if (response.isSuccess && response.data != null) {
      final productsData = response.data!['data'] as List<dynamic>;
      return productsData.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }
}
