import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

/// Barre de recherche pour les produits
class ProductSearchBar extends StatelessWidget {
  const ProductSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'product_search_placeholder'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        onPressed: () => controller.updateSearchQuery(''),
                        icon: const Icon(Icons.clear),
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _showSearchOptions,
            icon: const Icon(Icons.tune),
            tooltip: 'product_search_options'.tr,
          ),
        ],
      ),
    );
  }

  /// Affiche les options de recherche avancée
  void _showSearchOptions() {
    final controller = Get.find<ProductController>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product_search_options'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Recherche par référence exacte
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text('product_search_by_reference'.tr),
              subtitle: Text('product_search_by_reference_subtitle'.tr),
              onTap: () {
                Get.back();
                _showReferenceSearch();
              },
            ),

            // Recherche par code-barre
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('product_search_by_barcode'.tr),
              subtitle: Text('product_search_by_barcode_subtitle'.tr),
              onTap: () {
                Get.back();
                _showBarcodeSearch();
              },
            ),

            // Recherche par catégorie
            ListTile(
              leading: const Icon(Icons.category),
              title: Text('product_search_by_category'.tr),
              subtitle: Text('product_search_by_category_subtitle'.tr),
              onTap: () {
                Get.back();
                _showCategoryFilter();
              },
            ),

            // Recherche par prix
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('product_search_by_price'.tr),
              subtitle: Text('product_search_by_price_subtitle'.tr),
              onTap: () {
                Get.back();
                _showPriceFilter();
              },
            ),

            const SizedBox(height: 10),

            // Bouton effacer filtres
            Obx(() => controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controller.clearFilters();
                        Get.back();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: Text('product_search_clear_all'.tr),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  /// Affiche la recherche par référence
  void _showReferenceSearch() {
    final controller = Get.find<ProductController>();
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('product_search_reference_title'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'product_search_reference_label'.tr,
            hintText: 'product_search_reference_hint'.tr,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('product_search_reference_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateSearchQuery(textController.text.trim());
              Get.back();
            },
            child: Text('product_search_reference_button'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche le filtre par catégorie
  void _showCategoryFilter() {
    final controller = Get.find<ProductController>();

    Get.dialog(
      AlertDialog(
        title: Text('product_search_category_title'.tr),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Option "Toutes les catégories"
                  ListTile(
                    title: Text('product_search_category_all'.tr),
                    leading: Radio<String>(
                      value: '',
                      groupValue: controller.selectedCategory.value,
                      onChanged: (value) => controller.updateSelectedCategory(value ?? ''),
                    ),
                  ),
                  const Divider(height: 1),

                  // Liste scrollable des catégories
                  Flexible(
                    child: controller.categories.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'product_search_category_empty'.tr,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.categories.length,
                            itemBuilder: (context, index) {
                              final category = controller.categories[index];
                              return ListTile(
                                title: Text(category),
                                leading: Radio<String>(
                                  value: category,
                                  groupValue: controller.selectedCategory.value,
                                  onChanged: (value) => controller.updateSelectedCategory(value ?? ''),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('product_search_category_close'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche la recherche par code-barre
  void _showBarcodeSearch() {
    final controller = Get.find<ProductController>();
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('product_search_barcode_title'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'product_search_barcode_label'.tr,
            hintText: 'product_search_barcode_hint'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('product_search_reference_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                Get.back();
                await _searchByBarcode(barcode);
              }
            },
            child: Text('product_search_reference_button'.tr),
          ),
        ],
      ),
    );
  }

  /// Effectue une recherche spécifique par code-barres
  Future<void> _searchByBarcode(String barcode) async {
    final controller = Get.find<ProductController>();

    try {
      // Utiliser la méthode spécialisée de recherche par code-barres
      final product = await controller.searchByBarcode(barcode);

      if (product != null) {
        // Produit trouvé, l'afficher dans la liste
        controller.setSearchResults([product]);
        Get.snackbar(
          'product_search_barcode_found'.tr,
          'product_search_barcode_found_message'.tr.replaceAll('@name', product.nom).replaceAll('@barcode', barcode),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Aucun produit trouvé
        controller.setSearchResults([]);
        Get.snackbar(
          'product_search_barcode_not_found'.tr,
          'product_search_barcode_not_found_message'.tr.replaceAll('@barcode', barcode),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'product_search_barcode_error'.tr,
        'product_search_barcode_error_message'.tr.replaceAll('@error', e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Affiche le filtre par prix
  void _showPriceFilter() {
    Get.snackbar(
      'product_search_price_feature'.tr,
      'product_search_price_feature_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
