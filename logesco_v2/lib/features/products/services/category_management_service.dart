import 'package:get/get.dart';
import '../models/category_model.dart';
import 'category_service.dart';

/// Service avancé pour la gestion intelligente des catégories
class CategoryManagementService extends GetxService {
  final CategoryService _categoryService = Get.find<CategoryService>();
  
  // Cache des catégories pour éviter les appels répétés
  final RxList<Category> _cachedCategories = <Category>[].obs;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Récupère les catégories avec cache
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    // Vérifier si le cache est valide
    if (!forceRefresh && 
        _cachedCategories.isNotEmpty && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration) {
      print('📋 Utilisation du cache des catégories (${_cachedCategories.length} catégories)');
      return _cachedCategories.toList();
    }

    try {
      print('🔄 Rechargement des catégories depuis l\'API');
      final categories = await _categoryService.getCategories();
      
      // Mettre à jour le cache
      _cachedCategories.assignAll(categories);
      _lastCacheUpdate = DateTime.now();
      
      print('✅ Cache des catégories mis à jour (${categories.length} catégories)');
      return categories;
    } catch (e) {
      print('❌ Erreur lors du rechargement des catégories: $e');
      // Retourner le cache même s'il est expiré en cas d'erreur
      return _cachedCategories.toList();
    }
  }

  /// Vérifie si une catégorie existe par nom
  Future<Category?> findCategoryByName(String categoryName) async {
    if (categoryName.trim().isEmpty) return null;
    
    final categories = await getCategories();
    return categories.firstWhereOrNull(
      (cat) => cat.nom.toLowerCase().trim() == categoryName.toLowerCase().trim()
    );
  }

  /// Crée une catégorie si elle n'existe pas
  Future<Category> createCategoryIfNotExists(String categoryName, {String? description}) async {
    if (categoryName.trim().isEmpty) {
      throw Exception('Le nom de la catégorie ne peut pas être vide');
    }

    // Vérifier si la catégorie existe déjà
    final existingCategory = await findCategoryByName(categoryName);
    if (existingCategory != null) {
      print('✅ Catégorie "$categoryName" existe déjà (ID: ${existingCategory.id})');
      return existingCategory;
    }

    try {
      print('🔄 Création de la nouvelle catégorie: "$categoryName"');
      
      final newCategory = Category(
        id: 0, // L'ID sera assigné par le backend
        nom: categoryName.trim(),
        description: description?.trim(),
        dateCreation: DateTime.now(),
        dateModification: DateTime.now(),
      );

      final createdCategory = await _categoryService.createCategory(newCategory);
      
      // Mettre à jour le cache
      _cachedCategories.add(createdCategory);
      
      print('✅ Catégorie "$categoryName" créée avec succès (ID: ${createdCategory.id})');
      return createdCategory;
    } catch (e) {
      print('❌ Erreur lors de la création de la catégorie "$categoryName": $e');
      rethrow;
    }
  }

  /// Valide et crée automatiquement les catégories manquantes pour une liste de produits
  Future<Map<String, Category>> validateAndCreateCategories(List<String> categoryNames) async {
    final Map<String, Category> categoryMap = {};
    final List<String> uniqueNames = categoryNames.where((name) => name.trim().isNotEmpty).toSet().toList();

    if (uniqueNames.isEmpty) {
      return categoryMap;
    }

    print('🔍 Validation de ${uniqueNames.length} catégories uniques');

    for (final categoryName in uniqueNames) {
      try {
        final category = await createCategoryIfNotExists(categoryName);
        categoryMap[categoryName] = category;
      } catch (e) {
        print('❌ Impossible de créer la catégorie "$categoryName": $e');
        // Continuer avec les autres catégories
      }
    }

    print('✅ ${categoryMap.length}/${uniqueNames.length} catégories validées/créées');
    return categoryMap;
  }

  /// Invalide le cache pour forcer un rechargement
  void invalidateCache() {
    _cachedCategories.clear();
    _lastCacheUpdate = null;
    print('🗑️ Cache des catégories invalidé');
  }

  /// Ajoute une catégorie au cache (utile après création)
  void addToCache(Category category) {
    // Vérifier si la catégorie existe déjà dans le cache
    final existingIndex = _cachedCategories.indexWhere((cat) => cat.id == category.id);
    if (existingIndex != -1) {
      _cachedCategories[existingIndex] = category;
    } else {
      _cachedCategories.add(category);
    }
    print('📋 Catégorie "${category.nom}" ajoutée au cache');
  }

  /// Supprime une catégorie du cache
  void removeFromCache(int categoryId) {
    _cachedCategories.removeWhere((cat) => cat.id == categoryId);
    print('🗑️ Catégorie ID $categoryId supprimée du cache');
  }

  /// Récupère les noms de catégories pour l'autocomplétion
  Future<List<String>> getCategoryNames() async {
    final categories = await getCategories();
    return categories.map((cat) => cat.nom).toList();
  }

  /// Recherche des catégories par nom (pour l'autocomplétion)
  Future<List<Category>> searchCategories(String query) async {
    if (query.trim().isEmpty) return [];
    
    final categories = await getCategories();
    final lowerQuery = query.toLowerCase().trim();
    
    return categories.where((cat) => 
      cat.nom.toLowerCase().contains(lowerQuery) ||
      (cat.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}