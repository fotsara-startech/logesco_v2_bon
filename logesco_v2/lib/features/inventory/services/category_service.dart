import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';

/// Service pour récupérer les catégories de produits
class CategoryService {
  final AuthService _authService;

  CategoryService(this._authService);

  /// Récupère la liste des catégories distinctes depuis les produits
  Future<List<String>> getCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        // Retourner des catégories par défaut en cas d'erreur
        return _getDefaultCategories();
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categoriesData = jsonData['data'] as List;
        
        // Extraire les noms de catégories et filtrer les valeurs nulles/vides
        final categories = categoriesData
            .map((item) => item.toString())
            .where((category) => category.isNotEmpty && category != 'null')
            .toSet() // Éliminer les doublons
            .toList();
        
        categories.sort(); // Trier alphabétiquement
        
        return categories;
      } else if (response.statusCode == 404) {
        // Endpoint pas encore implémenté, utiliser une méthode alternative
        return await _getCategoriesFromProducts();
      } else {
        return _getDefaultCategories();
      }
    } catch (e) {
      // En cas d'erreur, essayer de récupérer via les produits
      try {
        return await _getCategoriesFromProducts();
      } catch (e2) {
        return _getDefaultCategories();
      }
    }
  }

  /// Récupère les catégories en analysant tous les produits
  Future<List<String>> _getCategoriesFromProducts() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return _getDefaultCategories();
      }

      // Récupérer tous les produits avec une limite élevée
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}?limit=1000'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final productsData = jsonData['data'] as List;
        
        // Extraire les catégories des produits
        final categories = <String>{};
        for (final product in productsData) {
          final category = product['categorie']?.toString();
          if (category != null && category.isNotEmpty && category != 'null') {
            categories.add(category);
          }
        }
        
        final sortedCategories = categories.toList()..sort();
        return sortedCategories;
      } else {
        return _getDefaultCategories();
      }
    } catch (e) {
      return _getDefaultCategories();
    }
  }

  /// Retourne des catégories par défaut en cas d'erreur
  List<String> _getDefaultCategories() {
    return [
      'Alimentation',
      'Automobile',
      'Beauté & Santé',
      'Électronique',
      'Livres & Médias',
      'Maison & Jardin',
      'Sport & Loisirs',
      'Vêtements',
    ];
  }
}