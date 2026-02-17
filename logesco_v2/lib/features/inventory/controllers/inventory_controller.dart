import 'dart:async';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../services/inventory_service.dart';
import '../services/export_service.dart';
import '../../subscription/mixins/subscription_verification_mixin.dart';

class InventoryController extends GetxController with SubscriptionVerificationMixin {
  final InventoryService _inventoryService;

  InventoryController(this._inventoryService);

  @override
  void onInit() {
    super.onInit();
    _initializeSubscriptionChecks();
  }

  /// Initialise les vérifications d'abonnement
  Future<void> _initializeSubscriptionChecks() async {
    // Attendre un peu pour que les services soient initialisés
    await Future.delayed(const Duration(milliseconds: 500));

    // Vérifier et afficher les avertissements d'abonnement
    await checkAndShowSubscriptionWarnings();
  }

  // État des stocks (reactive)
  final RxList<Stock> _stocks = <Stock>[].obs;
  final RxList<Stock> _stockAlerts = <Stock>[].obs;
  final RxList<StockMovement> _movements = <StockMovement>[].obs;
  final Rx<StockSummary?> _summary = Rx<StockSummary?>(null);

  // État de chargement (reactive)
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingAlerts = false.obs;
  final RxBool _isLoadingMovements = false.obs;
  final RxBool _isLoadingSummary = false.obs;

  // Pagination (reactive)
  final RxInt _currentPage = 1.obs;
  final RxInt _alertsPage = 1.obs;
  final RxInt _movementsPage = 1.obs;
  final RxBool _hasMoreStocks = true.obs;
  final RxBool _hasMoreAlerts = true.obs;
  final RxBool _hasMoreMovements = true.obs;

  // Filtres (reactive)
  final Rx<bool?> _alertFilter = Rx<bool?>(null);
  final Rx<int?> _productFilter = Rx<int?>(null);
  final Rx<String?> _movementTypeFilter = Rx<String?>(null);
  final Rx<DateTime?> _dateDebutFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> _dateFinFilter = Rx<DateTime?>(null);

  // Erreurs (reactive)
  final RxString _error = ''.obs;
  final RxString _alertsError = ''.obs;
  final RxString _movementsError = ''.obs;
  final RxString _summaryError = ''.obs;

  // Timer pour le rafraîchissement automatique
  Timer? _refreshTimer;

  // Getters
  List<Stock> get stocks => _stocks;
  List<Stock> get stockAlerts => _stockAlerts;
  List<StockMovement> get movements => _movements;
  StockSummary? get summary => _summary.value;

  bool get isLoading => _isLoading.value;
  bool get isLoadingAlerts => _isLoadingAlerts.value;
  bool get isLoadingMovements => _isLoadingMovements.value;
  bool get isLoadingSummary => _isLoadingSummary.value;

  bool get hasMoreStocks => _hasMoreStocks.value;
  bool get hasMoreAlerts => _hasMoreAlerts.value;
  bool get hasMoreMovements => _hasMoreMovements.value;

  String? get error => _error.value.isEmpty ? null : _error.value;
  String? get alertsError => _alertsError.value.isEmpty ? null : _alertsError.value;
  String? get movementsError => _movementsError.value.isEmpty ? null : _movementsError.value;
  String? get summaryError => _summaryError.value.isEmpty ? null : _summaryError.value;

  // Filtres actuels
  bool? get alertFilter => _alertFilter.value;
  int? get productFilter => _productFilter.value;
  String? get movementTypeFilter => _movementTypeFilter.value;
  DateTime? get dateDebutFilter => _dateDebutFilter.value;
  DateTime? get dateFinFilter => _dateFinFilter.value;

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Démarre le rafraîchissement automatique
  void startAutoRefresh({Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      refreshSummary();
      if (_stocks.isNotEmpty) {
        loadStocks(refresh: true);
      }
      if (_stockAlerts.isNotEmpty) {
        loadStockAlerts(refresh: true);
      }
    });
  }

  /// Arrête le rafraîchissement automatique
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  /// Charge la liste des stocks
  Future<void> loadStocks({
    bool refresh = false,
    bool? alerteStock,
    int? produitId,
  }) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMoreStocks.value = true;
      _stocks.clear();
    }

    if (!_hasMoreStocks.value || _isLoading.value) return;

    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _inventoryService.getStocks(
        page: _currentPage.value,
        alerteStock: alerteStock ?? _alertFilter.value,
        produitId: produitId ?? _productFilter.value,
      );

      if (refresh) {
        _stocks.assignAll(response.data);
      } else {
        _stocks.addAll(response.data);
      }

      _currentPage.value++;
      _hasMoreStocks.value = response.pagination.hasNext;

      // Mettre à jour les filtres
      _alertFilter.value = alerteStock ?? _alertFilter.value;
      _productFilter.value = produitId ?? _productFilter.value;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Charge les alertes de stock
  Future<void> loadStockAlerts({bool refresh = false}) async {
    if (refresh) {
      _alertsPage.value = 1;
      _hasMoreAlerts.value = true;
      _stockAlerts.clear();
    }

    if (!_hasMoreAlerts.value || _isLoadingAlerts.value) return;

    _isLoadingAlerts.value = true;
    _alertsError.value = '';

    try {
      final response = await _inventoryService.getStockAlerts(
        page: _alertsPage.value,
      );

      if (refresh) {
        _stockAlerts.assignAll(response.data);
      } else {
        _stockAlerts.addAll(response.data);
      }

      _alertsPage.value++;
      _hasMoreAlerts.value = response.pagination.hasNext;
    } catch (e) {
      _alertsError.value = e.toString();
    } finally {
      _isLoadingAlerts.value = false;
    }
  }

  /// Charge les mouvements de stock
  Future<void> loadMovements({
    bool refresh = false,
    int? produitId,
    String? typeMouvement,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    if (refresh) {
      _movementsPage.value = 1;
      _hasMoreMovements.value = true;
      _movements.clear();
    }

    if (!_hasMoreMovements.value || _isLoadingMovements.value) return;

    _isLoadingMovements.value = true;
    _movementsError.value = '';

    try {
      final response = await _inventoryService.getStockMovements(
        page: _movementsPage.value,
        produitId: produitId ?? _productFilter.value,
        typeMouvement: typeMouvement ?? _movementTypeFilter.value,
        dateDebut: dateDebut ?? _dateDebutFilter.value,
        dateFin: dateFin ?? _dateFinFilter.value,
      );

      if (refresh) {
        _movements.assignAll(response.data);
      } else {
        _movements.addAll(response.data);
      }

      _movementsPage.value++;
      _hasMoreMovements.value = response.pagination.hasNext;

      // Mettre à jour les filtres
      _movementTypeFilter.value = typeMouvement ?? _movementTypeFilter.value;
      _dateDebutFilter.value = dateDebut ?? _dateDebutFilter.value;
      _dateFinFilter.value = dateFin ?? _dateFinFilter.value;
    } catch (e) {
      _movementsError.value = e.toString();
    } finally {
      _isLoadingMovements.value = false;
    }
  }

  /// Charge le résumé du stock
  Future<void> loadSummary() async {
    _isLoadingSummary.value = true;
    _summaryError.value = '';

    try {
      _summary.value = await _inventoryService.getStockSummary();
    } catch (e) {
      _summaryError.value = e.toString();
    } finally {
      _isLoadingSummary.value = false;
    }
  }

  /// Rafraîchit le résumé
  Future<void> refreshSummary() async {
    try {
      _summary.value = await _inventoryService.getStockSummary();
    } catch (e) {
      // Erreur silencieuse pour le rafraîchissement automatique
    }
  }

  /// Ajuste le stock d'un produit
  Future<bool> adjustStock({
    required int produitId,
    required int changementQuantite,
    String? notes,
  }) async {
    // Vérifier l'abonnement avant d'ajuster le stock
    final canAdjustStock = await verifySubscriptionForWrite(actionName: 'Ajuster le stock');
    if (!canAdjustStock) {
      return false;
    }

    try {
      await _inventoryService.adjustStock(
        produitId: produitId,
        changementQuantite: changementQuantite,
        notes: notes,
      );

      // Effacer les filtres pour éviter que la liste ne soit filtrée
      _productFilter.value = null;
      _alertFilter.value = null;

      // Recharger la liste complète
      await loadStocks(refresh: true);

      // Rafraîchir le résumé
      refreshSummary();

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    }
  }

  /// Effectue un ajustement en lot
  Future<BulkAdjustmentResponse?> bulkAdjustStock(BulkAdjustmentRequest request) async {
    // Vérifier l'abonnement avant l'ajustement en lot
    final canBulkAdjust = await verifySubscriptionForWrite(actionName: 'Ajustement en lot');
    if (!canBulkAdjust) {
      return null;
    }

    try {
      final response = await _inventoryService.bulkAdjustStock(request);

      // Rafraîchir les données après l'ajustement
      await loadStocks(refresh: true);
      refreshSummary();

      return response;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  /// Récupère le stock d'un produit spécifique
  Future<Stock?> getStockByProductId(int productId) async {
    try {
      return await _inventoryService.getStockByProductId(productId);
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  /// Applique des filtres aux stocks
  void applyStockFilters({
    bool? alerteStock,
    int? produitId,
  }) {
    _alertFilter.value = alerteStock;
    _productFilter.value = produitId;
    loadStocks(refresh: true);
  }

  /// Applique des filtres aux mouvements
  void applyMovementFilters({
    int? produitId,
    String? typeMouvement,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    _productFilter.value = produitId;
    _movementTypeFilter.value = typeMouvement;
    _dateDebutFilter.value = dateDebut;
    _dateFinFilter.value = dateFin;
    loadMovements(refresh: true);
  }

  /// Efface tous les filtres
  void clearFilters() {
    _alertFilter.value = null;
    _productFilter.value = null;
    _movementTypeFilter.value = null;
    _dateDebutFilter.value = null;
    _dateFinFilter.value = null;
    loadStocks(refresh: true);
    loadMovements(refresh: true);
  }

  /// Exporte les stocks en Excel
  Future<String?> exportStockToExcel() async {
    // Vérifier l'abonnement pour les fonctionnalités d'export (premium)
    final canExport = await verifySubscriptionForPremium(featureName: 'Export Excel');
    if (!canExport) {
      return null;
    }

    try {
      // Récupérer les données CSV du backend
      final csvData = await _inventoryService.exportStockToCsv(
        alerteStock: _alertFilter.value,
        produitId: _productFilter.value,
      );

      if (csvData != null) {
        // Convertir en Excel
        return await ExportService.exportStocksFromCsv(csvData);
      }

      return null;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  /// Exporte les mouvements en Excel
  Future<String?> exportMovementsToExcel() async {
    // Vérifier l'abonnement pour les fonctionnalités d'export (premium)
    final canExport = await verifySubscriptionForPremium(featureName: 'Export mouvements Excel');
    if (!canExport) {
      return null;
    }

    try {
      // Récupérer les données CSV du backend
      final csvData = await _inventoryService.exportMovementsToCsv(
        produitId: _productFilter.value,
        typeMouvement: _movementTypeFilter.value,
        dateDebut: _dateDebutFilter.value,
        dateFin: _dateFinFilter.value,
      );

      if (csvData != null) {
        // Convertir en Excel
        return await ExportService.exportMovementsFromCsv(csvData);
      }

      return null;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }
}
