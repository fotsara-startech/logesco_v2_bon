import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
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
      exportStatus.value = 'products_recuperation_produits'.tr;

      // Récupérer tous les produits
      List<Product> products = await _productService.getAllProducts();

      if (products.isEmpty) {
        exportStatus.value = 'products_aucun_produit_exporter'.tr;
        SnackbarHelper.info('products_aucun_produit_trouve_export'.tr, title: 'Information');
        return;
      }

      exportStatus.value = 'customers_export_generating'.tr;

      // Exporter vers Excel
      String? filePath = await _excelService.exportProductsToExcel(products);

      if (filePath != null) {
        exportStatus.value = 'products_export_termine_avec_succes'.tr;

        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          // Sur le web, le fichier est automatiquement téléchargé
          SnackbarHelper.success(
            'products_produits_exportes_nfichier'.trParams({'length': '${products.length}', 'filename': '${filename}'}),
            title: 'customers_export_success'.tr,
            duration: const Duration(seconds: 4),
          );
        } else {
          // Sur desktop/mobile, proposer de partager
          Get.dialog(
            AlertDialog(
              title: Text('customers_export_success'.tr),
              content: Text('products_produits_exportes_avec_succes_nfichier_nvoulez'.trParams({'length': '${products.length}', 'filename': '${filename}'})),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('suppliers_close'.tr),
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
        }
      } else {
        exportStatus.value = 'products_erreur_lors_export_2'.tr;
        SnackbarHelper.error('products_impossible_exporter_produits'.tr);
      }
    } catch (e) {
      exportStatus.value = 'products_erreur'.trParams({'e': '${e}'});
      print('❌ Erreur export produits: $e');
      SnackbarHelper.error('products_erreur_lors_export'.trParams({'e': '${e}'}));
    } finally {
      isExporting.value = false;
    }
  }

  /// Importe des produits depuis un fichier Excel avec quantités initiales
  Future<void> importProductsFromExcel() async {
    try {
      isImporting.value = true;
      importStatus.value = 'suppliers_selection_fichier'.tr;

      // Importer depuis Excel
      ImportResult? importResult = await _excelService.importProductsFromExcel();

      if (importResult == null) {
        importStatus.value = 'products_import_annule'.tr;
        return;
      }

      if (importResult.products.isEmpty) {
        importStatus.value = 'products_aucun_produit_valide_trouve'.tr;
        SnackbarHelper.info('products_aucun_produit_valide_trouve_dans_fichier'.tr, title: 'Information');
        return;
      }

      // Afficher l'aperçu pour validation
      importPreview.value = importResult.products;
      initialStocksPreview.value = importResult.initialStocks;
      showImportPreview.value = true;

      String statusMessage = 'products_produits_prets_importer'.trParams({'length': '${importResult.products.length}'});
      if (importResult.initialStocks.isNotEmpty) {
        statusMessage += 'products_avec_stock_initial'.trParams({'length': '${importResult.initialStocks.length}'});
      }
      importStatus.value = statusMessage;
    } catch (e) {
      importStatus.value = 'products_erreur'.trParams({'e': '${e}'});
      SnackbarHelper.error('products_erreur_lors_import'.trParams({'e': '${e}'}));
    } finally {
      isImporting.value = false;
    }
  }

  /// Confirme et effectue l'import des produits avec stocks initiaux
  Future<void> confirmImport() async {
    try {
      isImporting.value = true;
      importStatus.value = 'products_import_produits_cours'.tr;

      // 1. Valider et créer les catégories manquantes
      importStatus.value = 'products_validation_categories'.tr;
      await _excelService.validateAndCreateCategories(importPreview);

      // 2. Importer les produits
      importStatus.value = 'products_import_produits_cours'.tr;
      List<Product> importedProducts = await _productService.importProducts(importPreview);

      // 3. Créer un mapping référence -> ID pour les stocks initiaux
      Map<String, int> productIdMap = {};
      for (final product in importedProducts) {
        productIdMap[product.reference] = product.id;
      }

      // 4. Créer les mouvements de stock initiaux si nécessaire
      int stocksCreated = 0;
      if (initialStocksPreview.isNotEmpty && _inventoryService != null) {
        importStatus.value = 'products_creation_stocks_initiaux'.tr;
        stocksCreated = initialStocksPreview.length;
        await _excelService.createInitialStockMovements(initialStocksPreview, productIdMap);
      }

      importStatus.value = 'products_import_termine_avec_succes'.tr;
      showImportPreview.value = false;
      importPreview.clear();
      initialStocksPreview.clear();

      String successMessage = 'products_produits_importes_avec_succes'.trParams({'length': '${importedProducts.length}'});
      if (stocksCreated > 0) {
        successMessage += 'products_avec_stocks_initiaux'.trParams({'stocksCreated': '${stocksCreated}'});
      }

      SnackbarHelper.success(successMessage);

      // Rafraîchir la liste des produits si nécessaire
      if (Get.isRegistered<GetxController>(tag: 'ProductController')) {
        Get.find<GetxController>(tag: 'ProductController').update();
      }
    } catch (e) {
      importStatus.value = 'products_erreur'.trParams({'e': '${e}'});
      SnackbarHelper.error('products_erreur_lors_import'.trParams({'e': '${e}'}));
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
      exportStatus.value = 'products_generation_template'.tr;

      String? filePath = await _excelService.generateImportTemplate();

      if (filePath != null) {
        exportStatus.value = 'customers_template_success'.tr;
        await _excelService.shareExcelFile(filePath);

        SnackbarHelper.success('products_template_import_genere_partage'.tr);
      } else {
        SnackbarHelper.error('products_impossible_generer_template'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('products_erreur_lors_generation_template'.trParams({'e': '${e}'}));
    }
  }

  /// Supprime un produit de l'aperçu d'import
  void removeFromImportPreview(int index) {
    if (index >= 0 && index < importPreview.length) {
      importPreview.removeAt(index);
      importStatus.value = 'products_produits_prets_importer'.trParams({'length': '${importPreview.length}'});
    }
  }

  /// Modifie un produit dans l'aperçu d'import
  void updateImportPreview(int index, ProductForm product) {
    if (index >= 0 && index < importPreview.length) {
      importPreview[index] = product;
    }
  }
}
