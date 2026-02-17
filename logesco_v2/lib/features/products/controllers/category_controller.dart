import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

/// Contrôleur pour la gestion des catégories avec base de données
class CategoryController extends GetxController {
  final CategoryService _categoryService = Get.find<CategoryService>();

  // Observables
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<Category?> selectedCategory = Rx<Category?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🏗️ CategoryController initialisé');
    print('🔍 Début du chargement des catégories...');
    loadCategories();
  }

  /// Charge toutes les catégories depuis la base de données
  Future<void> loadCategories({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      error.value = '';

      print('🔄 Chargement des catégories...');
      final result = await _categoryService.getCategories();

      categories.assignAll(result);
      print('✅ ${categories.length} catégories chargées');
    } catch (e) {
      error.value = 'Erreur lors du chargement: ${e.toString()}';
      print('❌ Erreur chargement catégories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Ajoute une nouvelle catégorie
  Future<bool> addCategory(String nom, {String? description}) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (nom.trim().isEmpty) {
        error.value = 'Le nom de la catégorie ne peut pas être vide';
        return false;
      }

      // Vérifier si la catégorie existe déjà
      if (categories.any((cat) => cat.nom.toLowerCase() == nom.trim().toLowerCase())) {
        error.value = 'Une catégorie avec ce nom existe déjà';
        return false;
      }

      final newCategory = Category(
        nom: nom.trim(),
        description: description?.trim(),
      );

      print('➕ Création de la catégorie: ${newCategory.nom}');
      final createdCategory = await _categoryService.createCategory(newCategory);

      categories.add(createdCategory);
      print('✅ Catégorie créée avec succès: ${createdCategory.nom}');
      return true;
    } catch (e) {
      error.value = 'Erreur lors de la création: ${e.toString()}';
      print('❌ Erreur création catégorie: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour une catégorie
  Future<bool> updateCategory(Category category, String newNom, {String? newDescription}) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (newNom.trim().isEmpty) {
        error.value = 'Le nom de la catégorie ne peut pas être vide';
        return false;
      }

      // Vérifier si le nouveau nom existe déjà (sauf pour la catégorie actuelle)
      if (categories.any((cat) => cat.id != category.id && cat.nom.toLowerCase() == newNom.trim().toLowerCase())) {
        error.value = 'Une catégorie avec ce nom existe déjà';
        return false;
      }

      final updatedCategory = category.copyWith(
        nom: newNom.trim(),
        description: newDescription?.trim(),
      );

      print('✏️ Mise à jour de la catégorie: ${category.nom} -> ${updatedCategory.nom}');
      final result = await _categoryService.updateCategory(updatedCategory);

      // Mettre à jour dans la liste
      final index = categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        categories[index] = result;
      }

      print('✅ Catégorie mise à jour avec succès');
      return true;
    } catch (e) {
      error.value = 'Erreur lors de la mise à jour: ${e.toString()}';
      print('❌ Erreur mise à jour catégorie: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprime une catégorie
  Future<bool> deleteCategory(Category category) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (category.id == null) {
        error.value = 'ID de catégorie invalide';
        return false;
      }

      print('🗑️ Suppression de la catégorie: ${category.nom}');
      await _categoryService.deleteCategory(category.id!);

      categories.removeWhere((cat) => cat.id == category.id);

      // Désélectionner si c'était la catégorie sélectionnée
      if (selectedCategory.value?.id == category.id) {
        selectedCategory.value = null;
      }

      print('✅ Catégorie supprimée avec succès');
      return true;
    } catch (e) {
      error.value = 'Erreur lors de la suppression: ${e.toString()}';
      print('❌ Erreur suppression catégorie: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sélectionne une catégorie
  void selectCategory(Category? category) {
    selectedCategory.value = category;
  }

  /// Efface la sélection
  void clearSelection() {
    selectedCategory.value = null;
  }

  /// Vérifie si une catégorie est sélectionnée
  bool get hasSelection => selectedCategory.value != null;

  /// Actualise les données
  Future<void> refresh() async {
    await loadCategories(showLoading: false);
  }
}
