import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/inventory_model.dart';
import '../services/stock_inventory_service.dart';
import '../services/mock_inventory_service.dart';
import '../services/inventory_print_service.dart';
import '../../../core/config/api_config.dart';
import '../../products/services/category_service.dart';

/// Contrôleur pour la gestion de l'inventaire de stock
class StockInventoryController extends GetxController {
  // Services
  final CategoryService _categoryService = Get.find<CategoryService>();

  // État des données
  final RxList<StockInventory> inventories = <StockInventory>[].obs;
  final RxList<InventoryItem> currentInventoryItems = <InventoryItem>[].obs;
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Tri des inventaires
  final RxString sortBy = 'nom'.obs; // nom, date, statut
  final RxBool sortAscending = true.obs;

  // Inventaire sélectionné
  final Rx<StockInventory?> selectedInventory = Rx<StockInventory?>(null);
  final Rx<InventoryItem?> selectedItem = Rx<InventoryItem?>(null);

  @override
  void onInit() {
    super.onInit();
    loadInventories();
    loadCategories();
  }

  @override
  void onClose() {
    // Réinitialiser tous les filtres pour éviter qu'ils persistent
    searchQuery.value = '';
    sortBy.value = 'nom';
    sortAscending.value = true;
    selectedInventory.value = null;
    selectedItem.value = null;
    super.onClose();
  }

  /// Charger tous les inventaires
  Future<void> loadInventories() async {
    try {
      isLoading.value = true;
      final inventoryList = ApiConfig.useTestData ? await MockInventoryService.getAllInventories() : await StockInventoryService.getAllInventories();
      inventories.assignAll(inventoryList);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les inventaires: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger les catégories depuis la base de données
  Future<void> loadCategories() async {
    try {
      print('🔄 Chargement des catégories depuis la base de données...');
      print('🔍 Mode test: ${ApiConfig.useTestData}');

      // TOUJOURS utiliser le service de catégories des produits pour avoir les vraies données
      try {
        print('🔄 Utilisation du service de catégories des produits...');
        final categoryList = await _categoryService.getCategories();

        // Convertir les objets Category en Map pour compatibilité
        final categoryMaps = categoryList
            .map((category) => {
                  'id': category.id,
                  'nom': category.nom,
                  'description': category.description,
                })
            .toList();

        categories.assignAll(categoryMaps);
        print('✅ ${categories.length} catégories réelles chargées depuis la base de données');

        // Afficher les catégories pour debug
        for (final cat in categoryMaps) {
          print('   - ID: ${cat['id']}, Nom: "${cat['nom']}"');
        }

        return; // Succès, on sort de la fonction
      } catch (serviceError) {
        print('❌ Erreur service catégories: $serviceError');

        // Fallback vers l'API directe
        try {
          print('🔄 Tentative de chargement depuis l\'API directe...');
          final categoryList = await StockInventoryService.getCategories();
          categories.assignAll(categoryList);
          print('✅ ${categories.length} catégories chargées depuis l\'API directe');
          return; // Succès, on sort de la fonction
        } catch (apiError) {
          print('❌ Erreur API directe: $apiError');

          // En dernier recours, utiliser les données de test SEULEMENT si configuré
          if (ApiConfig.useTestData) {
            print('🔄 Utilisation des données de test en dernier recours...');
            final categoryList = await MockInventoryService.getCategories();
            categories.assignAll(categoryList);
            print('⚠️ ${categories.length} catégories de test chargées en dernier recours');
          } else {
            // Pas de données de test, laisser vide
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
      }
    } catch (e) {
      print('❌ Erreur générale lors du chargement des catégories: $e');
      categories.clear();
    }
  }

  /// Inventaires filtrés selon la recherche
  List<StockInventory> get filteredInventories {
    if (searchQuery.value.isEmpty) {
      return inventories;
    }
    return inventories.where((inventory) {
      return inventory.nom.toLowerCase().contains(searchQuery.value.toLowerCase()) || (inventory.description != null && inventory.description!.toLowerCase().contains(searchQuery.value.toLowerCase()));
    }).toList();
  }

  /// Créer un nouvel inventaire
  Future<bool> createInventory(StockInventory inventory) async {
    try {
      isLoading.value = true;
      final newInventory = ApiConfig.useTestData ? await MockInventoryService.createInventory(inventory) : await StockInventoryService.createInventory(inventory);
      inventories.add(newInventory);

      Get.snackbar(
        'Succès',
        'Inventaire créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour un inventaire
  Future<bool> updateInventory(StockInventory inventory) async {
    try {
      isLoading.value = true;
      final updatedInventory = ApiConfig.useTestData ? await MockInventoryService.updateInventory(inventory.id!, inventory) : await StockInventoryService.updateInventory(inventory.id!, inventory);

      final index = inventories.indexWhere((i) => i.id == inventory.id);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      Get.snackbar(
        'Succès',
        'Inventaire mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer un inventaire
  Future<bool> deleteInventory(int inventoryId) async {
    try {
      ApiConfig.useTestData ? await MockInventoryService.deleteInventory(inventoryId) : await StockInventoryService.deleteInventory(inventoryId);
      inventories.removeWhere((inventory) => inventory.id == inventoryId);

      Get.snackbar(
        'Succès',
        'Inventaire supprimé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Charger les articles d'un inventaire
  Future<void> loadInventoryItems(int inventoryId) async {
    try {
      isLoading.value = true;
      final items = ApiConfig.useTestData ? await MockInventoryService.getInventoryItems(inventoryId) : await StockInventoryService.getInventoryItems(inventoryId);
      currentInventoryItems.assignAll(items);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les articles: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour un article d'inventaire (comptage)
  Future<bool> updateInventoryItem(int itemId, double quantiteComptee, String? commentaire) async {
    try {
      final updatedItem = ApiConfig.useTestData
          ? await MockInventoryService.updateInventoryItemSimple(itemId, quantiteComptee, commentaire)
          : await StockInventoryService.updateInventoryItem(itemId, quantiteComptee, commentaire);

      final index = currentInventoryItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        currentInventoryItems[index] = updatedItem;
      }

      Get.snackbar(
        'Succès',
        'Article mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'article: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Démarrer un inventaire
  Future<bool> startInventory(int inventoryId) async {
    try {
      final updatedInventory = ApiConfig.useTestData ? await MockInventoryService.startInventorySimple(inventoryId) : await StockInventoryService.startInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      if (selectedInventory.value?.id == inventoryId) {
        selectedInventory.value = updatedInventory;
      }

      Get.snackbar(
        'Succès',
        'Inventaire démarré avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Terminer un inventaire
  Future<bool> finishInventory(int inventoryId) async {
    try {
      final updatedInventory = ApiConfig.useTestData ? await MockInventoryService.finishInventory(inventoryId) : await StockInventoryService.finishInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      if (selectedInventory.value?.id == inventoryId) {
        selectedInventory.value = updatedInventory;
      }

      Get.snackbar(
        'Succès',
        'Inventaire terminé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de terminer l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Clôturer un inventaire
  Future<bool> closeInventory(int inventoryId) async {
    try {
      final updatedInventory = ApiConfig.useTestData ? await MockInventoryService.closeInventorySimple(inventoryId) : await StockInventoryService.closeInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      if (selectedInventory.value?.id == inventoryId) {
        selectedInventory.value = updatedInventory;
      }

      Get.snackbar(
        'Succès',
        'Inventaire clôturé avec succès - Stock équilibré',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de clôturer l\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Imprimer une feuille de comptage
  Future<void> printCountingSheet(int inventoryId) async {
    print('🖨️ Début impression pour inventaire $inventoryId');

    try {
      // Trouver l'inventaire
      final inventory = inventories.firstWhereOrNull((inv) => inv.id == inventoryId);
      if (inventory == null) {
        throw Exception('Inventaire non trouvé');
      }

      // Charger les articles si nécessaire
      if (currentInventoryItems.isEmpty || selectedInventory.value?.id != inventoryId) {
        await loadInventoryItems(inventoryId);
      }

      // Générer et imprimer le PDF
      await InventoryPrintService.printCountingSheet(inventory, currentInventoryItems);

      Get.snackbar(
        'Succès',
        'Feuille de comptage générée et envoyée à l\'imprimante',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer la feuille de comptage: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Imprimer un rapport d'inventaire terminé
  Future<void> printInventoryReport(int inventoryId) async {
    print('🖨️ Début impression rapport pour inventaire $inventoryId');

    try {
      // Trouver l'inventaire
      final inventory = inventories.firstWhereOrNull((inv) => inv.id == inventoryId);
      if (inventory == null) {
        throw Exception('Inventaire non trouvé');
      }

      // Charger les articles si nécessaire
      if (currentInventoryItems.isEmpty || selectedInventory.value?.id != inventoryId) {
        await loadInventoryItems(inventoryId);
      }

      // Générer et imprimer le rapport PDF
      await InventoryPrintService.printInventoryReport(inventory, currentInventoryItems);

      Get.snackbar(
        'Succès',
        'Rapport d\'inventaire généré et envoyé à l\'imprimante',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer le rapport d\'inventaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Sélectionner un inventaire
  void selectInventory(StockInventory? inventory) {
    selectedInventory.value = inventory;
    if (inventory != null) {
      loadInventoryItems(inventory.id!);
    }
  }

  /// Sélectionner un article
  void selectItem(InventoryItem? item) {
    selectedItem.value = item;
  }

  /// Mettre à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Confirmer la suppression d'un inventaire
  void confirmDeleteInventory(StockInventory inventory) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'inventaire "${inventory.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deleteInventory(inventory.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Obtenir les statistiques de progression
  Map<String, dynamic> getProgressStats() {
    if (currentInventoryItems.isEmpty) {
      return {
        'total': 0,
        'counted': 0,
        'remaining': 0,
        'withVariance': 0,
        'progress': 0.0,
      };
    }

    final total = currentInventoryItems.length;
    final counted = currentInventoryItems.where((item) => item.quantiteComptee != null).length;
    final withVariance = currentInventoryItems.where((item) => item.quantiteComptee != null && item.ecart != 0).length;

    return {
      'total': total,
      'counted': counted,
      'remaining': total - counted,
      'withVariance': withVariance,
      'progress': total > 0 ? counted / total : 0.0,
    };
  }

  /// Change l'ordre de tri pour les inventaires
  void toggleInventoriesSort() {
    sortAscending.value = !sortAscending.value;
    _applySortingToInventories();
  }

  /// Définit le critère de tri pour les inventaires
  void setInventoriesSortBy(String sortField) {
    if (sortBy.value == sortField) {
      // Si on clique sur le même critère, on bascule l'ordre
      sortAscending.value = !sortAscending.value;
    } else {
      // Nouveau critère, trier en ordre croissant par défaut
      sortBy.value = sortField;
      sortAscending.value = true;
    }
    _applySortingToInventories();
  }

  /// Applique le tri à la liste des inventaires
  void _applySortingToInventories() {
    final List<StockInventory> sortedInventories = List.from(inventories);

    switch (sortBy.value) {
      case 'nom':
        sortedInventories.sort((a, b) => sortAscending.value ? a.nom.toLowerCase().compareTo(b.nom.toLowerCase()) : b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
        break;
      case 'date':
        sortedInventories.sort((a, b) => sortAscending.value ? a.dateCreation.compareTo(b.dateCreation) : b.dateCreation.compareTo(a.dateCreation));
        break;
      case 'statut':
        sortedInventories.sort((a, b) => sortAscending.value ? a.status.name.compareTo(b.status.name) : b.status.name.compareTo(a.status.name));
        break;
    }

    inventories.assignAll(sortedInventories);
    update();
  }
}
