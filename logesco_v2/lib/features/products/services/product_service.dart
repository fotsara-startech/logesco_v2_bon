import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/product.dart';

class HttpProductService {
  final AuthService _authService;

  HttpProductService(this._authService);

  /// Récupère la liste des produits
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int limit = 100,
    String? search,
    bool? isActive,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}').replace(queryParameters: queryParams);

      print('🔄 Récupération des produits depuis: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API produits: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📦 Données JSON produits reçues');

        final products = <Product>[];
        final dataList = jsonData['data'] as List;

        for (final item in dataList) {
          try {
            final product = Product.fromJson(item as Map<String, dynamic>);
            products.add(product);
          } catch (e) {
            print('⚠️ Erreur parsing produit, ignoré: $e');
          }
        }

        print('✅ ${products.length} produits récupérés avec succès');
        return ApiResponse.success(
          products,
          pagination: jsonData['pagination'] != null ? Pagination.fromJson(jsonData['pagination']) : null,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération des produits');
      }
    } catch (e) {
      print('💥 Erreur de connexion produits: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un produit par son ID
  Future<Product?> getProductById(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Product.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du produit');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Importe des produits en lot
  Future<List<Product>> importProducts(List<ProductForm> products) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final productsData = products.map((p) => p.toJson()).toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/import'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'products': productsData}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final importedData = jsonData['data']['imported'] as List;
        return importedData.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'import des produits');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère tous les produits pour l'export
  Future<List<Product>> getAllProducts() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final productsData = jsonData['data'] as List;
        return productsData.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération des produits');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
