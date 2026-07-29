import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../models/inventory_model.dart';
import '../services/stock_inventory_service.dart';
import '../services/mock_inventory_service.dart';
import '../services/inventory_print_service.dart';
import '../services/inventory_excel_service.dart';
import '../../../core/config/app_config.dart';
import 'package:share_plus/share_plus.dart';
import '../../products/services/category_service.dart';
import '../../boutiques/controllers/boutique_controller.dart';
import '../../sync/controllers/sync_controller.dart';

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

    // Écouter les changements de boutique active
    try {
      final boutiqueController = Get.find<BoutiqueController>();
      ever(boutiqueController.boutiquesActive, (_) {
        loadInventories();
      });
    } catch (_) {}
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
      final inventoryList = AppConfig.useTestData ? await MockInventoryService.getAllInventories() : await StockInventoryService.getAllInventories();
      inventories.assignAll(inventoryList);
    } catch (e) {
      SnackbarHelper.error('Impossible de charger les inventaires: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger les catégories depuis la base de données
  Future<void> loadCategories() async {
    try {
      print('');
      print('');

      // TOUJOURS utiliser le service de catégories des produits pour avoir les vraies données
      try {
        print('');
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
        print(' ${categories.length} catégories réelles chargées depuis la base de données');

        // Afficher les catégories pour debug
        for (final cat in categoryMaps) {
          print('   - ID: ${cat['id']}, Nom: "${cat['nom']}"');
        }

        return; // Succès, on sort de la fonction
      } catch (serviceError) {
        print(' Erreur service catégories: $serviceError');

        // Fallback vers l'API directe
        try {
          print('🔄 Tentative de chargement depuis l\'API directe...');
          final categoryList = await StockInventoryService.getCategories();
          categories.assignAll(categoryList);
          print(' ${categories.length} catégories chargées depuis l\'API directe');
          return; // Succès, on sort de la fonction
        } catch (apiError) {
          print(' Erreur API directe: $apiError');

          // En dernier recours, utiliser les données de test SEULEMENT si configuré
          if (AppConfig.useTestData) {
            print('');
            final categoryList = await MockInventoryService.getCategories();
            categories.assignAll(categoryList);
            print('⚠️ ${categories.length} catégories de test chargées en dernier recours');
          } else {
            // Pas de données de test, laisser vide
            categories.clear();
            print(' Aucune catégorie disponible');

            SnackbarHelper.warning('Impossible de charger les catégories. Veuillez vérifier votre connexion.');
          }
        }
      }
    } catch (e) {
      print(' Erreur générale lors du chargement des catégories: $e');
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
      final newInventory = AppConfig.useTestData ? await MockInventoryService.createInventory(inventory) : await StockInventoryService.createInventory(inventory);
      inventories.add(newInventory);

      SnackbarHelper.success('Inventaire créé avec succès');

      // Déclencher la synchronisation automatiquement après création
      try {
        final syncController = Get.find<SyncController>();
        if (syncController.isType3) {
          await syncController.triggerSync();
        }
      } catch (e) {
        // Si le SyncController n'est pas disponible, continuer sans erreur
        if (kDebugMode) {
          print('Sync non disponible après création inventaire: $e');
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de créer l\'inventaire: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour un inventaire
  Future<bool> updateInventory(StockInventory inventory) async {
    try {
      isLoading.value = true;
      final updatedInventory = AppConfig.useTestData ? await MockInventoryService.updateInventory(inventory.id!, inventory) : await StockInventoryService.updateInventory(inventory.id!, inventory);

      final index = inventories.indexWhere((i) => i.id == inventory.id);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      SnackbarHelper.success('Inventaire mis à jour avec succès');

      // Déclencher la synchronisation après mise à jour
      try {
        final syncController = Get.find<SyncController>();
        if (syncController.isType3) {
          await syncController.triggerSync();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Sync non disponible après mise à jour inventaire: $e');
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de mettre à jour l\'inventaire: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer un inventaire
  Future<bool> deleteInventory(int inventoryId) async {
    try {
      AppConfig.useTestData ? await MockInventoryService.deleteInventory(inventoryId) : await StockInventoryService.deleteInventory(inventoryId);
      inventories.removeWhere((inventory) => inventory.id == inventoryId);

      SnackbarHelper.success('Inventaire supprimé avec succès');

      // Déclencher la synchronisation après suppression
      try {
        final syncController = Get.find<SyncController>();
        if (syncController.isType3) {
          await syncController.triggerSync();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Sync non disponible après suppression inventaire: $e');
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de supprimer l\'inventaire: $e');
      return false;
    }
  }

  /// Charger les articles d'un inventaire
  Future<void> loadInventoryItems(int inventoryId) async {
    try {
      isLoading.value = true;
      final items = AppConfig.useTestData ? await MockInventoryService.getInventoryItems(inventoryId) : await StockInventoryService.getInventoryItems(inventoryId);
      currentInventoryItems.assignAll(items);
    } catch (e) {
      SnackbarHelper.error('Impossible de charger les articles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour un article d'inventaire (comptage)
  Future<bool> updateInventoryItem(int itemId, double quantiteComptee, String? commentaire) async {
    try {
      final updatedItem = AppConfig.useTestData
          ? await MockInventoryService.updateInventoryItemSimple(itemId, quantiteComptee, commentaire)
          : await StockInventoryService.updateInventoryItem(itemId, quantiteComptee, commentaire);

      final index = currentInventoryItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        currentInventoryItems[index] = updatedItem;
      }

      SnackbarHelper.success('Article mis à jour avec succès');
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de mettre à jour l\'article: $e');
      return false;
    }
  }

  /// Démarrer un inventaire
  Future<bool> startInventory(int inventoryId) async {
    try {
      final updatedInventory = AppConfig.useTestData ? await MockInventoryService.startInventorySimple(inventoryId) : await StockInventoryService.startInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      if (selectedInventory.value?.id == inventoryId) {
        selectedInventory.value = updatedInventory;
      }

      SnackbarHelper.success('Inventaire démarré avec succès');
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de démarrer l\'inventaire: $e');
      return false;
    }
  }

  /// Terminer un inventaire
  Future<bool> finishInventory(int inventoryId) async {
    try {
      final updatedInventory = AppConfig.useTestData ? await MockInventoryService.finishInventory(inventoryId) : await StockInventoryService.finishInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) {
        inventories[index] = updatedInventory;
      }

      if (selectedInventory.value?.id == inventoryId) {
        selectedInventory.value = updatedInventory;
      }

      SnackbarHelper.success('Inventaire terminé avec succès');

      // Déclencher la synchronisation après fin d'inventaire
      try {
        final syncController = Get.find<SyncController>();
        if (syncController.isType3) {
          await syncController.triggerSync();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Sync non disponible après fin inventaire: $e');
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de terminer l\'inventaire: $e');
      return false;
    }
  }

  /// Clôturer un inventaire
  Future<bool> closeInventory(int inventoryId) async {
    // Confirmation avant clôture
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la clôture'),
        content: const Text(
          'La clôture va ajuster le stock de la boutique selon les écarts constatés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      isLoading.value = true;
      final updatedInventory = AppConfig.useTestData ? await MockInventoryService.closeInventorySimple(inventoryId) : await StockInventoryService.closeInventory(inventoryId);

      final index = inventories.indexWhere((i) => i.id == inventoryId);
      if (index != -1) inventories[index] = updatedInventory;
      if (selectedInventory.value?.id == inventoryId) selectedInventory.value = updatedInventory;

      SnackbarHelper.success('Inventaire clôturé - Stock boutique équilibré');

      // Déclencher la synchronisation après clôture (très important car modifie le stock)
      try {
        final syncController = Get.find<SyncController>();
        if (syncController.isType3) {
          await syncController.triggerSync();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Sync non disponible après clôture inventaire: $e');
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de clôturer l\'inventaire: $e');
      return false;
    } finally {
      isLoading.value = false;
      // Recharger pour s'assurer que l'état est à jour
      await loadInventories();
    }
  }

  /// Exporter la feuille de comptage en PDF et l'ouvrir
  Future<void> printCountingSheet(int inventoryId) async {
    try {
      final inventory = inventories.firstWhereOrNull((inv) => inv.id == inventoryId);
      if (inventory == null) throw Exception('Inventaire non trouvé');

      if (currentInventoryItems.isEmpty || selectedInventory.value?.id != inventoryId) {
        await loadInventoryItems(inventoryId);
      }

      final filePath = await InventoryPrintService.printCountingSheet(inventory, currentInventoryItems);

      if (filePath != null) {
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          SnackbarHelper.success(
            'Feuille de comptage téléchargée: $filename',
            title: 'Export réussi',
            duration: const Duration(seconds: 3),
          );
        } else {
          SnackbarHelper.success('Feuille de comptage exportée et ouverte');
        }
      } else {
        SnackbarHelper.error('Impossible de générer la feuille de comptage');
      }
    } catch (e) {
      print('❌ Erreur export feuille de comptage: $e');
      SnackbarHelper.error('Impossible de générer la feuille de comptage: $e');
    }
  }

  /// Exporter le rapport d'inventaire en PDF et l'ouvrir
  Future<void> printInventoryReport(int inventoryId) async {
    try {
      final inventory = inventories.firstWhereOrNull((inv) => inv.id == inventoryId);
      if (inventory == null) throw Exception('Inventaire non trouvé');

      if (currentInventoryItems.isEmpty || selectedInventory.value?.id != inventoryId) {
        await loadInventoryItems(inventoryId);
      }

      final filePath = await InventoryPrintService.printInventoryReport(inventory, currentInventoryItems);

      if (filePath != null) {
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          SnackbarHelper.success(
            'Rapport d\'inventaire téléchargé: $filename',
            title: 'Export réussi',
            duration: const Duration(seconds: 3),
          );
        } else {
          SnackbarHelper.success('Rapport d\'inventaire exporté et ouvert');
        }
      } else {
        SnackbarHelper.error('Impossible de générer le rapport d\'inventaire');
      }
    } catch (e) {
      print('❌ Erreur export rapport inventaire: $e');
      SnackbarHelper.error('Impossible de générer le rapport d\'inventaire: $e');
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
        content: Text('Êtestes-vous sûr de vouloir supprimer l\'inventaire "${inventory.nom}" ?'),
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

  /// Exporter la fiche de comptage en Excel
  Future<void> exportCountingSheetToExcel(int inventoryId) async {
    try {
      isLoading.value = true;

      final inventory = inventories.firstWhereOrNull((inv) => inv.id == inventoryId);
      if (inventory == null) {
        throw Exception('Inventaire non trouvé');
      }

      // Charger les items si nécessaire
      if (currentInventoryItems.isEmpty || selectedInventory.value?.id != inventoryId) {
        await loadInventoryItems(inventoryId);
      }

      // Exporter vers Excel
      final filePath = await InventoryExcelService.exportCountingSheet(
        inventory,
        currentInventoryItems,
      );

      // Partager le fichier
      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Fiche de comptage - ${inventory.nom}',
          text: 'Fiche de comptage Excel à remplir et réimporter',
        );
      }

      SnackbarHelper.success(
        'Fiche de comptage exportée avec succès',
        title: 'Export Excel',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Erreur export Excel: $e');
      SnackbarHelper.error('Impossible d\'exporter la fiche: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Importer la fiche de comptage depuis Excel
  Future<void> importCountingSheetFromExcel() async {
    try {
      isLoading.value = true;

      // Importer depuis Excel
      final imports = await InventoryExcelService.importCountingSheet();

      if (imports.isEmpty) {
        SnackbarHelper.warning('Aucune donnée de comptage trouvée dans le fichier');
        return;
      }

      // Correspondre les imports avec les items existants
      int updatedCount = 0;
      int notFoundCount = 0;
      final errors = <String>[];

      for (final import in imports) {
        // Trouver l'item correspondant par code ou par nom
        InventoryItem? matchingItem;

        if (import.codeProduit != null && import.codeProduit!.isNotEmpty) {
          matchingItem = currentInventoryItems.firstWhereOrNull(
            (item) => item.codeProduit?.toLowerCase() == import.codeProduit!.toLowerCase(),
          );
        }

        // Si pas trouvé par code, chercher par nom
        if (matchingItem == null) {
          matchingItem = currentInventoryItems.firstWhereOrNull(
            (item) => item.nomProduit.toLowerCase() == import.nomProduit.toLowerCase(),
          );
        }

        if (matchingItem != null) {
          // Mettre à jour l'item
          try {
            final success = await updateInventoryItem(
              matchingItem.id!,
              import.quantiteComptee,
              import.commentaire,
            );
            if (success) {
              updatedCount++;
            } else {
              errors.add(import.nomProduit);
            }
          } catch (e) {
            errors.add('${import.nomProduit}: $e');
          }
        } else {
          notFoundCount++;
          if (kDebugMode) {
            print('⚠️ Produit non trouvé: ${import.codeProduit ?? ''} - ${import.nomProduit}');
          }
        }
      }

      // Afficher le résultat
      if (updatedCount > 0) {
        String message = '$updatedCount comptage(s) importé(s) avec succès';
        if (notFoundCount > 0) {
          message += '\n$notFoundCount produit(s) non trouvé(s)';
        }
        if (errors.isNotEmpty) {
          message += '\n${errors.length} erreur(s)';
        }

        SnackbarHelper.success(
          message,
          title: 'Import Excel',
          duration: const Duration(seconds: 5),
        );

        // Recharger les items pour avoir les données à jour
        if (selectedInventory.value?.id != null) {
          await loadInventoryItems(selectedInventory.value!.id!);
        }
      } else {
        SnackbarHelper.warning('Aucun comptage n\'a pu être importé');
      }
    } catch (e) {
      print('❌ Erreur import Excel: $e');
      SnackbarHelper.error('Impossible d\'importer la fiche: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
