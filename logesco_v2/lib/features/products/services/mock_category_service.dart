import 'package:get/get.dart';
import '../models/category_model.dart';

/// Service mock pour tester les catégories sans backend
class MockCategoryService extends GetxService {
  /// Données mock
  final List<Category> _mockCategories = [
    Category(
      id: 1,
      nom: 'Smartphones',
      description: 'Téléphones intelligents et accessoires',
      dateCreation: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 2,
      nom: 'Ordinateurs',
      description: 'PC, laptops et composants informatiques',
      dateCreation: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Category(
      id: 3,
      nom: 'Accessoires',
      description: 'Câbles, chargeurs et autres accessoires',
      dateCreation: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  /// Récupère toutes les catégories (simulation)
  Future<List<Category>> getCategories() async {
    print('');

    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    print('');
    return List.from(_mockCategories);
  }

  /// Crée une nouvelle catégorie (simulation)
  Future<Category> createCategory(Category category) async {
    print('');

    await Future.delayed(const Duration(milliseconds: 300));

    final newCategory = category.copyWith(
      id: _mockCategories.length + 1,
      dateCreation: DateTime.now(),
    );

    _mockCategories.add(newCategory);
    print('');

    return newCategory;
  }

  /// Met à jour une catégorie (simulation)
  Future<Category> updateCategory(Category category) async {
    print('');

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockCategories.indexWhere((cat) => cat.id == category.id);
    if (index != -1) {
      _mockCategories[index] = category.copyWith(dateModification: DateTime.now());
      print('');
      return _mockCategories[index];
    }

    throw Exception('Catégorie non trouvée');
  }

  /// Supprime une catégorie (simulation)
  Future<void> deleteCategory(int categoryId) async {
    print('');

    await Future.delayed(const Duration(milliseconds: 300));

    _mockCategories.removeWhere((cat) => cat.id == categoryId);
    print('');

    print('');
  }

  /// Récupère une catégorie par ID (simulation)
  Future<Category?> getCategoryById(int id) async {
    print('');

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _mockCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
