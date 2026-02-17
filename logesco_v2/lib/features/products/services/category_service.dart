import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/category_model.dart';

/// Service pour la gestion des catégories via API
class CategoryService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  /// Récupère toutes les catégories
  Future<List<Category>> getCategories() async {
    try {
      print('🔍 CategoryService - Début appel API /categories');
      final response = await _apiService.get('/categories');
      print('🔍 CategoryService - Réponse reçue: success=${response.success}');

      if (response.success && response.data != null) {
        print('🔍 CategoryService - Data type: ${response.data.runtimeType}');
        if (response.data is List) {
          final categories = (response.data as List).map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
          print('🔍 CategoryService - ${categories.length} catégories parsées');
          return categories;
        }
      }

      print('❌ CategoryService - Erreur: ${response.message}');
      throw Exception(response.message ?? 'Erreur lors de la récupération des catégories');
    } catch (e) {
      print('❌ CategoryService - Exception: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle catégorie
  Future<Category> createCategory(Category category) async {
    try {
      final response = await _apiService.post('/categories', category.toJson());

      if (response.success && response.data != null) {
        return Category.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception(response.message ?? 'Erreur lors de la création de la catégorie');
    } catch (e) {
      print('❌ Erreur lors de la création de la catégorie: $e');
      rethrow;
    }
  }

  /// Met à jour une catégorie
  Future<Category> updateCategory(Category category) async {
    try {
      final response = await _apiService.put('/categories/${category.id}', category.toJson());

      if (response.success && response.data != null) {
        return Category.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception(response.message ?? 'Erreur lors de la mise à jour de la catégorie');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la catégorie: $e');
      rethrow;
    }
  }

  /// Supprime une catégorie
  Future<void> deleteCategory(int categoryId) async {
    try {
      final response = await _apiService.delete('/categories/$categoryId');

      if (!response.success) {
        throw Exception(response.message ?? 'Erreur lors de la suppression de la catégorie');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de la catégorie: $e');
      rethrow;
    }
  }

  /// Récupère une catégorie par ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final response = await _apiService.get('/categories/$id');

      if (response.success && response.data != null) {
        return Category.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la catégorie $id: $e');
      return null;
    }
  }
}
