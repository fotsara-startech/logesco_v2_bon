import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../subscription/mixins/subscription_verification_mixin.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../printing/models/print_format.dart';

import '../../products/models/product.dart';
import '../../customers/models/customer.dart';
import '../models/sale.dart';
import '../services/sales_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../inventory/models/stock_model.dart' hide Product;
import '../../products/controllers/product_controller.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../company_settings/models/company_profile.dart';
import '../../printing/services/printing_service.dart';
import '../../printing/models/models.dart';
import '../../cash_registers/controllers/cash_session_controller.dart';

class SalesController extends GetxController with SubscriptionVerificationMixin {
  final SalesService _salesService = SalesService(Get.find<AuthService>());
  final InventoryService _inventoryService = InventoryService(Get.find<AuthService>());
  final CompanySettingsService _companyService = CompanySettingsService(Get.find<AuthService>());
  final PrintingService _printingService = PrintingService(Get.find<AuthService>());

  // État des ventes
  final RxList<Sale> _sales = <Sale>[].obs;
  final Rx<Sale?> _currentSale = Rx<Sale?>(null);
  final Rx<Sale?> _lastCreatedSale = Rx<Sale?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isCreating = false.obs;

  // État des informations d'entreprise
  final Rx<CompanyProfile?> _companyProfile = Rx<CompanyProfile?>(null);

  // Gestion des stocks
  final RxMap<int, Stock> _productStocks = <int, Stock>{}.obs;

  // Gestion des produits pour la vente (copie locale avec tri)
  final RxList<Product> _productsForSale = <Product>[].obs;
  final RxString _productSearchQuery = ''.obs;
  final RxString _productSortBy = 'nom'.obs; // nom, prix, reference, categorie
  final RxBool _productSortAscending = true.obs;

  // Panier de vente
  final RxList<CartItem> _cartItems = <CartItem>[].obs;
  final Rx<Customer?> _selectedCustomer = Rx<Customer?>(null);
  final RxString _paymentMode = 'comptant'.obs;
  final RxDouble _discount = 0.0.obs;
  final RxDouble _amountPaid = 0.0.obs;
  final Rx<PrintFormat> _selectedReceiptFormat = PrintFormat.thermal.obs;
  final Rx<DateTime?> _customSaleDate = Rx<DateTime?>(null);

  // Pagination
  final RxInt _currentPage = 1.obs;
  final RxInt _totalPages = 1.obs;
  final RxBool _hasMoreData = true.obs;

  // Filtres
  final RxString _statusFilter = ''.obs;
  final RxString _paymentModeFilter = ''.obs;
  final Rx<DateTime?> _startDateFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> _endDateFilter = Rx<DateTime?>(null);

  // Recherche
  final RxString _searchQuery = ''.obs;
  final RxList<Sale> _filteredSales = <Sale>[].obs;

  // Getters
  List<Sale> get sales => _searchQuery.value.isEmpty ? _sales : _filteredSales;
  Sale? get currentSale => _currentSale.value;
  Sale? get lastCreatedSale => _lastCreatedSale.value;
  bool get isLoading => _isLoading.value;
  bool get isCreating => _isCreating.value;
  CompanyProfile? get companyProfile => _companyProfile.value;

  List<CartItem> get cartItems => _cartItems;
  Customer? get selectedCustomer => _selectedCustomer.value;
  String get paymentMode => _paymentMode.value;
  double get discount => _discount.value;
  double get amountPaid => _amountPaid.value;
  PrintFormat get selectedReceiptFormat => _selectedReceiptFormat.value;
  DateTime? get customSaleDate => _customSaleDate.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  bool get hasMoreData => _hasMoreData.value;

  // Getters pour les filtres
  String get statusFilter => _statusFilter.value;
  String get paymentModeFilter => _paymentModeFilter.value;

  // Getters pour les produits de vente
  List<Product> get productsForSale => _productsForSale;
  String get productSearchQuery => _productSearchQuery.value;
  String get productSortBy => _productSortBy.value;
  bool get productSortAscending => _productSortAscending.value;

  // Calculs du panier
  double get cartSubtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get cartOriginalSubtotal => _cartItems.fold(0.0, (sum, item) => sum + (item.originalPrice * item.quantity));
  double get cartTotal => cartSubtotal - discount;
  double get remainingAmount => cartTotal - amountPaid;

  @override
  void onInit() {
    super.onInit();
    loadSales();
    _initializeStocks();
    _loadCompanyProfile();
    loadProductsForSale(); // Charger les produits pour la vente

    // Vérifier l'abonnement au démarrage
    _initializeSubscriptionChecks();
  }

  /// Initialise les vérifications d'abonnement
  Future<void> _initializeSubscriptionChecks() async {
    // Attendre un peu pour que les services soient initialisés
    await Future.delayed(const Duration(milliseconds: 500));

    // Vérifier et afficher les avertissements d'abonnement
    await checkAndShowSubscriptionWarnings();
  }

  // Chargement du profil d'entreprise
  Future<void> _loadCompanyProfile() async {
    try {
      print('🔄 Chargement du profil d\'entreprise depuis l\'API...');
      final response = await _companyService.getCompanyProfile(forceRefresh: true);
      if (response.success && response.data != null) {
        _companyProfile.value = response.data;
        print('✅ Profil d\'entreprise chargé pour les ventes');
        print('📋 === DONNÉES D\'ENTREPRISE RÉCUPÉRÉES ===');
        print('📋 Nom: ${response.data!.name}');
        print('📋 Adresse: ${response.data!.address}');
        print('📋 Localisation: ${response.data!.location ?? 'Non définie'}');
        print('📋 Téléphone: ${response.data!.phone ?? 'Non défini'}');
        print('📋 Email: ${response.data!.email ?? 'Non défini'}');
        print('📋 NUI/RCCM: ${response.data!.nuiRccm ?? 'Non défini'}');
        print('📋 ========================================');
      } else {
        print('⚠️ Aucun profil d\'entreprise configuré');
        print('💡 Allez dans Paramètres > Entreprise pour configurer les informations');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil d\'entreprise: $e');
    }
  }

  // Méthode publique pour recharger le profil d'entreprise
  Future<void> refreshCompanyProfile() async {
    await _loadCompanyProfile();
  }

  /// Génère manuellement un reçu pour une vente existante
  Future<bool> generateReceiptForSaleId(int saleId, {PrintFormat? format}) async {
    try {
      // Charger la vente si nécessaire
      final sale = _sales.firstWhere((s) => s.id == saleId, orElse: () => throw Exception('Vente non trouvée'));

      await _generateReceiptForSale(sale);
      return true;
    } catch (e) {
      print('❌ Erreur lors de la génération manuelle du reçu: $e');
      SnackbarUtils.showError('Erreur lors de la génération du reçu: $e');
      return false;
    }
  }

  // Initialisation des stocks avec fallback vers les données de test
  Future<void> _initializeStocks() async {
    await loadStocks();

    // Ne pas utiliser automatiquement les données de test
    // L'utilisateur peut les charger manuellement avec le bouton de débogage
    if (_productStocks.isEmpty) {
      print('⚠️ Aucun stock chargé depuis l\'API');
      print('💡 Utilisez le bouton de débogage pour charger des données de test si nécessaire');
    }
  }

  // Méthode pour recharger les stocks manuellement
  Future<void> refreshStocks() async {
    print('🔄 Rafraîchissement manuel des stocks...');
    await loadStocks();

    // Afficher un résumé des stocks chargés
    if (_productStocks.isNotEmpty) {
      final stocksWithQuantity = _productStocks.values.where((s) => s.quantiteDisponible > 0).length;
      final stocksEmpty = _productStocks.values.where((s) => s.quantiteDisponible == 0).length;

      print('📊 Résumé des stocks:');
      print('   - Total produits: ${_productStocks.length}');
      print('   - Avec stock: $stocksWithQuantity');
      print('   - Stock vide: $stocksEmpty');

      // Afficher quelques exemples
      print('📦 Exemples de stocks:');
      _productStocks.entries.take(5).forEach((entry) {
        print('   - Produit ${entry.key}: ${entry.value.quantiteDisponible} unités');
      });
    }
  }

  // Méthode de débogage pour afficher les stocks
  void debugPrintStocks() {
    print('=== DEBUG STOCKS ===');
    print('Total stocks en mémoire: ${_productStocks.length}');

    if (_productStocks.isEmpty) {
      print('⚠️ AUCUN STOCK EN MÉMOIRE!');
      print('💡 Cliquez sur le bouton de rafraîchissement pour charger les stocks');
      return;
    }

    print('\n📦 Liste des stocks:');
    _productStocks.forEach((produitId, stock) {
      print('Produit $produitId: ${stock.quantiteDisponible} disponible, ${stock.quantiteReservee} réservé');
    });

    print('\n📊 Statistiques:');
    final totalDisponible = _productStocks.values.fold(0, (sum, stock) => sum + stock.quantiteDisponible);
    final totalReserve = _productStocks.values.fold(0, (sum, stock) => sum + stock.quantiteReservee);
    print('Total disponible: $totalDisponible');
    print('Total réservé: $totalReserve');
  }

  // Méthode pour forcer l'utilisation des données de test
  void loadTestStocks() {
    print('🧪 Chargement forcé des données de test...');
    _productStocks.clear();

    // Simuler des données de test directement
    final testStocks = [
      Stock(id: 1, produitId: 1, quantiteDisponible: 50, quantiteReservee: 5, derniereMaj: DateTime.now()),
      Stock(id: 2, produitId: 2, quantiteDisponible: 25, quantiteReservee: 0, derniereMaj: DateTime.now()),
      Stock(id: 3, produitId: 3, quantiteDisponible: 3, quantiteReservee: 0, derniereMaj: DateTime.now()), // Correspond au vrai stock
      Stock(id: 4, produitId: 4, quantiteDisponible: 0, quantiteReservee: 0, derniereMaj: DateTime.now()),
      Stock(id: 5, produitId: 5, quantiteDisponible: 75, quantiteReservee: 2, derniereMaj: DateTime.now()),
      Stock(id: 6, produitId: 6, quantiteDisponible: 200, quantiteReservee: 15, derniereMaj: DateTime.now()),
      Stock(id: 7, produitId: 7, quantiteDisponible: 3, quantiteReservee: 1, derniereMaj: DateTime.now()),
      Stock(id: 8, produitId: 8, quantiteDisponible: 150, quantiteReservee: 20, derniereMaj: DateTime.now()),
      Stock(id: 9, produitId: 9, quantiteDisponible: 30, quantiteReservee: 5, derniereMaj: DateTime.now()),
      Stock(id: 10, produitId: 10, quantiteDisponible: 85, quantiteReservee: 8, derniereMaj: DateTime.now()),
    ];

    for (final stock in testStocks) {
      _productStocks[stock.produitId] = stock;
    }

    print('✅ ${_productStocks.length} stocks de test chargés');
    SnackbarUtils.showSuccess('⚠️ ${_productStocks.length} stocks de TEST chargés (pas les vraies données)');
  }

  // Méthode pour vérifier le stock réel d'un produit avant la vente
  Future<bool> verifyRealStock(int productId, int requestedQuantity) async {
    try {
      final response = await _inventoryService.getProductStock(productId);
      if (response.success && response.data != null) {
        final realStock = response.data!;

        if (realStock.quantiteDisponible < requestedQuantity) {
          SnackbarUtils.showError('Stock insuffisant pour ce produit.\n'
              'Affiché: ${getRawStockQuantity(productId)}, '
              'Réel: ${realStock.quantiteDisponible}, '
              'Demandé: $requestedQuantity');
          return false;
        }
        return true;
      }
      return true; // Si on ne peut pas vérifier, on laisse passer
    } catch (e) {
      print('Erreur lors de la vérification du stock: $e');
      return true; // Si on ne peut pas vérifier, on laisse passer
    }
  }

  // Gestion des ventes
  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      print('⏳ [LOADSALES] Refresh demandé, réinitialisation des données');
      _currentPage.value = 1;
      _hasMoreData.value = true;
      _sales.clear();
    }

    if (!_hasMoreData.value) {
      print('⏳ [LOADSALES] Plus de données disponibles');
      return;
    }

    _isLoading.value = true;
    print('⏳ [LOADSALES] Appel API avec filtres: statut=${_statusFilter.value}, modePaiement=${_paymentModeFilter.value}, dateDebut=${_startDateFilter.value}, dateFin=${_endDateFilter.value}');

    try {
      final response = await _salesService.getSales(
        page: _currentPage.value,
        statut: _statusFilter.value.isEmpty ? null : _statusFilter.value,
        modePaiement: _paymentModeFilter.value.isEmpty ? null : _paymentModeFilter.value,
        dateDebut: _startDateFilter.value,
        dateFin: _endDateFilter.value,
      );

      print('⏳ [LOADSALES] Réponse reçue: success=${response.success}, dataCount=${response.data?.length ?? 0}');

      if (response.success && response.data != null) {
        if (refresh) {
          print('⏳ [LOADSALES] Remplacement des données (${response.data!.length} ventes)');
          _sales.assignAll(response.data!);
        } else {
          print('⏳ [LOADSALES] Ajout de données (${response.data!.length} ventes)');
          _sales.addAll(response.data!);
        }

        if (response.pagination != null) {
          _currentPage.value = response.pagination!.page;
          _totalPages.value = response.pagination!.totalPages;
          _hasMoreData.value = _currentPage.value < _totalPages.value;
          print('⏳ [LOADSALES] Pagination: page ${_currentPage.value}/${_totalPages.value}, hasMoreData=${_hasMoreData.value}');
        }
      } else {
        print('⏳ [LOADSALES] Erreur: ${response.message}');
        SnackbarUtils.showError(response.message ?? 'Erreur lors du chargement des ventes');
      }
    } catch (e) {
      print('⏳ [LOADSALES] Exception: $e');
      SnackbarUtils.showError('Erreur lors du chargement des ventes');
    } finally {
      _isLoading.value = false;
      print('⏳ [LOADSALES] Chargement terminé, total ventes: ${_sales.length}');
    }
  }

  Future<void> loadMoreSales() async {
    if (_hasMoreData.value && !_isLoading.value) {
      _currentPage.value++;
      await loadSales();
    }
  }

  Future<void> loadSale(int id) async {
    _isLoading.value = true;

    try {
      final response = await _salesService.getSale(id);
      if (response.success && response.data != null) {
        _currentSale.value = response.data;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors du chargement de la vente');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors du chargement de la vente');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Recherche les ventes par nom du client ou numéro de vente
  void searchSales(String query) {
    _searchQuery.value = query;

    if (query.isEmpty) {
      _filteredSales.clear();
      return;
    }

    final queryLower = query.toLowerCase();
    _filteredSales.assignAll(
      _sales.where((sale) {
        // Recherche par numéro de vente
        if (sale.numeroVente.toLowerCase().contains(queryLower)) {
          return true;
        }

        // Recherche par nom du client
        if (sale.client != null) {
          final fullName = '${sale.client!.nom} ${sale.client!.prenom ?? ''}'.toLowerCase().trim();
          if (fullName.contains(queryLower)) {
            return true;
          }

          // Recherche aussi par nom seul et prénom seul
          if (sale.client!.nom.toLowerCase().contains(queryLower) || (sale.client!.prenom != null && sale.client!.prenom!.toLowerCase().contains(queryLower))) {
            return true;
          }
        }

        return false;
      }).toList(),
    );
  }

  // Gestion des stocks
  Future<void> loadStocks() async {
    try {
      print('🔄 Chargement des stocks...');
      _productStocks.clear();

      int page = 1;
      bool hasMore = true;
      int totalLoaded = 0;

      // Charger toutes les pages de stocks
      while (hasMore) {
        final response = await _inventoryService.getStock(page: page, limit: 100);

        if (response.success && response.data != null) {
          for (final stock in response.data!) {
            _productStocks[stock.produitId] = stock;
            print('Stock chargé - Produit ${stock.produitId}: ${stock.quantiteDisponible}');
          }

          totalLoaded += response.data!.length;

          // Vérifier s'il y a plus de données
          if (response.pagination != null) {
            hasMore = response.pagination!.hasNext;
            page++;
            print('📄 Page $page chargée, ${response.data!.length} stocks');
          } else {
            hasMore = false;
          }
        } else {
          print('❌ Erreur lors du chargement des stocks page $page: ${response.message}');
          hasMore = false;
        }
      }

      print('✅ Total stocks chargés: ${_productStocks.length}');
      if (_productStocks.isNotEmpty) {
        SnackbarUtils.showSuccess('${_productStocks.length} stocks chargés');
      } else {
        print('⚠️ Aucun stock chargé depuis l\'API');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des stocks: $e');
      SnackbarUtils.showError('Erreur de connexion lors du chargement des stocks');
    }
  }

  // Gestion des produits pour la vente
  Future<void> loadProductsForSale() async {
    try {
      print('🔄 Chargement des produits pour la vente...');
      final productController = Get.find<ProductController>();

      // Charger les produits si nécessaire
      if (productController.products.isEmpty) {
        await productController.loadProducts();
      }

      // Copier les produits dans la liste locale
      _productsForSale.assignAll(productController.products);

      // Appliquer le tri
      _applySortingToProducts();

      print('✅ ${_productsForSale.length} produits chargés pour la vente');
    } catch (e) {
      print('❌ Erreur lors du chargement des produits: $e');
      SnackbarUtils.showError('Erreur lors du chargement des produits');
    }
  }

  /// Met à jour la recherche de produits
  void updateProductSearchQuery(String query) {
    _productSearchQuery.value = query;
    _filterAndSortProducts();
  }

  /// Change l'ordre de tri des produits
  void toggleProductSort() {
    _productSortAscending.value = !_productSortAscending.value;
    _applySortingToProducts();
  }

  /// Définit le critère de tri des produits
  void setProductSortBy(String sortField) {
    if (_productSortBy.value == sortField) {
      // Si on clique sur le même critère, on bascule l'ordre
      _productSortAscending.value = !_productSortAscending.value;
    } else {
      // Nouveau critère, trier en ordre croissant par défaut
      _productSortBy.value = sortField;
      _productSortAscending.value = true;
    }
    _applySortingToProducts();
  }

  /// Applique le tri à la liste des produits
  void _applySortingToProducts() {
    final productController = Get.find<ProductController>();
    List<Product> sortedProducts = List.from(productController.products);

    // Appliquer la recherche d'abord
    if (_productSearchQuery.value.isNotEmpty) {
      final query = _productSearchQuery.value.toLowerCase();
      sortedProducts = sortedProducts.where((product) {
        return product.nom.toLowerCase().contains(query) ||
            product.reference.toLowerCase().contains(query) ||
            (product.codeBarre?.toLowerCase().contains(query) ?? false) ||
            (product.categorie?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Appliquer le tri
    switch (_productSortBy.value) {
      case 'nom':
        sortedProducts.sort((a, b) => _productSortAscending.value ? a.nom.toLowerCase().compareTo(b.nom.toLowerCase()) : b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
        break;
      case 'prix':
        sortedProducts.sort((a, b) => _productSortAscending.value ? a.prixUnitaire.compareTo(b.prixUnitaire) : b.prixUnitaire.compareTo(a.prixUnitaire));
        break;
      case 'reference':
        sortedProducts.sort((a, b) => _productSortAscending.value ? a.reference.compareTo(b.reference) : b.reference.compareTo(a.reference));
        break;
      case 'categorie':
        sortedProducts.sort((a, b) {
          final catA = a.categorie ?? '';
          final catB = b.categorie ?? '';
          return _productSortAscending.value ? catA.toLowerCase().compareTo(catB.toLowerCase()) : catB.toLowerCase().compareTo(catA.toLowerCase());
        });
        break;
    }

    _productsForSale.assignAll(sortedProducts);
  }

  /// Filtre et trie les produits
  void _filterAndSortProducts() {
    _applySortingToProducts();
  }

  /// Rafraîchit les produits et les stocks
  Future<void> refreshProductsAndStocks() async {
    await Future.wait([
      loadProductsForSale(),
      loadStocks(),
    ]);
  }

  Stock? getProductStock(int productId) {
    return _productStocks[productId];
  }

  int getAvailableQuantity(int productId) {
    final stock = getProductStock(productId);
    final stockQuantity = stock?.quantiteDisponible ?? 0;

    // Soustraire la quantité déjà dans le panier
    final cartQuantity = _cartItems.where((item) => item.productId == productId).fold(0, (sum, item) => sum + item.quantity);

    final availableQuantity = stockQuantity - cartQuantity;

    return availableQuantity > 0 ? availableQuantity : 0;
  }

  // Méthode pour obtenir la quantité en stock brute (sans tenir compte du panier)
  int getRawStockQuantity(int productId) {
    final stock = getProductStock(productId);
    return stock?.quantiteDisponible ?? 0;
  }

  bool isQuantityAvailable(int productId, int requestedQuantity) {
    // Pour les services, toujours disponible
    final stock = getProductStock(productId);
    if (stock == null) return true; // Probablement un service

    return stock.quantiteDisponible >= requestedQuantity;
  }

  // Gestion du panier
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    // Vérifier le stock pour les produits physiques
    if (!product.estService) {
      final existingQuantity = _cartItems.where((item) => item.productId == product.id).fold(0, (sum, item) => sum + item.quantity);

      final totalRequestedQuantity = existingQuantity + quantity;

      // Vérifier d'abord avec les données locales
      if (!isQuantityAvailable(product.id, totalRequestedQuantity)) {
        final availableQuantity = getAvailableQuantity(product.id);
        SnackbarUtils.showError('Stock insuffisant (local). Disponible: $availableQuantity, Demandé: $totalRequestedQuantity');
        return;
      }

      // Vérifier avec le stock réel de l'API si possible
      final realStockOk = await verifyRealStock(product.id, totalRequestedQuantity);
      if (!realStockOk) {
        return; // Le message d'erreur est déjà affiché dans verifyRealStock
      }
    }

    final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
      _cartItems.refresh();
    } else {
      _cartItems.add(CartItem(
        productId: product.id,
        productName: product.nom,
        productReference: product.reference,
        quantity: quantity,
        unitPrice: product.prixUnitaire,
        originalPrice: product.prixUnitaire,
        maxDiscountAllowed: product.remiseMaxAutorisee,
        discountApplied: 0.0,
      ));
    }
  }

  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        // Vérifier le stock pour les produits physiques
        final stock = getProductStock(productId);
        if (stock != null && !isQuantityAvailable(productId, quantity)) {
          final availableQuantity = getAvailableQuantity(productId);
          SnackbarUtils.showError('Stock insuffisant. Disponible: $availableQuantity, Demandé: $quantity');
          return;
        }

        _cartItems[index].quantity = quantity;
        _cartItems.refresh();
      }
    }
  }

  void updateCartItemPrice(int productId, double price) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      final item = _cartItems[index];

      // 🔧 CORRECTION: Préserver le prix original lors de la modification du prix
      if (item.originalPrice == item.unitPrice) {
        // Le prix original n'a pas encore été modifié, le sauvegarder
        print('💰 REMISE APPLIQUÉE: ${item.productName} (${item.originalPrice} → $price FCFA)');

        _cartItems[index] = item.copyWith(unitPrice: price);
      } else {
        // Le prix original est déjà sauvegardé, juste changer le prix actuel
        _cartItems[index] = item.copyWith(unitPrice: price);
      }

      _cartItems.refresh();
    }
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer.value = null;
    _paymentMode.value = 'comptant';
    _discount.value = 0.0;
    _amountPaid.value = 0.0;
    _customSaleDate.value = null;
  }

  // Configuration de la vente
  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer.value = customer;
  }

  void setPaymentMode(String mode) {
    _paymentMode.value = mode;
    // Ne plus écraser automatiquement le montant payé
    // Le montant payé doit être défini explicitement via setAmountPaid
  }

  void setDiscount(double discount) {
    _discount.value = discount;
    // Ne plus écraser automatiquement le montant payé
    // Le montant payé doit être défini explicitement via setAmountPaid
  }

  void setAmountPaid(double amount) {
    _amountPaid.value = amount;
  }

  void setReceiptFormat(String format) {
    _selectedReceiptFormat.value = format as PrintFormat;
  }

  void setSelectedReceiptFormat(PrintFormat format) {
    _selectedReceiptFormat.value = format;
  }

  void setCustomSaleDate(DateTime? date) {
    _customSaleDate.value = date;
  }

  // Vérifier si l'utilisateur peut antidater les ventes
  bool get canBackdateSales {
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      return currentUser?.role.canBackdateSales ?? false;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification des privilèges d\'antidatage: $e');
      return false;
    }
  }

  // Création de vente
  Future<bool> createSale() async {
    // Vérifier l'abonnement avant de créer une vente
    final canCreateSale = await verifySubscriptionForWrite(actionName: 'Créer une vente');
    if (!canCreateSale) {
      return false;
    }

    // Vérifier qu'une session de caisse est active
    try {
      final cashSessionController = Get.find<CashSessionController>();
      if (!cashSessionController.canMakeSales) {
        SnackbarUtils.showError('Vous devez vous connecter à une caisse pour effectuer des ventes');
        Get.toNamed('/cash-session');
        return false;
      }
    } catch (e) {
      // Si le contrôleur n'est pas trouvé, on continue (mode dégradé)
      print('⚠️ Contrôleur de session de caisse non trouvé: $e');
    }

    if (_cartItems.isEmpty) {
      SnackbarUtils.showError('Le panier est vide');
      return false;
    }

    _isCreating.value = true;

    try {
      // 🔍 DEBUG: Afficher les valeurs avant création de la vente
      print('=== DEBUG CRÉATION VENTE ===');
      print('Client: ${_selectedCustomer.value?.nomComplet ?? "Aucun"}');
      print('Mode paiement: ${_paymentMode.value}');
      print('Montant remise: ${_discount.value}');
      print('Montant payé: ${_amountPaid.value} (type: ${_amountPaid.value.runtimeType})');
      print('Sous-total panier: $cartSubtotal');
      print('Total panier: $cartTotal');
      if (_selectedCustomer.value != null) {
        final customerDebt = _selectedCustomer.value!.solde < 0 ? -_selectedCustomer.value!.solde : 0.0;
        print('Dette client: $customerDebt');
        print('Total à payer (commande + dette): ${cartTotal + customerDebt}');
      }
      print('===========================');

      // 🔍 DEBUG: Vérifier les remises avant envoi au backend
      for (var item in _cartItems) {
        final discount = item.originalPrice - item.unitPrice;
        if (discount > 0) {
          print('💰 ENVOI REMISE AU BACKEND: ${item.productName} (-${discount.toStringAsFixed(0)} FCFA)');
        }
      }

      final request = CreateSaleRequest(
        clientId: _selectedCustomer.value?.id,
        modePaiement: _paymentMode.value,
        montantRemise: _discount.value,
        montantPaye: _amountPaid.value,
        dateVente: _customSaleDate.value,
        details: _cartItems.map((item) {
          final priceDifference = item.originalPrice - item.unitPrice;

          // Si c'est une majoration (prix augmenté), traiter comme prix affiché majoré
          if (priceDifference < 0) {
            return CreateSaleDetailRequest(
              produitId: item.productId,
              quantite: item.quantity,
              prixUnitaire: item.unitPrice, // Prix majoré
              prixAffiche: item.unitPrice, // Même prix affiché
              remiseAppliquee: 0.0, // Pas de remise
              justificationRemise: item.discountJustification,
            );
          }

          // Si c'est une remise (prix réduit)

          return CreateSaleDetailRequest(
            produitId: item.productId,
            quantite: item.quantity,
            prixUnitaire: item.unitPrice, // Prix final après remise
            prixAffiche: item.originalPrice, // Prix original affiché
            remiseAppliquee: priceDifference, // Remise positive
            justificationRemise: item.discountJustification,
          );
        }).toList(),
      );

      final response = await _salesService.createSale(request);

      if (response.success && response.data != null) {
        final sale = response.data!;

        // Sauvegarder la dernière vente créée
        _lastCreatedSale.value = sale;

        // Mettre à jour le solde de la caisse avec le montant payé
        try {
          final cashSessionController = Get.find<CashSessionController>();
          if (cashSessionController.canMakeSales) {
            // Ajouter le montant payé au solde de la caisse
            cashSessionController.addToCurrentBalance(sale.montantPaye);
            print('✅ Solde de caisse mis à jour: +${sale.montantPaye.toStringAsFixed(0)} FCFA');
          }
        } catch (e) {
          print('⚠️ Impossible de mettre à jour le solde de caisse: $e');
        }

        // Générer automatiquement le reçu avec les informations d'entreprise
        await _generateReceiptForSale(sale);

        // SnackbarUtils.showSuccess(response.message ?? 'Vente créée avec succès');
        clearCart();
        _searchQuery.value = ''; // Réinitialiser la recherche
        await loadSales(refresh: true);

        // Recharger les stocks après la vente pour mettre à jour les quantités
        await loadStocks();

        // Notifier les autres contrôleurs de mettre à jour leurs données
        _refreshOtherControllers();

        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la création de la vente');
        return false;
      }
    } catch (e) {
      print('Erreur création vente: $e');
      SnackbarUtils.showError('Erreur de connexion: Vérifiez que le serveur est démarré');
      return false;
    } finally {
      _isCreating.value = false;
    }
  }

  // Génération automatique du reçu après création de vente
  Future<void> _generateReceiptForSale(Sale sale) async {
    try {
      // Vérifier si le profil d'entreprise est disponible
      if (_companyProfile.value == null) {
        print('⚠️ Aucun profil d\'entreprise disponible pour le reçu');
        await _loadCompanyProfile(); // Essayer de recharger
      }

      // Utiliser directement le format sélectionné (est déjà PrintFormat)
      final format = _selectedReceiptFormat.value;

      // Créer la requête de génération de reçu
      final generateRequest = GenerateReceiptRequest(
        saleId: sale.id.toString(),
        format: format,
        includeCompanyInfo: true, // Toujours inclure les infos d'entreprise (mode test utilise des données par défaut)
      );

      // Générer le reçu
      final receiptResponse = await _printingService.generateReceipt(request: generateRequest);

      if (receiptResponse.success && receiptResponse.data != null) {
        print('✅ Reçu généré automatiquement pour la vente ${sale.numeroVente}');

        // Afficher une notification de succès
        Get.snackbar(
          'Reçu généré',
          'Le reçu de la vente ${sale.numeroVente} a été créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.receipt, color: Colors.green),
        );
      } else {
        print('⚠️ Échec de génération du reçu: ${receiptResponse.message}');

        // Afficher une notification d'erreur
        Get.snackbar(
          'Erreur de génération',
          'Impossible de générer le reçu: ${receiptResponse.message}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.warning, color: Colors.orange),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la génération automatique du reçu: $e');
      // Ne pas faire échouer la vente si la génération du reçu échoue
    }
  }

  // Méthode pour rafraîchir les autres contrôleurs après une vente
  void _refreshOtherControllers() {
    try {
      // Rafraîchir le contrôleur de produits si disponible
      if (Get.isRegistered<ProductController>()) {
        final productController = Get.find<ProductController>();
        productController.loadProducts(refresh: true);
        print('✅ ProductController rafraîchi');
      }

      // Rafraîchir le contrôleur d'inventaire si disponible
      if (Get.isRegistered<InventoryController>()) {
        final inventoryController = Get.find<InventoryController>();
        inventoryController.loadStocks(refresh: true);
        print('✅ InventoryController rafraîchi');
      }

      // CORRECTION: Rafraîchir le contrôleur des comptes après une vente
      try {
        // Importer le contrôleur des comptes
        final accountController = Get.find<dynamic>();
        if (accountController.runtimeType.toString().contains('AccountController')) {
          accountController.refreshAll();
          print('✅ AccountController rafraîchi après vente');
        }
      } catch (e) {
        // Si le contrôleur n'est pas encore chargé, essayer de l'importer
        try {
          // Import dynamique pour éviter les dépendances circulaires
          print('🔄 Tentative de rafraîchissement des comptes...');
        } catch (e2) {
          print('ℹ️ AccountController non disponible (normal si module non ouvert)');
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors du rafraîchissement des contrôleurs: $e');
    }
  }

  // Paiement
  Future<bool> addPayment(int saleId, double amount, {String? description}) async {
    // Vérifier l'abonnement avant d'ajouter un paiement
    final canAddPayment = await verifySubscriptionForWrite(actionName: 'Ajouter un paiement');
    if (!canAddPayment) {
      return false;
    }

    _isLoading.value = true;

    try {
      final request = SalePaymentRequest(
        montantPaye: amount,
        description: description,
      );

      final response = await _salesService.addPayment(saleId, request);

      if (response.success) {
        SnackbarUtils.showSuccess(response.message ?? 'Paiement enregistré avec succès');
        _searchQuery.value = '';
        await loadSales(refresh: true);
        if (_currentSale.value?.id == saleId) {
          await loadSale(saleId);
        }
        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de l\'enregistrement du paiement');
        return false;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de l\'enregistrement du paiement');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Annulation
  Future<bool> cancelSale(int saleId) async {
    // Vérifier l'abonnement avant d'annuler une vente
    final canCancelSale = await verifySubscriptionForWrite(actionName: 'Annuler une vente');
    if (!canCancelSale) {
      return false;
    }

    _isLoading.value = true;

    try {
      final response = await _salesService.cancelSale(saleId);

      if (response.success) {
        SnackbarUtils.showSuccess(response.message ?? 'Vente annulée avec succès');
        await loadSales(refresh: true);
        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de l\'annulation de la vente');
        return false;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de l\'annulation de la vente');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Filtres
  void setStatusFilter(String status) {
    _statusFilter.value = status;
    _searchQuery.value = '';
    loadSales(refresh: true);
  }

  void setPaymentModeFilter(String mode) {
    _paymentModeFilter.value = mode;
    _searchQuery.value = '';
    loadSales(refresh: true);
  }

  void setDateFilter(DateTime? startDate, DateTime? endDate) {
    print('🔧 [CONTROLLER] setDateFilter appelé: startDate=$startDate, endDate=$endDate');
    _startDateFilter.value = startDate;
    _endDateFilter.value = endDate;
    _searchQuery.value = ''; // Réinitialiser la recherche quand on applique un filtre
    print('🔧 [CONTROLLER] Filtres définis, appel loadSales(refresh: true)');
    loadSales(refresh: true);
  }

  void clearFilters() {
    _statusFilter.value = '';
    _paymentModeFilter.value = '';
    _startDateFilter.value = null;
    _endDateFilter.value = null;
    _searchQuery.value = ''; // Réinitialiser la recherche
    loadSales(refresh: true);
  }

  /// Récupère le compte d'un client
  Future<Map<String, dynamic>?> getCustomerAccount(int clientId) async {
    try {
      final token = await Get.find<AuthService>().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${Get.find<ApiService>().baseUrl}/customers/$clientId/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du compte client: $e');
      return null;
    }
  }
}
