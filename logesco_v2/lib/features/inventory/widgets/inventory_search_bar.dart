import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import 'category_filter_dialog.dart';

/// Barre de recherche pour l'inventaire
class InventorySearchBar extends StatefulWidget {
  final int currentTabIndex;

  const InventorySearchBar({
    super.key,
    this.currentTabIndex = 0,
  });

  @override
  State<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends State<InventorySearchBar> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _getPlaceholder {
    switch (widget.currentTabIndex) {
      case 0:
        return 'stock_search_placeholder'.tr;
      case 1:
        return 'stock_search_alerts_placeholder'.tr;
      case 2:
        return 'stock_search_movements_placeholder'.tr;
      default:
        return 'stock_search_placeholder'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    // Synchroniser le TextField avec le contrôleur GetX
    if (_textController.text != controller.searchQuery.value) {
      _textController.text = controller.searchQuery.value;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

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
            child: Obx(() {
              return TextField(
                controller: _textController,
                onChanged: controller.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: _getPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _textController.clear();
                            controller.updateSearchQuery('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
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
              );
            }),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showSearchOptions(widget.currentTabIndex),
            icon: const Icon(Icons.tune),
            tooltip: 'stock_search_options'.tr,
          ),
        ],
      ),
    );
  }

  /// Affiche les options de recherche avancée
  void _showSearchOptions(int tabIndex) {
    final controller = Get.find<InventoryGetxController>();

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
              'stock_search_options'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Recherche par référence exacte
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text('stock_search_exact_reference'.tr),
              subtitle: Text('stock_search_exact_reference_hint'.tr),
              onTap: () {
                Get.back();
                _showReferenceSearch();
              },
            ),

            // Recherche par code-barre
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('stock_search_barcode'.tr),
              subtitle: Text('stock_search_barcode_hint'.tr),
              onTap: () {
                Get.back();
                _showBarcodeSearch();
              },
            ),

            // Filtre par catégorie
            ListTile(
              leading: const Icon(Icons.category),
              title: Text('stock_filter_category'.tr),
              subtitle: Text('stock_filter_category_hint'.tr),
              onTap: () {
                Get.back();
                _showCategoryFilter();
              },
            ),

            // Filtre par statut de stock
            ListTile(
              leading: const Icon(Icons.warning),
              title: Text('stock_filter_status'.tr),
              subtitle: Text('stock_filter_status_hint'.tr),
              onTap: () {
                Get.back();
                _showStockStatusFilter();
              },
            ),

            const SizedBox(height: 10),

            // Bouton effacer filtres
            Obx(() => controller.hasActiveFilters
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controller.clearAllFilters();
                        Get.back();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: Text('stock_filter_clear_all'.tr),
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
    final controller = Get.find<InventoryGetxController>();
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('stock_search_exact_reference'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'stock_filter_category_label'.tr,
            hintText: 'Ex: REF001',
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateSearchQuery(textController.text.trim());
              Get.back();
            },
            child: Text('stock_search_placeholder'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche la recherche par code-barre
  void _showBarcodeSearch() {
    final controller = Get.find<InventoryGetxController>();
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('stock_search_barcode'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'stock_search_barcode'.tr,
            hintText: 'stock_search_barcode_hint'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                controller.updateSearchQuery(barcode);
                Get.back();
              }
            },
            child: Text('stock_search_placeholder'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche le filtre par statut de stock
  void _showStockStatusFilter() {
    final controller = Get.find<InventoryGetxController>();

    Get.dialog(
      AlertDialog(
        title: Text('stock_filter_status'.tr),
        content: Obx(() => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('stock_filter_all'.tr),
                    leading: Radio<String>(
                      value: '',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_alert'.tr),
                    leading: Radio<String>(
                      value: 'alerte',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_rupture'.tr),
                    leading: Radio<String>(
                      value: 'rupture',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_available'.tr),
                    leading: Radio<String>(
                      value: 'disponible',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                ],
              ),
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_close'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche le filtre par catégorie
  void _showCategoryFilter() {
    Get.dialog(const CategoryFilterDialog());
  }

  /// Affiche le filtre par type de mouvement
  void _showMovementTypeFilter() {
    final controller = Get.find<InventoryGetxController>();

    Get.dialog(
      AlertDialog(
        title: Text('stock_filter_movement_type'.tr),
        content: Obx(() => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('stock_filter_all'.tr),
                    leading: Radio<String>(
                      value: '',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_purchase'.tr),
                    leading: Radio<String>(
                      value: 'achat',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_sale'.tr),
                    leading: Radio<String>(
                      value: 'vente',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_adjustment'.tr),
                    leading: Radio<String>(
                      value: 'ajustement',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: Text('stock_filter_return'.tr),
                    leading: Radio<String>(
                      value: 'retour',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                ],
              ),
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_close'.tr),
          ),
        ],
      ),
    );
  }
}
