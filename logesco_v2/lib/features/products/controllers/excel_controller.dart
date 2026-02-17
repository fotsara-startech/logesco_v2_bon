import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../services/excel_service.dart';
import '../services/api_product_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../core/services/auth_service.dart';
import '../services/category_management_service.dart';

/// Contrôleur pour la gestion de l'import/export Excel des produits
class ExcelController extends GetxController {
  final ApiProductService _productService = Get.find<ApiProductService>();
  late final ExcelService _excelService;
  InventoryService? _inventoryService;
  CategoryManagementService? _categoryManagementService;

  // États observables
  final RxBool isExporting = false.obs;
  final RxBool isImporting = false.obs;
  final RxString exportStatus = ''.obs;
  final RxString importStatus = ''.obs;
  final RxList<ProductForm> importPreview = <ProductForm>[].obs;
  final RxBool showImportPreview = false.obs;
  final RxList<InitialStock> initialStocksPreview = <InitialStock>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialiser les services
    try {
      _inventoryService = InventoryService(Get.find<AuthService>());
    } catch (e) {
      print('⚠️ InventoryService non disponible: $e');
    }

    try {
      _categoryManagementService = Get.find<CategoryManagementService>();
    } catch (e) {
      print('⚠️ CategoryManagementService non disponible: $e');
    }

    _excelService = ExcelService(
      inventoryService: _inventoryService,
      categoryManagementService: _categoryManagementService,
    );
  }

  /// Exporte tous les produits vers Excel
  Future<void> exportAllProducts() async {
    try {
      isExporting.value = true;
      exportStatus.value = 'Récupération des produits...';

      // Récupérer tous les produits
      List<Product> products = await _productService.getAllProducts();

      if (products.isEmpty) {
        exportStatus.value = 'Aucun produit à exporter';
        Get.snackbar(
          'Information',
          'Aucun produit trouvé pour l\'export',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      exportStatus.value = 'Génération du fichier Excel...';

      // Exporter vers Excel
      String? filePath = await _excelService.exportProductsToExcel(products);

      if (filePath != null) {
        exportStatus.value = 'Export terminé avec succès';

        // Proposer de partager le fichier
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text('${products.length} produits exportés avec succès.\nVoulez-vous partager le fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await _excelService.shareExcelFile(filePath);
                },
                child: const Text('Partager'),
              ),
            ],
          ),
        );
      } else {
        exportStatus.value = 'Erreur lors de l\'export';
        Get.snackbar(
          'Erreur',
          'Impossible d\'exporter les produits',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      exportStatus.value = 'Erreur: $e';
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Importe des produits depuis un fichier Excel avec quantités initiales
  Future<void> importProductsFromExcel() async {
    try {
      isImporting.value = true;
      importStatus.value = 'Sélection du fichier...';

      // Importer depuis Excel
      ImportResult? importResult = await _excelService.importProductsFromExcel();

      if (importResult == null) {
        importStatus.value = 'Import annulé';
        return;
      }

      if (importResult.products.isEmpty) {
        importStatus.value = 'Aucun produit valide trouvé';
        Get.snackbar(
          'Information',
          'Aucun produit valide trouvé dans le fichier',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Afficher l'aperçu pour validation
      importPreview.value = importResult.products;
      initialStocksPreview.value = importResult.initialStocks;
      showImportPreview.value = true;

      String statusMessage = '${importResult.products.length} produits prêts à importer';
      if (importResult.initialStocks.isNotEmpty) {
        statusMessage += ' (${importResult.initialStocks.length} avec stock initial)';
      }
      importStatus.value = statusMessage;
    } catch (e) {
      importStatus.value = 'Erreur: $e';
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'import: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isImporting.value = false;
    }
  }

  /// Confirme et effectue l'import des produits avec stocks initiaux
  Future<void> confirmImport() async {
    try {
      isImporting.value = true;
      importStatus.value = 'Import des produits en cours...';

      // 1. Valider et créer les catégories manquantes
      importStatus.value = 'Validation des catégories...';
      await _excelService.validateAndCreateCategories(importPreview);

      // 2. Importer les produits
      importStatus.value = 'Import des produits en cours...';
      List<Product> importedProducts = await _productService.importProducts(importPreview);

      // 3. Créer un mapping référence -> ID pour les stocks initiaux
      Map<String, int> productIdMap = {};
      for (final product in importedProducts) {
        productIdMap[product.reference] = product.id;
      }

      // 4. Créer les mouvements de stock initiaux si nécessaire
      int stocksCreated = 0;
      if (initialStocksPreview.isNotEmpty && _inventoryService != null) {
        importStatus.value = 'Création des stocks initiaux...';
        stocksCreated = initialStocksPreview.length;
        await _excelService.createInitialStockMovements(initialStocksPreview, productIdMap);
      }

      importStatus.value = 'Import terminé avec succès';
      showImportPreview.value = false;
      importPreview.clear();
      initialStocksPreview.clear();

      String successMessage = '${importedProducts.length} produits importés avec succès';
      if (stocksCreated > 0) {
        successMessage += ' avec $stocksCreated stocks initiaux';
      }

      Get.snackbar(
        'Succès',
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Rafraîchir la liste des produits si nécessaire
      if (Get.isRegistered<GetxController>(tag: 'ProductController')) {
        Get.find<GetxController>(tag: 'ProductController').update();
      }
    } catch (e) {
      importStatus.value = 'Erreur: $e';
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'import: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isImporting.value = false;
    }
  }

  /// Annule l'import en cours
  void cancelImport() {
    showImportPreview.value = false;
    importPreview.clear();
    initialStocksPreview.clear();
    importStatus.value = '';
  }

  /// Génère et partage un template d'import
  Future<void> downloadImportTemplate() async {
    try {
      exportStatus.value = 'Génération du template...';

      String? filePath = await _excelService.generateImportTemplate();

      if (filePath != null) {
        exportStatus.value = 'Template généré';
        await _excelService.shareExcelFile(filePath);

        Get.snackbar(
          'Succès',
          'Template d\'import généré et partagé',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de générer le template',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du template: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Supprime un produit de l'aperçu d'import
  void removeFromImportPreview(int index) {
    if (index >= 0 && index < importPreview.length) {
      importPreview.removeAt(index);
      importStatus.value = '${importPreview.length} produits prêts à importer';
    }
  }

  /// Modifie un produit dans l'aperçu d'import
  void updateImportPreview(int index, ProductForm product) {
    if (index >= 0 && index < importPreview.length) {
      importPreview[index] = product;
    }
  }
}
