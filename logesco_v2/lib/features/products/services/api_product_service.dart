import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
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
    final response = await _apiClient.get<Map<String, dynamic>>('/products/$id');

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le produit directement dans 'data'
      final productData = response.data!['data'] as Map<String, dynamic>;

      final product = Product.fromJson(productData);

      // Résoudre le nom de la catégorie si le service est disponible
      if (_categoryResolver != null) {
        final resolvedProduct = await _categoryResolver!.resolveProductCategory(product);
        return resolvedProduct;
      }

      return product;
    }

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
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>('/products/$id');
      return response.isSuccess;
    } catch (e) {
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

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/products/import',
      {'products': productsData},
    );

    if (response.isSuccess && response.data != null) {
      try {
        // Vérifier si la réponse contient les données attendues
        if (response.data!.containsKey('data')) {
          final responseData = response.data!['data'] as Map<String, dynamic>;

          // Vérifier s'il y a des erreurs dans la réponse
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'] as List<dynamic>;
            if (errors.isNotEmpty) {
              // Vérifier le résumé
              if (responseData.containsKey('summary')) {
                final summary = responseData['summary'] as Map<String, dynamic>;
                final imported = summary['imported'] as int;
                final errorCount = summary['errors'] as int;

                if (imported == 0 && errorCount > 0) {
                  throw Exception('Aucun produit n\'a pu être importé. Erreur backend: ${errors.first['error']}');
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
        return [];
      } catch (e) {
        rethrow; // Relancer l'exception pour qu'elle soit gérée par le contrôleur
      }
    }

    throw Exception('Erreur lors de l\'import des produits: ${response.message ?? 'Réponse invalide'}');
  }

  /// Upload ou remplace l'image d'un produit
  Future<String?> uploadProductImage(int productId, String filePath) async {
    try {
      final token = await Get.find<AuthService>().getToken();
      if (token == null) throw Exception('Token manquant');

      final uri = Uri.parse('${AppConfig.currentBaseUrl}/products/$productId/image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        filePath,
        contentType: _mimeTypeFromPath(filePath),
      );
      request.files.add(multipartFile);

      debugPrint('📤 Upload image: uri=$uri, file=$filePath, field=${multipartFile.field}, length=${multipartFile.length}');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('📥 Upload response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
        return data?['imageUrl'] as String?;
      }
      throw Exception('Erreur upload image: ${response.statusCode} - ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime l'image d'un produit
  Future<bool> deleteProductImage(int productId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/products/$productId/image',
    );
    return response.isSuccess;
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

  /// Détermine le MIME type à partir de l'extension du fichier
  MediaType _mimeTypeFromPath(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
