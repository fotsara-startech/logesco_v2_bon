import 'package:get/get.dart';
import '../models/movement_category.dart';
import '../models/loading_state.dart';
import '../services/financial_movement_service.dart';
import '../utils/financial_error_handler.dart';

/// Contrôleur pour la gestion des catégories de mouvements financiers
class MovementCategoryController extends GetxController with LoadingStateMixin {
  final FinancialMovementService _service = Get.find<FinancialMovementService>();

  // État observable
  final RxList<MovementCategory> categories = <MovementCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // Filtres et recherche
  final RxString searchQuery = ''.obs;
  final RxBool showInactiveCategories = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// Charge les catégories (avec fallback automatique)
  Future<void> loadCategories({bool forceRefresh = false}) async {
    await executeWithLoadingState<void>(
      () async {
        isLoading.value = true;

        try {
          // Essayer de charger depuis l'API
          final loadedCategories = await _service.getCategories(forceRefresh: forceRefresh);
          categories.value = loadedCategories;
        } catch (e) {
          print('⚠️ Erreur API catégories, utilisation du fallback: $e');
          // Utiliser les catégories par défaut en cas d'erreur
          categories.value = MovementCategory.defaultCategories;
        }

        isLoading.value = false;
      },
      loadingState: forceRefresh
          ? LoadingState.refreshing(
              message: 'Actualisation des catégories...',
              operation: 'refreshCategories',
            )
          : LoadingState.loading(
              message: 'Chargement des catégories...',
              operation: 'loadCategories',
            ),
      successMessage: null, // Pas de message de succès pour éviter le spam
      errorMessage: 'Erreur lors du chargement des catégories',
      autoResetAfterSuccess: true,
    ).catchError((e) {
      isLoading.value = false;

      if (e is FinancialMovementException) {
        error.value = e.userFriendlyMessage;
        FinancialErrorHandler.logError(e, operation: 'loadCategories');
        FinancialErrorHandler.showErrorToUser(e, context: 'Chargement des catégories');

        // Exécute une action spéciale si nécessaire
        if (FinancialErrorHandler.requiresSpecialAction(e)) {
          FinancialErrorHandler.executeSpecialAction(e);
        }
      } else {
        final financialError = FinancialErrorHandler.handleError(e, operation: 'loadCategories');
        error.value = financialError.userFriendlyMessage;
        FinancialErrorHandler.logError(financialError, operation: 'loadCategories');
      }

      // En cas d'erreur, utilise les catégories par défaut
      categories.value = MovementCategory.defaultCategories;
      print('📦 Utilisation des catégories par défaut suite à une erreur');
    });
  }

  /// Rafraîchit les catégories (force le rechargement depuis l'API)
  Future<void> refreshCategories() async {
    try {
      isRefreshing.value = true;
      await loadCategories(forceRefresh: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Recherche des catégories par nom
  void searchCategories(String query) {
    searchQuery.value = query;
  }

  /// Bascule l'affichage des catégories inactives
  void toggleShowInactiveCategories() {
    showInactiveCategories.value = !showInactiveCategories.value;
  }

  /// Obtient les catégories filtrées selon les critères actuels
  List<MovementCategory> get filteredCategories {
    var filtered = categories.toList();

    // Filtre par statut actif/inactif
    if (!showInactiveCategories.value) {
      filtered = filtered.where((category) => category.isActive).toList();
    }

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((category) => category.name.toLowerCase().contains(query) || category.displayName.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  /// Obtient une catégorie par son ID
  MovementCategory? getCategoryById(int id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient une catégorie par son nom
  MovementCategory? getCategoryByName(String name) {
    try {
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtient les catégories actives uniquement
  List<MovementCategory> get activeCategories {
    return categories.where((category) => category.isActive).toList();
  }

  /// Obtient les catégories par défaut
  List<MovementCategory> get defaultCategories {
    return categories.where((category) => category.isDefault).toList();
  }

  /// Vérifie si une catégorie existe par son nom
  bool categoryExistsByName(String name) {
    return categories.any(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
    );
  }

  /// Réinitialise les filtres
  void resetFilters() {
    searchQuery.value = '';
    showInactiveCategories.value = false;
  }

  /// Obtient le nombre total de catégories
  int get totalCategoriesCount => categories.length;

  /// Obtient le nombre de catégories actives
  int get activeCategoriesCount => activeCategories.length;

  /// Obtient le nombre de catégories inactives
  int get inactiveCategoriesCount => categories.length - activeCategories.length;

  /// Obtient des statistiques sur les catégories
  Map<String, dynamic> getCategoriesStats() {
    return {
      'total': totalCategoriesCount,
      'active': activeCategoriesCount,
      'inactive': inactiveCategoriesCount,
      'default': defaultCategories.length,
      'custom': categories.where((c) => !c.isDefault).length,
    };
  }

  /// Méthodes de convenance pour vérifier les états de chargement

  /// Vérifie si le chargement des catégories est en cours
  bool get isCategoriesLoading => isLoading.value || currentLoadingState.isLoading;

  /// Obtient le message de chargement actuel
  String get currentLoadingMessage => currentLoadingState.message ?? 'Chargement...';

  /// Vérifie si l'état actuel est une erreur
  bool get hasLoadingError => currentLoadingState.isError;

  /// Obtient le message d'erreur de chargement
  String? get loadingErrorMessage => currentLoadingState.isError ? currentLoadingState.message : null;
}
