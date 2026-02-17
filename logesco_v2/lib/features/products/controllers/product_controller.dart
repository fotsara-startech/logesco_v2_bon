import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/product.dart';
import '../services/api_product_service.dart';

/// Contrôleur pour la gestion des produits avec GetX
class ProductController extends GetxController {
  final ApiProductService _productService = Get.find<ApiProductService>();

  // Observables pour l'état de l'interface
  final RxList<Product> products = <Product>[].obs;
  final RxList<String> categories = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Tri des produits
  final RxString sortBy = 'nom'.obs; // nom, prix, reference
  final RxBool sortAscending = true.obs;

  // Pagination (gérée automatiquement - chargement de tous les produits à la fois)
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final int _pageSize = 100; // Limite maximale acceptée par l'API

  // Debouncing pour la recherche
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();

    // Écouter les changements de recherche avec debouncing
    ever(searchQuery, (_) => _debounceSearch());
    ever(selectedCategory, (_) => _resetAndLoadProducts());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    // Réinitialiser tous les filtres pour éviter qu'ils persistent
    searchQuery.value = '';
    selectedCategory.value = '';
    sortBy.value = 'nom';
    sortAscending.value = true;
    super.onClose();
  }

  /// Charge tous les produits à la fois (pagination automatique en arrière-plan)
  Future<void> loadProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
        products.clear();
      }

      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final allProducts = <Product>[];
      int page = 1;
      bool hasMore = true;

      // Charger tous les produits page par page (100 par page max)
      while (hasMore) {
        final pageProducts = await _productService.getProducts(
          search: searchQuery.value.isEmpty ? null : searchQuery.value,
          categorie: selectedCategory.value.isEmpty ? null : selectedCategory.value,
          page: page,
          limit: _pageSize,
        );

        if (pageProducts.isEmpty) {
          hasMore = false;
        } else {
          allProducts.addAll(pageProducts);
          if (pageProducts.length < _pageSize) {
            hasMore = false;
          } else {
            page++;
          }
        }
      }

      // Charger tous les produits en une seule assignation
      products.assignAll(allProducts);
      hasMoreData.value = false;
      currentPage.value = 1;
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement des produits';
      }

      Get.snackbar(
        'Erreur',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Charge les catégories disponibles depuis l'API
  Future<void> loadCategories() async {
    try {
      print('📂 Chargement des catégories depuis l\'API...');

      final apiCategories = await _productService.getCategories();

      // Filtrer les catégories vides et trier
      final validCategories = apiCategories.where((cat) => cat.trim().isNotEmpty).toList()..sort();

      categories.assignAll(validCategories);
      print('✅ ${validCategories.length} catégories chargées: $validCategories');
    } catch (e) {
      print('❌ Erreur lors du chargement des catégories: $e');
      // En cas d'erreur, utiliser une liste vide
      categories.clear();
    }
  }

  /// Recherche avec debouncing
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _resetAndLoadProducts();
    });
  }

  /// Remet à zéro et recharge les produits
  void _resetAndLoadProducts() {
    currentPage.value = 1;
    hasMoreData.value = true;
    loadProducts(refresh: true);
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Met à jour la catégorie sélectionnée
  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// Efface les filtres
  void clearFilters() {
    searchQuery.value = '';
    selectedCategory.value = '';
  }

  /// Change l'ordre de tri
  void toggleSort() {
    sortAscending.value = !sortAscending.value;
    _applySorting();
  }

  /// Définit le critère de tri
  void setSortBy(String sortField) {
    if (sortBy.value == sortField) {
      // Si on clique sur le même critère, on bascule l'ordre
      sortAscending.value = !sortAscending.value;
    } else {
      // Nouveau critère, trier en ordre croissant par défaut
      sortBy.value = sortField;
      sortAscending.value = true;
    }
    _applySorting();
  }

  /// Applique le tri à la liste des produits
  void _applySorting() {
    final List<Product> sortedProducts = List.from(products);

    switch (sortBy.value) {
      case 'nom':
        sortedProducts.sort((a, b) => sortAscending.value ? a.nom.toLowerCase().compareTo(b.nom.toLowerCase()) : b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
        break;
      case 'prix':
        sortedProducts.sort((a, b) => sortAscending.value ? a.prixUnitaire.compareTo(b.prixUnitaire) : b.prixUnitaire.compareTo(a.prixUnitaire));
        break;
      case 'reference':
        sortedProducts.sort((a, b) => sortAscending.value ? a.reference.compareTo(b.reference) : b.reference.compareTo(a.reference));
        break;
      case 'dateCreation':
        sortedProducts.sort((a, b) => sortAscending.value ? a.dateCreation.compareTo(b.dateCreation) : b.dateCreation.compareTo(a.dateCreation));
        break;
    }

    products.assignAll(sortedProducts);
    update();
  }

  /// Rafraîchit la liste des produits
  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  /// Navigue vers la création d'un produit
  void goToCreateProduct() {
    Get.toNamed('/products/create');
  }

  /// Navigue vers l'édition d'un produit
  Future<void> goToEditProduct(Product product) async {
    try {
      print('🔍 Navigation vers édition produit ID: ${product.id}');

      // Récupérer le produit complet avec catégorie résolue via l'API
      final fullProduct = await _productService.getProductById(product.id);

      if (fullProduct != null) {
        print('✅ Produit complet récupéré avec catégorie: "${fullProduct.categorie}"');
        Get.toNamed('/products/${product.id}/edit', arguments: fullProduct);
      } else {
        print('❌ Impossible de récupérer le produit complet');
        // Fallback avec le produit original
        Get.toNamed('/products/${product.id}/edit', arguments: product);
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du produit: $e');
      // Fallback avec le produit original
      Get.toNamed('/products/${product.id}/edit', arguments: product);
    }
  }

  /// Navigue vers les détails d'un produit
  void goToProductDetail(Product product) {
    Get.toNamed('/products/${product.id}', arguments: product);
  }

  /// Supprime un produit avec confirmation
  Future<void> deleteProduct(Product product) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le produit "${product.nom}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        print('=== SUPPRESSION PRODUIT ===');
        print('ID: ${product.id}');
        print('Référence: ${product.reference}');
        print('Nom: ${product.nom}');
        print('========================');

        final success = await _productService.deleteProduct(product.id);

        if (success) {
          products.remove(product);
          print('✅ Produit supprimé de la liste locale');

          Future.delayed(const Duration(milliseconds: 100), () {
            Get.snackbar(
              'Succès',
              'Produit supprimé avec succès',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );
          });
        } else {
          throw Exception('Échec de la suppression');
        }
      } catch (e) {
        print('❌ Erreur suppression: $e');
        String message = 'Erreur lors de la suppression du produit';
        String title = 'Erreur';
        Color backgroundColor = Colors.red.shade100;
        Color textColor = Colors.red.shade800;

        if (e is ApiException) {
          // Vérifier si c'est une erreur de contrainte de clé étrangère
          if (e.message.contains('Foreign key constraint') || e.message.contains('utilisé dans') || e.message.contains('désactivé')) {
            title = 'Information';
            message = 'Ce produit ne peut pas être supprimé car il est utilisé dans des transactions. Il a été désactivé à la place.';
            backgroundColor = Colors.orange.shade100;
            textColor = Colors.orange.shade800;

            // Rafraîchir la liste pour voir le produit désactivé
            await loadProducts();
          } else {
            message = e.message;
          }
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: backgroundColor,
            colorText: textColor,
            duration: const Duration(seconds: 4),
          );
        });
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Bascule l'état actif/inactif d'un produit
  Future<void> toggleProductStatus(Product product) async {
    try {
      final updatedForm = ProductForm.fromProduct(product).copyWith(
        estActif: !product.estActif,
      );

      final updatedProduct = await _productService.updateProduct(
        product.id,
        updatedForm,
      );

      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = updatedProduct;
      }

      Get.snackbar(
        'Succès',
        'Statut du produit mis à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      String message = 'Erreur lors de la mise à jour du statut';
      if (e is ApiException) {
        message = e.message;
      }

      Get.snackbar(
        'Erreur',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Recherche un produit par code-barre
  Future<Product?> searchByBarcode(String barcode) async {
    try {
      return await _productService.getProductByBarcode(barcode);
    } catch (e) {
      print('Erreur recherche par code-barre: $e');
      return null;
    }
  }

  /// Définit les résultats de recherche (pour affichage spécifique)
  void setSearchResults(List<Product> results) {
    products.assignAll(results);
    currentPage.value = 1;
    hasMoreData.value = false; // Pas de pagination pour les résultats spécifiques
  }
}

/// Extension pour ProductForm avec copyWith
extension ProductFormExtension on ProductForm {
  ProductForm copyWith({
    String? reference,
    String? nom,
    String? description,
    double? prixUnitaire,
    double? prixAchat,
    String? codeBarre,
    String? categorie,
    int? seuilStockMinimum,
    bool? estActif,
    bool? estService,
  }) {
    return ProductForm(
      reference: reference ?? this.reference,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixAchat: prixAchat ?? this.prixAchat,
      codeBarre: codeBarre ?? this.codeBarre,
      categorie: categorie ?? this.categorie,
      seuilStockMinimum: seuilStockMinimum ?? this.seuilStockMinimum,
      estActif: estActif ?? this.estActif,
      estService: estService ?? this.estService,
    );
  }
}
