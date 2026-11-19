import 'package:get/get.dart';
import '../models/expense_category.dart';
import '../services/expense_category_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class ExpenseCategoryController extends GetxController {
  final ExpenseCategoryService _service = Get.find<ExpenseCategoryService>();

  // Observables
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxList<ExpenseCategory> filteredCategories = <ExpenseCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString searchQuery = ''.obs;

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
        _applyFilter();
      } else {
        _showError('roles_loading_error'.tr, response.message);
      }
    } catch (e) {
      _showError('roles_loading_error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Filtre les catégories selon la recherche
  void searchCategories(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  /// Applique le filtre de recherche
  void _applyFilter() {
    if (searchQuery.value.isEmpty) {
      filteredCategories.assignAll(categories);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredCategories.assignAll(
        categories.where((category) => category.displayName.toLowerCase().contains(query) || category.nom.toLowerCase().contains(query)).toList(),
      );
    }
  }

  /// Efface la recherche
  void clearSearch() {
    searchQuery.value = '';
    _applyFilter();
  }

  /// Crée une nouvelle catégorie
  Future<bool> createCategory(CreateExpenseCategoryRequest request) async {
    try {
      isCreating.value = true;
      final response = await _service.createExpenseCategory(request);

      if (response.success && response.data != null) {
        categories.add(response.data!);
        _applyFilter();
        _showSuccess('categories_created_success'.tr);
        return true;
      } else {
        _showError('expenses_erreur_creation'.tr, response.message);
        return false;
      }
    } catch (e) {
      _showError('expenses_erreur_creation'.tr, e.toString());
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
          _applyFilter();
        }
        _showSuccess('expenses_categorie_mise_jour_avec_succes'.tr);
        return true;
      } else {
        _showError('expenses_erreur_mise_jour'.tr, response.message);
        return false;
      }
    } catch (e) {
      _showError('expenses_erreur_mise_jour'.tr, e.toString());
      return false;
    }
  }

  /// Supprime une catégorie
  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _service.deleteExpenseCategory(id);

      if (response.success) {
        categories.removeWhere((cat) => cat.id == id);
        _applyFilter();
        _showSuccess('categories_delete_success'.tr);
        return true;
      } else {
        _showError('expenses_erreur_suppression'.tr, response.message);
        return false;
      }
    } catch (e) {
      _showError('expenses_erreur_suppression'.tr, e.toString());
      return false;
    }
  }

  /// Affiche un message d'erreur
  void _showError(String title, String? message) {
    SnackbarHelper.error(
      message ?? 'roles_error_occurred'.tr,
      title: title,
    );
  }

  /// Affiche un message de succès
  void _showSuccess(String message) {
    SnackbarHelper.success(message);
  }
}
