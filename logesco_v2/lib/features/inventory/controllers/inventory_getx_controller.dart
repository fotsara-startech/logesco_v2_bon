import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../services/inventory_service.dart';
import '../services/export_service.dart';
import '../../products/services/category_service.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Contrôleur GetX pour la gestion de l'inventaire
class InventoryGetxController extends GetxController {
  final InventoryService _inventoryService = InventoryService(Get.find<AuthService>());
  final CategoryService _categoryService = Get.find<CategoryService>();
  final AuthService _authService = Get.find<AuthService>();

  // Observables pour l'état des stocks
  final RxList<Stock> stocks = <Stock>[].obs;
  final RxList<Stock> stockAlerts = <Stock>[].obs;
  final RxList<StockMovement> movements = <StockMovement>[].obs;
  final Rx<StockSummary?> summary = Rx<StockSummary?>(null);

  // État de chargement
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAlerts = false.obs;
  final RxBool isLoadingMovements = false.obs;
  final RxBool isLoadingSummary = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt alertsPage = 1.obs;
  final RxInt movementsPage = 1.obs;
  final RxBool hasMoreStocks = true.obs;
  final RxBool hasMoreAlerts = true.obs;
  final RxBool hasMoreMovements = true.obs;

  // Filtres
  final RxnBool alertFilter = RxnBool(null);
  final RxnInt productFilter = RxnInt(null);
  final RxnString movementTypeFilter = RxnString(null);
  final Rxn<DateTime> dateDebutFilter = Rxn<DateTime>(null);
  final Rxn<DateTime> dateFinFilter = Rxn<DateTime>(null);

  // Filtres de recherche et catégorie
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString stockStatusFilter = ''.obs;
  final RxList<String> categories = <String>[].obs;

  // Tri des stocks
  final RxString sortBy = 'nom'.obs; // nom, quantite, prix, reference, dateCreation
  final RxBool sortAscending = true.obs;

  // Tri des mouvements
  final RxString sortByMovements = 'dateCreation'.obs; // dateCreation, typeMouvement
  final RxBool sortMovementsAscending = false.obs; // Par défaut décroissant (plus récent d'abord)

  // Erreurs
  final RxString stocksError = ''.obs;
  final RxString alertsError = ''.obs;
  final RxString movementsError = ''.obs;
  final RxString summaryError = ''.obs;

  // Visibilité du résumé
  final RxBool isSummaryVisible = true.obs;

  // Timer pour auto-refresh
  Timer? _autoRefreshTimer;

  @override
  void onInit() {
    super.onInit();
    // Ne pas charger les données automatiquement - attendre que la page soit prête

    // Écouter les changements de recherche avec debounce
    debounce(searchQuery, (_) => _performSearch(), time: const Duration(milliseconds: 500));

    // Écouter les changements de catégorie
    ever(selectedCategory, (_) => _performSearch());

    // Écouter les changements de statut de stock
    ever(stockStatusFilter, (_) => _performSearch());
  }

  @override
  void onClose() {
    stopAutoRefresh();
    // Réinitialiser tous les filtres et la recherche pour éviter qu'ils persistent
    searchQuery.value = '';
    selectedCategory.value = '';
    stockStatusFilter.value = '';
    alertFilter.value = null;
    productFilter.value = null;
    movementTypeFilter.value = null;
    dateDebutFilter.value = null;
    dateFinFilter.value = null;
    // Réinitialiser le tri
    sortBy.value = 'nom';
    sortAscending.value = true;
    sortByMovements.value = 'dateCreation';
    sortMovementsAscending.value = false;
    super.onClose();
  }

  /// Charge les données initiales
  Future<void> loadInitialData() async {
    // Vérifier si un token d'authentification est disponible
    final token = await _authService.getToken();
    if (token == null) {
      print('❌ Pas de token disponible');
      return;
    }

    // Charger les catégories
    await loadCategories();

    // Charger TOUS les stocks (toutes les pages)
    await _loadAllStocks();
  }

  /// Charge tous les stocks en chargeant toutes les pages
  Future<void> _loadAllStocks() async {
    try {
      print('📚 Début du chargement complet de tous les stocks...');
      currentPage.value = 1;
      hasMoreStocks.value = true;
      stocks.clear();
      isLoading.value = true;
      stocksError.value = '';

      // Charger les pages jusqu'à avoir tous les produits
      while (hasMoreStocks.value) {
        final searchParam = searchQuery.value.isNotEmpty ? searchQuery.value : null;
        final categoryParam = selectedCategory.value.isNotEmpty ? selectedCategory.value : null;
        final alertParam = _getAlertFilterFromStatus();

        final result = await _inventoryService.getStocks(
          page: currentPage.value,
          alerteStock: alertParam,
          produitId: productFilter.value,
          searchQuery: searchParam,
          category: categoryParam,
        );

        final stockList = result.data;
        final pagination = result.pagination;

        print('📄 Page ${pagination.page}: ${stockList.length} stocks chargés');

        stocks.addAll(stockList);

        // Vérifier s'il y a plus de pages
        hasMoreStocks.value = pagination.hasNext;

        if (hasMoreStocks.value) {
          currentPage.value++;
        }
      }

      print('✅ TOUS LES STOCKS CHARGÉS: ${stocks.length} stocks au total');
      currentPage.value = 1; // Réinitialiser pour la pagination après
      hasMoreStocks.value = false;
    } catch (e) {
      print('❌ Erreur lors du chargement complet: $e');
      stocksError.value = e.toString();
      Get.snackbar(
        'Erreur',
        'Impossible de charger les stocks: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge le résumé des stocks
  Future<void> loadSummary() async {
    try {
      isLoadingSummary.value = true;
      summaryError.value = '';

      final result = await _inventoryService.getStockSummary();
      summary.value = result;
    } catch (e) {
      summaryError.value = e.toString();
      Get.snackbar(
        'Erreur',
        'Impossible de charger le résumé des stocks',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoadingSummary.value = false;
    }
  }

  /// Charge la liste des stocks (recharge tous les stocks si refresh=true)
  /// Charge la liste des stocks (recharge tous les stocks si refresh=true)
  Future<void> loadStocks({bool refresh = false}) async {
    if (refresh) {
      await _loadAllStocks();
    }
    // Si pas de refresh, tous les stocks sont déjà chargés
  }

  /// Charge les alertes de stock
  Future<void> loadStockAlerts({bool refresh = false}) async {
    try {
      if (refresh) {
        alertsPage.value = 1;
        hasMoreAlerts.value = true;
        stockAlerts.clear();
      }

      if (!hasMoreAlerts.value) return;

      isLoadingAlerts.value = alertsPage.value == 1;
      alertsError.value = '';

      final result = await _inventoryService.getStockAlerts(
        page: alertsPage.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        category: selectedCategory.value.isEmpty ? null : selectedCategory.value,
      );

      // Extraire les données de la réponse paginée
      final alertsList = result.data;
      final pagination = result.pagination;

      // Vérifier s'il y a plus de données
      hasMoreAlerts.value = pagination.hasNext;

      if (alertsPage.value == 1) {
        stockAlerts.assignAll(alertsList);
      } else {
        stockAlerts.addAll(alertsList);
      }

      alertsPage.value++;
    } catch (e) {
      alertsError.value = e.toString();
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  /// Charge les mouvements de stock
  Future<void> loadMovements({bool refresh = false}) async {
    try {
      if (refresh) {
        movementsPage.value = 1;
        hasMoreMovements.value = true;
        movements.clear();
      }

      if (!hasMoreMovements.value) {
        return;
      }

      isLoadingMovements.value = movementsPage.value == 1;
      movementsError.value = '';

      final result = await _inventoryService.getStockMovements(
        page: movementsPage.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        produitId: productFilter.value,
        typeMouvement: movementTypeFilter.value,
        dateDebut: dateDebutFilter.value,
        dateFin: dateFinFilter.value,
      );

      // Extraire les données de la réponse paginée
      final movementsList = result.data;
      final pagination = result.pagination;

      // Vérifier s'il y a plus de données
      hasMoreMovements.value = pagination.hasNext;

      if (movementsPage.value == 1) {
        movements.assignAll(movementsList);
        // Appliquer le tri lors du premier chargement
        _applySortingToMovements();
      } else {
        movements.addAll(movementsList);
      }

      movementsPage.value++;
    } catch (e) {
      movementsError.value = e.toString();
    } finally {
      isLoadingMovements.value = false;
    }
  }

  /// Applique les filtres pour les stocks
  void applyStockFilters({bool? alerteStock, int? produitId}) {
    alertFilter.value = alerteStock;
    productFilter.value = produitId;
    loadStocks(refresh: true);
  }

  /// Applique les filtres pour les mouvements
  void applyMovementFilters({
    int? produitId,
    String? typeMouvement,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    productFilter.value = produitId;
    movementTypeFilter.value = typeMouvement;
    dateDebutFilter.value = dateDebut;
    dateFinFilter.value = dateFin;
    loadMovements(refresh: true);
  }

  /// Efface tous les filtres
  void clearFilters() {
    alertFilter.value = null;
    productFilter.value = null;
    movementTypeFilter.value = null;
    dateDebutFilter.value = null;
    dateFinFilter.value = null;

    loadStocks(refresh: true);
    loadMovements(refresh: true);
  }

  /// Démarre le rafraîchissement automatique
  void startAutoRefresh() {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadSummary();
      loadStockAlerts(refresh: true);
    });
  }

  /// Arrête le rafraîchissement automatique
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Rafraîchit toutes les données
  Future<void> refreshAll() async {
    await Future.wait([
      loadSummary(),
      loadStocks(refresh: true),
      loadStockAlerts(refresh: true),
      loadMovements(refresh: true),
    ]);
  }

  /// Navigue vers les détails d'un stock
  void goToStockDetail(Stock stock) {
    Get.toNamed('/inventory/stock/${stock.produitId}', arguments: stock);
  }

  /// Navigue vers la création d'un mouvement de stock
  void goToStockMovement([Stock? stock]) {
    print('🚀 Navigation vers /inventory/movement');
    print('   Stock passé: ${stock?.produitId}');
    try {
      Get.toNamed('/inventory/movement', arguments: stock);
      print('✅ Navigation réussie');
    } catch (e) {
      print('❌ Erreur navigation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le formulaire de mouvement: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle la visibilité du résumé des stocks
  void toggleSummaryVisibility() {
    isSummaryVisible.value = !isSummaryVisible.value;
  }

  /// Exporte les stocks en Excel
  Future<String?> exportStockToExcel() async {
    try {
      // Récupérer les données CSV du backend
      final csvData = await _inventoryService.exportStockToCsv(
        alerteStock: alertFilter.value,
        produitId: productFilter.value,
      );

      if (csvData != null) {
        // Convertir en Excel
        return await ExportService.exportStocksFromCsv(csvData);
      }

      return null;
    } catch (e) {
      stocksError.value = e.toString();
      rethrow;
    }
  }

  /// Exporte les mouvements en Excel
  Future<String?> exportMovementsToExcel() async {
    try {
      // Récupérer les données CSV du backend
      final csvData = await _inventoryService.exportMovementsToCsv(
        produitId: productFilter.value,
        typeMouvement: movementTypeFilter.value,
        dateDebut: dateDebutFilter.value,
        dateFin: dateFinFilter.value,
      );

      if (csvData != null) {
        // Convertir en Excel
        return await ExportService.exportMovementsFromCsv(csvData);
      }

      return null;
    } catch (e) {
      movementsError.value = e.toString();
      rethrow;
    }
  }

  /// Crée un mouvement de stock (remplace l'ajustement)
  Future<bool> createStockMovement({
    required int productId,
    required String typeMouvement,
    required int quantite,
    required String motif,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      // Mapper les types de mouvement frontend vers backend
      String backendType;
      int changement;

      switch (typeMouvement) {
        case 'entree':
          backendType = 'achat';
          changement = quantite;
          break;
        case 'sortie':
          backendType = 'vente';
          changement = -quantite;
          break;
        case 'correction':
          backendType = 'ajustement';
          changement = quantite;
          break;
        case 'transfert':
          backendType = 'transfert';
          changement = -quantite;
          break;
        default:
          backendType = 'ajustement';
          changement = quantite;
      }

      // Utiliser le service de mouvements de stock
      await _inventoryService.createStockMovement(
        produitId: productId,
        typeMouvement: backendType,
        changementQuantite: changement,
        notes: notes ?? motif,
      );

      // Recharger les données pour avoir les informations à jour
      await Future.wait([
        loadSummary(),
        loadStocks(refresh: true),
        loadStockAlerts(refresh: true),
        loadMovements(refresh: true),
      ]);

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le mouvement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les catégories disponibles depuis la base de données
  Future<void> loadCategories() async {
    try {
      print('🔄 Chargement des catégories depuis la base de données (inventory module)...');

      // TOUJOURS utiliser le service de catégories pour avoir les vraies données
      final realCategories = await _categoryService.getCategories();

      // Convertir les objets Category en noms de catégories pour compatibilité
      final categoryNames = realCategories.map((category) => category.nom).toList();

      categories.assignAll(categoryNames);
      print('✅ ${categories.length} catégories réelles chargées depuis la base de données');

      // Afficher les catégories pour debug
      for (final cat in categoryNames) {
        print('   - "${cat}"');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des catégories: $e');

      // En cas d'erreur, laisser vide plutôt que d'utiliser des données par défaut
      categories.clear();
      print('❌ Aucune catégorie disponible');

      Get.snackbar(
        'Attention',
        'Impossible de charger les catégories. Veuillez vérifier votre connexion.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    // Log uniquement pour diagnostiquer les problèmes de recherche
    if (query.isNotEmpty) {
      print('🔍 RECHERCHE: "$query"');
    }
    searchQuery.value = query;
    // Recharger toutes les données (stocks, alertes, mouvements)
    loadStocks(refresh: true);
    loadStockAlerts(refresh: true);
    loadMovements(refresh: true);
  }

  /// Met à jour la catégorie sélectionnée
  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// Met à jour le filtre de statut de stock
  void updateStockStatusFilter(String status) {
    stockStatusFilter.value = status;
  }

  /// Met à jour le filtre de type de mouvement
  void updateMovementTypeFilter(String type) {
    movementTypeFilter.value = type.isEmpty ? null : type;
    loadMovements(refresh: true);
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty ||
        selectedCategory.value.isNotEmpty ||
        stockStatusFilter.value.isNotEmpty ||
        movementTypeFilter.value != null ||
        dateDebutFilter.value != null ||
        dateFinFilter.value != null;
  }

  /// Efface tous les filtres
  void clearAllFilters() {
    searchQuery.value = '';
    selectedCategory.value = '';
    stockStatusFilter.value = '';
    movementTypeFilter.value = null;
    dateDebutFilter.value = null;
    dateFinFilter.value = null;

    // Recharger les données
    loadStocks(refresh: true);
    loadMovements(refresh: true);
  }

  /// Effectue une recherche
  void _performSearch() {
    loadStocks(refresh: true);
  }

  /// Convertit le filtre de statut en filtre d'alerte
  bool? _getAlertFilterFromStatus() {
    switch (stockStatusFilter.value) {
      case 'alerte':
        return true;
      case 'rupture':
        return null; // Géré différemment
      case 'disponible':
        return false;
      default:
        return alertFilter.value;
    }
  }

  /// Change l'ordre de tri pour les stocks
  void toggleStockSort() {
    sortAscending.value = !sortAscending.value;
    _applySortingToStocks();
  }

  /// Définit le critère de tri pour les stocks
  void setStockSortBy(String sortField) {
    if (sortBy.value == sortField) {
      // Si on clique sur le même critère, on bascule l'ordre
      sortAscending.value = !sortAscending.value;
    } else {
      // Nouveau critère, trier en ordre croissant par défaut
      sortBy.value = sortField;
      sortAscending.value = true;
    }
    _applySortingToStocks();
  }

  /// Applique le tri à la liste des stocks
  void _applySortingToStocks() {
    final List<Stock> sortedStocks = List.from(stocks);

    switch (sortBy.value) {
      case 'nom':
        sortedStocks.sort((a, b) {
          final nomA = (a.produit?.nom ?? '').toLowerCase();
          final nomB = (b.produit?.nom ?? '').toLowerCase();
          return sortAscending.value ? nomA.compareTo(nomB) : nomB.compareTo(nomA);
        });
        break;
      case 'quantite':
        sortedStocks.sort((a, b) => sortAscending.value ? a.quantiteDisponible.compareTo(b.quantiteDisponible) : b.quantiteDisponible.compareTo(a.quantiteDisponible));
        break;
      case 'reference':
        sortedStocks.sort((a, b) {
          final refA = a.produit?.reference ?? '';
          final refB = b.produit?.reference ?? '';
          return sortAscending.value ? refA.compareTo(refB) : refB.compareTo(refA);
        });
        break;
      case 'dateCreation':
        sortedStocks.sort((a, b) => sortAscending.value ? a.derniereMaj.compareTo(b.derniereMaj) : b.derniereMaj.compareTo(a.derniereMaj));
        break;
    }

    stocks.assignAll(sortedStocks);
    update();
  }

  /// Change l'ordre de tri pour les mouvements
  void toggleMovementsSort() {
    sortMovementsAscending.value = !sortMovementsAscending.value;
    _applySortingToMovements();
  }

  /// Définit le critère de tri pour les mouvements
  void setMovementsSortBy(String sortField) {
    if (sortByMovements.value == sortField) {
      // Si on clique sur le même critère, on bascule l'ordre
      sortMovementsAscending.value = !sortMovementsAscending.value;
    } else {
      // Nouveau critère de tri pour les mouvements
      sortByMovements.value = sortField;
      sortMovementsAscending.value = sortField == 'dateCreation' ? false : true; // Par défaut décroissant pour les dates
    }
    _applySortingToMovements();
  }

  /// Applique le tri à la liste des mouvements
  void _applySortingToMovements() {
    final List<StockMovement> sortedMovements = List.from(movements);

    switch (sortByMovements.value) {
      case 'dateCreation':
        sortedMovements.sort((a, b) => sortMovementsAscending.value ? a.dateMouvement.compareTo(b.dateMouvement) : b.dateMouvement.compareTo(a.dateMouvement));
        break;
      case 'typeMouvement':
        sortedMovements.sort((a, b) {
          final typeA = (a.typeMouvement ?? '').toLowerCase();
          final typeB = (b.typeMouvement ?? '').toLowerCase();
          return sortMovementsAscending.value ? typeA.compareTo(typeB) : typeB.compareTo(typeA);
        });
        break;
    }

    movements.assignAll(sortedMovements);
    update();
  }

  /// Test pour forcer la mise à jour de l'interface
  void testUpdateInterface() {
    print('🔍 TEST: Forçage mise à jour interface');
    print('🔍 TEST: stocks.length = ${stocks.length}');
    stocks.refresh();
    update();
  }
}
