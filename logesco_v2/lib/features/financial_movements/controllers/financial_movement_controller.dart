import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/financial_movement.dart';
import '../models/movement_category.dart';
import '../models/loading_state.dart';
import '../models/filter_preset.dart';
import '../services/financial_movement_service.dart';
import '../utils/financial_error_handler.dart';
import '../widgets/pagination_widget.dart';
import '../services/pagination_preferences_service.dart';

/// Contrôleur pour la gestion des mouvements financiers avec cache
class FinancialMovementController extends GetxController with LoadingStateMixin {
  final FinancialMovementService _service = Get.find<FinancialMovementService>();

  // État observable
  final RxList<FinancialMovement> movements = <FinancialMovement>[].obs;
  final RxList<MovementCategory> categories = <MovementCategory>[].obs;
  final RxString error = ''.obs;

  // États de chargement spécifiques (conservés pour compatibilité)
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Filtres et pagination
  final RxInt currentPage = 1.obs;
  final RxInt limit = 20.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final Rx<int?> selectedCategoryId = Rx<int?>(null);
  final RxString searchQuery = ''.obs;
  final Rx<double?> minAmount = Rx<double?>(null);
  final Rx<double?> maxAmount = Rx<double?>(null);

  // État de pagination
  final RxBool isLoadingMore = false.obs;
  final RxBool canLoadMore = true.obs;
  final RxList<FinancialMovement> allMovements = <FinancialMovement>[].obs;

  // États de chargement pour opérations spécifiques
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  // Presets de filtres sauvegardés
  final RxList<FilterPreset> savedFilterPresets = <FilterPreset>[].obs;

  // Mode de pagination
  final Rx<PaginationType> paginationType = PaginationType.infinite.obs;

  // Debouncing pour la recherche
  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    // Initialise le cache et charge les données
    _initializeData();
    // Charge les presets par défaut
    _loadDefaultPresets();
  }

  @override
  void onClose() {
    // Nettoie le timer de debouncing
    _searchDebounceTimer?.cancel();
    super.onClose();
  }

  /// Initialise les données au démarrage
  Future<void> _initializeData() async {
    // Le cache est déjà initialisé via les bindings initiaux

    // Charge les préférences de pagination
    await _loadPaginationPreferences();

    await loadCategories();
    await loadMovements();
  }

  /// Charge les préférences de pagination
  Future<void> _loadPaginationPreferences() async {
    try {
      final savedType = await PaginationPreferencesService.getPaginationType();
      final savedPageSize = await PaginationPreferencesService.getPageSize();

      paginationType.value = savedType;
      limit.value = savedPageSize;

      print('📄 Préférences de pagination chargées: ${savedType.name}, taille: $savedPageSize');
    } catch (e) {
      print('⚠️ Erreur lors du chargement des préférences de pagination: $e');
      // Utilise les valeurs par défaut
      paginationType.value = PaginationType.infinite;
      limit.value = 20;
    }
  }

  /// Charge les mouvements financiers (avec cache)
  Future<void> loadMovements({bool forceRefresh = false, bool append = false}) async {
    try {
      // Gestion des états de chargement
      if (append) {
        isLoadingMore.value = true;
        setLoadingMore(
          message: 'Chargement de plus de mouvements...',
          operation: 'loadMoreMovements',
        );
      } else if (forceRefresh) {
        isRefreshing.value = true;
        setRefreshing(
          message: 'Actualisation des mouvements...',
          operation: 'refreshMovements',
        );
      } else {
        isLoading.value = true;
        setLoading(
          message: 'Chargement des mouvements...',
          operation: 'loadMovements',
        );
      }
      error.value = '';

      final response = await _service.getMovements(
        page: currentPage.value,
        limit: limit.value,
        startDate: startDate.value,
        endDate: endDate.value,
        categoryId: selectedCategoryId.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        minAmount: minAmount.value,
        maxAmount: maxAmount.value,
        forceRefresh: forceRefresh,
      );

      final newMovements = response.data ?? [];

      if (append && paginationType.value == PaginationType.infinite) {
        // Mode infini: ajoute les nouveaux mouvements à la liste existante
        allMovements.addAll(newMovements);
        movements.value = List.from(allMovements);
      } else {
        // Mode pages ou chargement initial: remplace la liste complète
        allMovements.value = newMovements;
        movements.value = newMovements;
      }

      // Met à jour les informations de pagination
      if (response.pagination != null) {
        totalItems.value = response.pagination!.total;
        totalPages.value = response.pagination!.totalPages;
        hasNextPage.value = response.pagination!.hasNext;
        hasPreviousPage.value = response.pagination!.hasPrev;
        canLoadMore.value = response.pagination!.hasNext;
      }
    } on FinancialMovementException catch (e) {
      error.value = e.userFriendlyMessage;
      setError(
        message: e.userFriendlyMessage,
        operation: append ? 'loadMoreMovements' : (forceRefresh ? 'refreshMovements' : 'loadMovements'),
        metadata: {'errorType': e.errorType.toString(), 'statusCode': e.statusCode},
      );

      FinancialErrorHandler.logError(e, operation: 'loadMovements');
      FinancialErrorHandler.showErrorToUser(e, context: 'Chargement des mouvements');

      // Exécute une action spéciale si nécessaire
      if (FinancialErrorHandler.requiresSpecialAction(e)) {
        await FinancialErrorHandler.executeSpecialAction(e);
      }
    } on TypeError catch (e) {
      // Gestion spécifique des erreurs de cast de type
      final errorMessage = 'Erreur de format des données reçues du serveur';
      print('❌ [loadMovements] Erreur de cast de type: $e');

      error.value = errorMessage;
      setError(
        message: errorMessage,
        operation: append ? 'loadMoreMovements' : (forceRefresh ? 'refreshMovements' : 'loadMovements'),
        metadata: {'error': e.toString(), 'type': 'TypeError'},
      );

      // Crée une exception financière pour la gestion uniforme
      final financialError = FinancialMovementException(
        message: errorMessage,
        code: 'DATA_FORMAT_ERROR',
        statusCode: 500,
        errorType: FinancialErrorType.unknownError,
        details: {'originalError': e.toString()},
      );

      FinancialErrorHandler.logError(financialError, operation: 'loadMovements');
      FinancialErrorHandler.showErrorToUser(financialError, context: 'Chargement des mouvements');
    } catch (e) {
      // Vérification spéciale pour les erreurs de cast
      if (e.toString().contains('type \'Null\' is not a subtype of type \'num\'') || e.toString().contains('is not a subtype of type')) {
        final errorMessage = 'Erreur de format des données reçues du serveur';
        print('❌ [loadMovements] Erreur de cast détectée: $e');

        error.value = errorMessage;
        setError(
          message: errorMessage,
          operation: append ? 'loadMoreMovements' : (forceRefresh ? 'refreshMovements' : 'loadMovements'),
          metadata: {'error': e.toString(), 'type': 'CastError'},
        );

        // Crée une exception financière pour la gestion uniforme
        final financialError = FinancialMovementException(
          message: errorMessage,
          code: 'DATA_CAST_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
          details: {'originalError': e.toString()},
        );

        FinancialErrorHandler.logError(financialError, operation: 'loadMovements');
        FinancialErrorHandler.showErrorToUser(financialError, context: 'Chargement des mouvements');
      } else {
        final financialError = FinancialErrorHandler.handleError(e, operation: 'loadMovements');
        error.value = financialError.userFriendlyMessage;
        setError(
          message: financialError.userFriendlyMessage,
          operation: append ? 'loadMoreMovements' : (forceRefresh ? 'refreshMovements' : 'loadMovements'),
          metadata: {'error': e.toString()},
        );

        FinancialErrorHandler.logError(financialError, operation: 'loadMovements');
        FinancialErrorHandler.showErrorToUser(financialError, context: 'Chargement des mouvements');
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      isRefreshing.value = false;

      // Réinitialise l'état de chargement si pas d'erreur
      if (error.value.isEmpty) {
        setIdle();
      }
    }
  }

  /// Charge les catégories (avec cache)
  Future<void> loadCategories({bool forceRefresh = false}) async {
    try {
      final loadedCategories = await _service.getCategories(forceRefresh: forceRefresh);
      categories.value = loadedCategories;
      update(); // Notify GetBuilder widgets
    } on FinancialMovementException catch (e) {
      FinancialErrorHandler.logError(e, operation: 'loadCategories');

      // Pour les catégories, on ne montre pas d'erreur à l'utilisateur car on a un fallback
      // En cas d'erreur, utilise les catégories par défaut
      categories.value = MovementCategory.defaultCategories;
      update(); // Notify GetBuilder widgets
      print('📦 Utilisation des catégories par défaut suite à une erreur');
    } catch (e) {
      final financialError = FinancialErrorHandler.handleError(e, operation: 'loadCategories');
      FinancialErrorHandler.logError(financialError, operation: 'loadCategories');

      // En cas d'erreur, utilise les catégories par défaut
      categories.value = MovementCategory.defaultCategories;
      update(); // Notify GetBuilder widgets
      print('📦 Utilisation des catégories par défaut suite à une erreur');
    }
  }

  /// Rafraîchit les données (force le rechargement depuis l'API)
  Future<void> refreshData() async {
    try {
      isRefreshing.value = true;
      await Future.wait([
        loadMovements(forceRefresh: true),
        loadCategories(forceRefresh: true),
      ]);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Rafraîchit uniquement les mouvements (utilisé après création externe)
  Future<void> refreshMovements() async {
    print('🔄 [refreshMovements] Rafraîchissement des mouvements financiers');
    await loadMovements(forceRefresh: true);
  }

  /// Recherche des mouvements avec debouncing
  Future<void> searchMovements(String query) async {
    searchQuery.value = query;

    // Annule le timer précédent s'il existe
    _searchDebounceTimer?.cancel();

    // Démarre un nouveau timer pour le debouncing (500ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      currentPage.value = 1; // Reset à la première page
      await loadMovements();
    });
  }

  /// Recherche immédiate sans debouncing
  Future<void> searchMovementsImmediate(String query) async {
    _searchDebounceTimer?.cancel();
    searchQuery.value = query;
    currentPage.value = 1;
    await loadMovements();
  }

  /// Recherche avancée dans plusieurs champs
  Future<void> advancedSearch({
    String? description,
    String? reference,
    String? notes,
    String? userName,
  }) async {
    _searchDebounceTimer?.cancel();

    // Combine tous les critères de recherche en une seule requête
    final searchTerms = <String>[];

    if (description != null && description.isNotEmpty) {
      searchTerms.add('desc:$description');
    }
    if (reference != null && reference.isNotEmpty) {
      searchTerms.add('ref:$reference');
    }
    if (notes != null && notes.isNotEmpty) {
      searchTerms.add('notes:$notes');
    }
    if (userName != null && userName.isNotEmpty) {
      searchTerms.add('user:$userName');
    }

    searchQuery.value = searchTerms.join(' ');
    currentPage.value = 1;
    await loadMovements();
  }

  /// Recherche intelligente avec suggestions automatiques
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];

    final suggestions = <String>[];
    final queryLower = query.toLowerCase();

    // Suggestions basées sur les descriptions existantes
    for (final movement in movements) {
      if (movement.description.toLowerCase().contains(queryLower)) {
        final words = movement.description.split(' ');
        for (final word in words) {
          if (word.toLowerCase().startsWith(queryLower) && word.length > 2 && !suggestions.contains(word)) {
            suggestions.add(word);
          }
        }
      }
    }

    // Suggestions basées sur les catégories
    for (final category in categories) {
      if (category.displayName.toLowerCase().contains(queryLower) && !suggestions.contains(category.displayName)) {
        suggestions.add(category.displayName);
      }
    }

    // Limite à 10 suggestions
    return suggestions.take(10).toList();
  }

  /// Recherche avec mise en évidence des termes
  List<FinancialMovement> getHighlightedSearchResults() {
    if (searchQuery.value.isEmpty) return movements;

    final query = searchQuery.value.toLowerCase();
    final results = <FinancialMovement>[];

    for (final movement in movements) {
      // Vérifie si le mouvement correspond à la recherche
      if (_matchesSearchQuery(movement, query)) {
        results.add(movement);
      }
    }

    return results;
  }

  /// Vérifie si un mouvement correspond à la requête de recherche
  bool _matchesSearchQuery(FinancialMovement movement, String query) {
    // Recherche simple dans tous les champs
    if (!query.contains(':')) {
      return movement.description.toLowerCase().contains(query) ||
          movement.reference.toLowerCase().contains(query) ||
          (movement.notes?.toLowerCase().contains(query) ?? false) ||
          (movement.utilisateurNom?.toLowerCase().contains(query) ?? false);
    }

    // Recherche avancée avec préfixes
    final terms = query.split(' ');
    for (final term in terms) {
      if (term.contains(':')) {
        final parts = term.split(':');
        if (parts.length == 2) {
          final field = parts[0];
          final value = parts[1].toLowerCase();

          switch (field) {
            case 'desc':
              if (!movement.description.toLowerCase().contains(value)) return false;
              break;
            case 'ref':
              if (!movement.reference.toLowerCase().contains(value)) return false;
              break;
            case 'notes':
              if (!(movement.notes?.toLowerCase().contains(value) ?? false)) return false;
              break;
            case 'user':
              if (!(movement.utilisateurNom?.toLowerCase().contains(value) ?? false)) return false;
              break;
          }
        }
      } else {
        // Terme sans préfixe, recherche dans tous les champs
        if (!movement.description.toLowerCase().contains(term) &&
            !movement.reference.toLowerCase().contains(term) &&
            !(movement.notes?.toLowerCase().contains(term) ?? false) &&
            !(movement.utilisateurNom?.toLowerCase().contains(term) ?? false)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Filtre par catégorie
  Future<void> filterByCategory(int? categoryId) async {
    selectedCategoryId.value = categoryId;
    currentPage.value = 1; // Reset à la première page
    await loadMovements();
  }

  /// Filtre par période avec validation
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    // Validation des dates
    if (start != null && end != null && start.isAfter(end)) {
      error.value = 'La date de début ne peut pas être postérieure à la date de fin';
      return;
    }

    if (start != null && start.isAfter(DateTime.now())) {
      error.value = 'La date de début ne peut pas être dans le futur';
      return;
    }

    if (end != null && end.isAfter(DateTime.now())) {
      error.value = 'La date de fin ne peut pas être dans le futur';
      return;
    }

    startDate.value = start;
    endDate.value = end;
    _resetPagination();
    await loadMovements();
  }

  /// Filtre par montant avec validation
  Future<void> filterByAmountRange(double? min, double? max) async {
    // Validation des montants
    if (min != null && min < 0) {
      error.value = 'Le montant minimum ne peut pas être négatif';
      return;
    }

    if (max != null && max < 0) {
      error.value = 'Le montant maximum ne peut pas être négatif';
      return;
    }

    if (min != null && max != null && min > max) {
      error.value = 'Le montant minimum ne peut pas être supérieur au montant maximum';
      return;
    }

    minAmount.value = min;
    maxAmount.value = max;
    _resetPagination();
    await loadMovements();
  }

  /// Filtre combiné avancé
  Future<void> applyAdvancedFilters({
    String? search,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    if (search != null) searchQuery.value = search;
    if (categoryId != null) selectedCategoryId.value = categoryId;
    if (startDate != null) this.startDate.value = startDate;
    if (endDate != null) this.endDate.value = endDate;
    if (minAmount != null) this.minAmount.value = minAmount;
    if (maxAmount != null) this.maxAmount.value = maxAmount;

    _resetPagination();
    await loadMovements();
  }

  /// Charge la page suivante
  Future<void> loadNextPage() async {
    if (!isLoading.value && !isLoadingMore.value && hasNextPage.value) {
      currentPage.value++;
      await loadMovements(append: true);
    }
  }

  /// Charge la page précédente
  Future<void> loadPreviousPage() async {
    if (!isLoading.value && hasPreviousPage.value && currentPage.value > 1) {
      currentPage.value--;
      await loadMovements();
    }
  }

  /// Va à une page spécifique
  Future<void> goToPage(int page) async {
    if (!isLoading.value && page > 0 && page <= totalPages.value) {
      currentPage.value = page;
      await loadMovements();
    }
  }

  /// Charge plus de mouvements (pagination infinie)
  Future<void> loadMore() async {
    if (canLoadMore.value && !isLoadingMore.value && !isLoading.value) {
      await loadNextPage();
    }
  }

  /// Change le mode de pagination
  Future<void> changePaginationType(PaginationType newType) async {
    if (paginationType.value != newType) {
      paginationType.value = newType;

      // Sauvegarde la préférence utilisateur
      try {
        await PaginationPreferencesService.savePaginationType(newType);
        print('📄 Mode de pagination changé et sauvegardé: ${newType.name}');
      } catch (e) {
        print('⚠️ Erreur lors de la sauvegarde du mode de pagination: $e');
      }

      // Réinitialise la pagination et recharge
      _resetPagination();
      await loadMovements();
    }
  }

  /// Crée un nouveau mouvement
  Future<bool> createMovement(FinancialMovementForm form) async {
    return await executeWithLoadingState<bool>(
      () async {
        isCreating.value = true;

        await _service.createMovement(form);

        // Recharge les données pour refléter le nouveau mouvement
        await loadMovements(forceRefresh: true);

        isCreating.value = false;
        return true;
      },
      loadingState: LoadingState.creating(
        message: 'Création du mouvement en cours...',
        operation: 'createMovement',
      ),
      successMessage: 'Mouvement créé avec succès',
      errorMessage: 'Erreur lors de la création du mouvement',
    ).catchError((e) {
      isCreating.value = false;

      if (e is FinancialMovementException) {
        error.value = e.userFriendlyMessage;
        FinancialErrorHandler.logError(e, operation: 'createMovement');
        FinancialErrorHandler.showErrorToUser(e, context: 'Création du mouvement');

        // Exécute une action spéciale si nécessaire
        if (FinancialErrorHandler.requiresSpecialAction(e)) {
          FinancialErrorHandler.executeSpecialAction(e);
        }
      } else {
        final financialError = FinancialErrorHandler.handleError(e, operation: 'createMovement');
        error.value = financialError.userFriendlyMessage;
        FinancialErrorHandler.logError(financialError, operation: 'createMovement');
        FinancialErrorHandler.showErrorToUser(financialError, context: 'Création du mouvement');
      }

      return false;
    });
  }

  /// Met à jour un mouvement existant
  Future<bool> updateMovement(int id, FinancialMovementForm form) async {
    return await executeWithLoadingState<bool>(
      () async {
        isUpdating.value = true;

        await _service.updateMovement(id, form);

        // Recharge les données pour refléter les modifications
        await loadMovements(forceRefresh: true);

        isUpdating.value = false;
        return true;
      },
      loadingState: LoadingState.updating(
        message: 'Mise à jour du mouvement en cours...',
        operation: 'updateMovement',
      ),
      successMessage: 'Mouvement mis à jour avec succès',
      errorMessage: 'Erreur lors de la mise à jour du mouvement',
    ).catchError((e) {
      isUpdating.value = false;

      if (e is FinancialMovementException) {
        error.value = e.userFriendlyMessage;
        FinancialErrorHandler.logError(e, operation: 'updateMovement', context: {'movementId': id});
        FinancialErrorHandler.showErrorToUser(e, context: 'Mise à jour du mouvement');

        // Exécute une action spéciale si nécessaire
        if (FinancialErrorHandler.requiresSpecialAction(e)) {
          FinancialErrorHandler.executeSpecialAction(e);
        }
      } else {
        final financialError = FinancialErrorHandler.handleError(e, operation: 'updateMovement');
        error.value = financialError.userFriendlyMessage;
        FinancialErrorHandler.logError(financialError, operation: 'updateMovement', context: {'movementId': id});
        FinancialErrorHandler.showErrorToUser(financialError, context: 'Mise à jour du mouvement');
      }

      return false;
    });
  }

  /// Supprime un mouvement
  Future<bool> deleteMovement(int id) async {
    return await executeWithLoadingState<bool>(
      () async {
        isDeleting.value = true;

        await _service.deleteMovement(id);

        // Recharge les données pour refléter la suppression
        await loadMovements(forceRefresh: true);

        isDeleting.value = false;
        return true;
      },
      loadingState: LoadingState.deleting(
        message: 'Suppression du mouvement en cours...',
        operation: 'deleteMovement',
      ),
      successMessage: 'Mouvement supprimé avec succès',
      errorMessage: 'Erreur lors de la suppression du mouvement',
    ).catchError((e) {
      isDeleting.value = false;

      if (e is FinancialMovementException) {
        error.value = e.userFriendlyMessage;
        FinancialErrorHandler.logError(e, operation: 'deleteMovement', context: {'movementId': id});
        FinancialErrorHandler.showErrorToUser(e, context: 'Suppression du mouvement');

        // Exécute une action spéciale si nécessaire
        if (FinancialErrorHandler.requiresSpecialAction(e)) {
          FinancialErrorHandler.executeSpecialAction(e);
        }
      } else {
        final financialError = FinancialErrorHandler.handleError(e, operation: 'deleteMovement');
        error.value = financialError.userFriendlyMessage;
        FinancialErrorHandler.logError(financialError, operation: 'deleteMovement', context: {'movementId': id});
        FinancialErrorHandler.showErrorToUser(financialError, context: 'Suppression du mouvement');
      }

      return false;
    });
  }

  /// Obtient un mouvement par son ID (avec cache)
  Future<FinancialMovement?> getMovementById(int id, {bool forceRefresh = false}) async {
    try {
      return await _service.getMovementById(id, forceRefresh: forceRefresh);
    } on FinancialMovementException catch (e) {
      FinancialErrorHandler.logError(e, operation: 'getMovementById', context: {'movementId': id});

      // Pour la récupération d'un mouvement spécifique, on peut montrer l'erreur si c'est critique
      if (e.errorType == FinancialErrorType.authenticationError || e.errorType == FinancialErrorType.permissionError) {
        FinancialErrorHandler.showErrorToUser(e, context: 'Récupération du mouvement');

        if (FinancialErrorHandler.requiresSpecialAction(e)) {
          await FinancialErrorHandler.executeSpecialAction(e);
        }
      }

      return null;
    } catch (e) {
      final financialError = FinancialErrorHandler.handleError(e, operation: 'getMovementById');
      FinancialErrorHandler.logError(financialError, operation: 'getMovementById', context: {'movementId': id});
      return null;
    }
  }

  /// Nettoie le cache
  Future<void> clearCache() async {
    await _service.clearCache();
    // Recharge les données depuis l'API
    await refreshData();
  }

  /// Obtient des informations sur le cache
  Map<String, dynamic> getCacheInfo() {
    return _service.getCacheInfo();
  }

  /// Obtient la taille du cache
  int getCacheSize() {
    return _service.getCacheSize();
  }

  /// Réinitialise les filtres
  void resetFilters() {
    searchQuery.value = '';
    selectedCategoryId.value = null;
    startDate.value = null;
    endDate.value = null;
    minAmount.value = null;
    maxAmount.value = null;
    _resetPagination();
  }

  /// Applique tous les filtres et recharge
  Future<void> applyFilters() async {
    _resetPagination();
    await loadMovements();
  }

  /// Réinitialise la pagination
  void _resetPagination() {
    currentPage.value = 1;

    // En mode infini, on garde les mouvements chargés
    // En mode pages, on vide tout
    if (paginationType.value == PaginationType.pages) {
      allMovements.clear();
    }

    totalItems.value = 0;
    totalPages.value = 0;
    hasNextPage.value = false;
    hasPreviousPage.value = false;
    canLoadMore.value = true;
  }

  /// Obtient le nombre total de mouvements filtrés
  int get filteredCount => totalItems.value;

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty || selectedCategoryId.value != null || startDate.value != null || endDate.value != null || minAmount.value != null || maxAmount.value != null;
  }

  /// Obtient un résumé des filtres actifs
  Map<String, dynamic> get activeFiltersInfo {
    final filters = <String, dynamic>{};

    if (searchQuery.value.isNotEmpty) {
      filters['search'] = searchQuery.value;
    }
    if (selectedCategoryId.value != null) {
      MovementCategory? category;
      try {
        category = categories.firstWhere((c) => c.id == selectedCategoryId.value);
      } catch (e) {
        category = null;
      }
      filters['category'] = category?.displayName ?? 'Catégorie ${selectedCategoryId.value}';
    }
    if (startDate.value != null) {
      filters['startDate'] = startDate.value;
    }
    if (endDate.value != null) {
      filters['endDate'] = endDate.value;
    }
    if (minAmount.value != null) {
      filters['minAmount'] = minAmount.value;
    }
    if (maxAmount.value != null) {
      filters['maxAmount'] = maxAmount.value;
    }

    return filters;
  }

  /// Obtient les informations de pagination
  Map<String, dynamic> get paginationInfo {
    return {
      'currentPage': currentPage.value,
      'totalPages': totalPages.value,
      'totalItems': totalItems.value,
      'itemsPerPage': limit.value,
      'hasNext': hasNextPage.value,
      'hasPrev': hasPreviousPage.value,
      'canLoadMore': canLoadMore.value,
    };
  }

  /// Change la taille de page
  Future<void> changePageSize(int newLimit) async {
    if (newLimit > 0 && newLimit != limit.value) {
      limit.value = newLimit;

      // Sauvegarde la préférence utilisateur
      try {
        await PaginationPreferencesService.savePageSize(newLimit);
        print('📄 Taille de page changée et sauvegardée: $newLimit');
      } catch (e) {
        print('⚠️ Erreur lors de la sauvegarde de la taille de page: $e');
      }

      _resetPagination();
      await loadMovements();
    }
  }

  /// Méthodes de convenance pour vérifier les états de chargement

  /// Vérifie si une opération de chargement est en cours
  bool get isAnyLoading => isLoading.value || isRefreshing.value || isLoadingMore.value || isCreating.value || isUpdating.value || isDeleting.value || currentLoadingState.isLoading;

  /// Vérifie si le chargement initial est en cours
  bool get isInitialLoading => isLoading.value && !isRefreshing.value && !isLoadingMore.value;

  /// Vérifie si une opération CRUD est en cours
  bool get isCrudOperationInProgress => isCreating.value || isUpdating.value || isDeleting.value;

  /// Obtient le message de chargement actuel
  String get currentLoadingMessage => currentLoadingState.message ?? 'Chargement...';

  /// Obtient le type d'opération en cours
  String? get currentOperation => currentLoadingState.operation;

  /// Vérifie si l'état actuel a un progrès
  bool get hasProgress => currentLoadingState.hasProgress;

  /// Obtient le pourcentage de progrès
  int get progressPercentage => currentLoadingState.progressPercentage;

  /// Filtre rapide par période prédéfinie
  Future<void> filterByPredefinedPeriod(String period) async {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = now;

    switch (period.toLowerCase()) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'this_week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'last_week':
        final lastWeekEnd = now.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        start = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
        end = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59);
        break;
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = lastMonth;
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'last_year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      default:
        return; // Période non reconnue
    }

    await filterByDateRange(start, end);
  }

  /// Obtient le total des montants pour les mouvements actuellement affichés
  double get currentTotal {
    return movements.fold(0.0, (sum, movement) => sum + movement.montant);
  }

  /// Obtient les statistiques rapides des mouvements affichés
  Map<String, dynamic> get quickStats {
    if (movements.isEmpty) {
      return {
        'count': 0,
        'total': 0.0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
      };
    }

    final amounts = movements.map((m) => m.montant).toList();
    amounts.sort();

    return {
      'count': movements.length,
      'total': currentTotal,
      'average': currentTotal / movements.length,
      'min': amounts.first,
      'max': amounts.last,
    };
  }

  // ========== GESTION DES PRESETS DE FILTRES ==========

  /// Charge les presets par défaut
  void _loadDefaultPresets() {
    savedFilterPresets.value = FilterPreset.defaultPresets;
  }

  /// Sauvegarde les filtres actuels comme preset
  Future<void> saveCurrentFiltersAsPreset(String name, {String? description}) async {
    if (name.trim().isEmpty) {
      error.value = 'Le nom du preset ne peut pas être vide';
      return;
    }

    // Vérifie si un preset avec ce nom existe déjà
    if (savedFilterPresets.any((preset) => preset.name.toLowerCase() == name.toLowerCase())) {
      error.value = 'Un preset avec ce nom existe déjà';
      return;
    }

    final preset = FilterPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description?.trim(),
      startDate: startDate.value,
      endDate: endDate.value,
      categoryId: selectedCategoryId.value,
      searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      minAmount: minAmount.value,
      maxAmount: maxAmount.value,
      createdAt: DateTime.now(),
    );

    savedFilterPresets.add(preset);

    // Ici, on pourrait sauvegarder dans le stockage local
    // await _savePresetsToStorage();

    Get.snackbar(
      'Succès',
      'Preset "$name" sauvegardé avec succès',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  /// Applique un preset de filtres
  Future<void> applyFilterPreset(FilterPreset preset) async {
    searchQuery.value = preset.searchQuery ?? '';
    selectedCategoryId.value = preset.categoryId;
    startDate.value = preset.startDate;
    endDate.value = preset.endDate;
    minAmount.value = preset.minAmount;
    maxAmount.value = preset.maxAmount;

    _resetPagination();
    await loadMovements();

    Get.snackbar(
      'Preset appliqué',
      'Filtres "${preset.name}" appliqués',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  /// Supprime un preset sauvegardé
  Future<void> deleteFilterPreset(String presetId) async {
    final preset = savedFilterPresets.firstWhereOrNull((p) => p.id == presetId);
    if (preset == null) return;

    if (preset.isDefault) {
      error.value = 'Impossible de supprimer un preset par défaut';
      return;
    }

    savedFilterPresets.removeWhere((p) => p.id == presetId);

    // Ici, on pourrait sauvegarder dans le stockage local
    // await _savePresetsToStorage();

    Get.snackbar(
      'Preset supprimé',
      'Preset "${preset.name}" supprimé',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
    );
  }

  /// Met à jour un preset existant
  Future<void> updateFilterPreset(
    String presetId, {
    String? name,
    String? description,
    bool? updateFilters,
  }) async {
    final index = savedFilterPresets.indexWhere((p) => p.id == presetId);
    if (index == -1) return;

    final currentPreset = savedFilterPresets[index];
    if (currentPreset.isDefault) {
      error.value = 'Impossible de modifier un preset par défaut';
      return;
    }

    final updatedPreset = currentPreset.copyWith(
      name: name,
      description: description,
      startDate: updateFilters == true ? startDate.value : currentPreset.startDate,
      endDate: updateFilters == true ? endDate.value : currentPreset.endDate,
      categoryId: updateFilters == true ? selectedCategoryId.value : currentPreset.categoryId,
      searchQuery: updateFilters == true ? (searchQuery.value.isNotEmpty ? searchQuery.value : null) : currentPreset.searchQuery,
      minAmount: updateFilters == true ? minAmount.value : currentPreset.minAmount,
      maxAmount: updateFilters == true ? maxAmount.value : currentPreset.maxAmount,
    );

    savedFilterPresets[index] = updatedPreset;

    // Ici, on pourrait sauvegarder dans le stockage local
    // await _savePresetsToStorage();

    Get.snackbar(
      'Preset mis à jour',
      'Preset "${updatedPreset.name}" mis à jour',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  /// Obtient les presets personnalisés (non par défaut)
  List<FilterPreset> get customPresets {
    return savedFilterPresets.where((preset) => !preset.isDefault).toList();
  }

  /// Obtient les presets par défaut
  List<FilterPreset> get defaultPresets {
    return savedFilterPresets.where((preset) => preset.isDefault).toList();
  }

  /// Vérifie si les filtres actuels correspondent à un preset
  FilterPreset? get currentMatchingPreset {
    return savedFilterPresets.firstWhereOrNull((preset) {
      return preset.startDate == startDate.value &&
          preset.endDate == endDate.value &&
          preset.categoryId == selectedCategoryId.value &&
          preset.searchQuery == (searchQuery.value.isNotEmpty ? searchQuery.value : null) &&
          preset.minAmount == minAmount.value &&
          preset.maxAmount == maxAmount.value;
    });
  }

  // ========== FILTRES INTELLIGENTS ==========

  /// Filtre intelligent basé sur l'historique
  Future<void> applySmartFilter(String type) async {
    final now = DateTime.now();

    switch (type) {
      case 'frequent_categories':
        // Trouve les catégories les plus utilisées
        if (movements.isNotEmpty) {
          final categoryFrequency = <int, int>{};
          for (final movement in movements) {
            categoryFrequency[movement.categorieId] = (categoryFrequency[movement.categorieId] ?? 0) + 1;
          }

          final mostFrequentCategory = categoryFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

          await filterByCategory(mostFrequentCategory);
        }
        break;

      case 'recent_large_amounts':
        // Mouvements récents avec montants élevés
        final lastWeek = now.subtract(const Duration(days: 7));
        final averageAmount = movements.isNotEmpty ? movements.map((m) => m.montant).reduce((a, b) => a + b) / movements.length : 0.0;

        await applyAdvancedFilters(
          startDate: lastWeek,
          endDate: now,
          minAmount: averageAmount * 1.5, // 50% au-dessus de la moyenne
        );
        break;

      case 'unusual_patterns':
        // Détecte les patterns inhabituels (montants très élevés ou très faibles)
        if (movements.isNotEmpty) {
          final amounts = movements.map((m) => m.montant).toList();
          amounts.sort();

          final q1 = amounts[(amounts.length * 0.25).floor()];
          final q3 = amounts[(amounts.length * 0.75).floor()];
          final iqr = q3 - q1;

          // Outliers selon la règle IQR
          final upperBound = q3 + (1.5 * iqr);

          // Filtre pour montants en dehors des bornes normales (montants élevés)
          if (upperBound > 0) {
            await filterByAmountRange(upperBound, null);
          }
        }
        break;
    }
  }

  /// Suggestions de filtres basées sur les données
  List<Map<String, dynamic>> get filterSuggestions {
    final suggestions = <Map<String, dynamic>>[];

    if (movements.isNotEmpty) {
      // Suggestion basée sur la catégorie la plus fréquente
      final categoryFrequency = <int, int>{};
      for (final movement in movements) {
        categoryFrequency[movement.categorieId] = (categoryFrequency[movement.categorieId] ?? 0) + 1;
      }

      if (categoryFrequency.isNotEmpty) {
        final mostFrequent = categoryFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);
        final category = categories.firstWhereOrNull((c) => c.id == mostFrequent.key);

        if (category != null) {
          suggestions.add({
            'type': 'category',
            'title': 'Catégorie populaire',
            'description': 'Filtrer par "${category.displayName}" (${mostFrequent.value} mouvements)',
            'action': () => filterByCategory(category.id),
          });
        }
      }

      // Suggestion basée sur les montants élevés récents
      final recentHighAmounts = movements.where((m) => m.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).where((m) => m.montant > 10000).length;

      if (recentHighAmounts > 0) {
        suggestions.add({
          'type': 'amount',
          'title': 'Montants élevés récents',
          'description': '$recentHighAmounts mouvements > 10 000 FCFA cette semaine',
          'action': () => applySmartFilter('recent_large_amounts'),
        });
      }
    }

    return suggestions;
  }
}
