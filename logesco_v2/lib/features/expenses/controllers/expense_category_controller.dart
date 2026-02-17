import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/expense_category.dart';
import '../services/expense_category_service.dart';

class ExpenseCategoryController extends GetxController {
  final ExpenseCategoryService _service = Get.find<ExpenseCategoryService>();

  // Observables
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// Charge toutes les catégories
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final response = await _service.getExpenseCategories();

      if (response.success && response.data != null) {
        categories.assignAll(response.data!);
      } else {
        _showError('Erreur de chargement', response.message);
      }
    } catch (e) {
      _showError('Erreur de chargement', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une nouvelle catégorie
  Future<bool> createCategory(CreateExpenseCategoryRequest request) async {
    try {
      isCreating.value = true;
      final response = await _service.createExpenseCategory(request);

      if (response.success && response.data != null) {
        categories.add(response.data!);
        _showSuccess('Catégorie créée avec succès');
        return true;
      } else {
        _showError('Erreur de création', response.message);
        return false;
      }
    } catch (e) {
      _showError('Erreur de création', e.toString());
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  /// Met à jour une catégorie
  Future<bool> updateCategory(int id, UpdateExpenseCategoryRequest request) async {
    try {
      final response = await _service.updateExpenseCategory(id, request);

      if (response.success && response.data != null) {
        final index = categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          categories[index] = response.data!;
        }
        _showSuccess('Catégorie mise à jour avec succès');
        return true;
      } else {
        _showError('Erreur de mise à jour', response.message);
        return false;
      }
    } catch (e) {
      _showError('Erreur de mise à jour', e.toString());
      return false;
    }
  }

  /// Supprime une catégorie
  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _service.deleteExpenseCategory(id);

      if (response.success) {
        categories.removeWhere((cat) => cat.id == id);
        _showSuccess('Catégorie supprimée avec succès');
        return true;
      } else {
        _showError('Erreur de suppression', response.message);
        return false;
      }
    } catch (e) {
      _showError('Erreur de suppression', e.toString());
      return false;
    }
  }

  /// Affiche un message d'erreur
  void _showError(String title, String? message) {
    Get.snackbar(
      title,
      message ?? 'Une erreur est survenue',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: const Duration(seconds: 4),
    );
  }

  /// Affiche un message de succès
  void _showSuccess(String message) async {
    Get.back();
    Get.snackbar(
      'Succès',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 3),
    );
  }
}
