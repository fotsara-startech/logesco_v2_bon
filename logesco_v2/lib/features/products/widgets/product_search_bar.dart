import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
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
            Obx(() => controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty || controller.hasPriceFilter
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
      _CategoryFilterDialog(controller: controller),
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
        SnackbarHelper.success('product_search_barcode_found_message'.tr.replaceAll('@name', product.nom).replaceAll('@barcode', barcode), title: 'product_search_barcode_found'.tr);
      } else {
        // Aucun produit trouvé
        controller.setSearchResults([]);
        SnackbarHelper.warning('product_search_barcode_not_found_message'.tr.replaceAll('@barcode', barcode), title: 'product_search_barcode_not_found'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('product_search_barcode_error_message'.tr.replaceAll('@error', e.toString()), title: 'product_search_barcode_error'.tr);
    }
  }

  /// Affiche le filtre par prix
  void _showPriceFilter() {
    final controller = Get.find<ProductController>();
    Get.dialog(_PriceFilterDialog(controller: controller));
  }
}

/// Dialog de filtre par catégorie avec barre de recherche intégrée
class _CategoryFilterDialog extends StatefulWidget {
  final ProductController controller;
  const _CategoryFilterDialog({required this.controller});

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtered = [];
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.selectedCategory.value;
    _filtered = widget.controller.categories.toList();
    _searchCtrl.addListener(_onSearch);
  }

  void _select(String value) {
    setState(() => _selected = value);
    widget.controller.updateSelectedCategory(value);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? widget.controller.categories.toList() : widget.controller.categories.where((c) => c.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('product_search_category_title'.tr),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              title: Text('product_search_category_all'.tr),
              leading: Radio<String>(
                value: '',
                groupValue: _selected,
                onChanged: (v) => _select(v ?? ''),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(child: Text('product_search_category_empty'.tr, style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final cat = _filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(cat),
                          leading: Radio<String>(
                            value: cat,
                            groupValue: _selected,
                            onChanged: (v) => _select(v ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('product_search_category_close'.tr),
        ),
      ],
    );
  }
}

/// Dialog de filtre par fourchette de prix
class _PriceFilterDialog extends StatefulWidget {
  final ProductController controller;
  const _PriceFilterDialog({required this.controller});

  @override
  State<_PriceFilterDialog> createState() => _PriceFilterDialogState();
}

class _PriceFilterDialogState extends State<_PriceFilterDialog> {
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.minPrice.value != null) {
      _minCtrl.text = widget.controller.minPrice.value!.toStringAsFixed(0);
    }
    if (widget.controller.maxPrice.value != null) {
      _maxCtrl.text = widget.controller.maxPrice.value!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.trim());
    final max = double.tryParse(_maxCtrl.text.trim());
    widget.controller.setPriceFilter(min: min, max: max);
    Get.back();
  }

  void _clear() {
    widget.controller.setPriceFilter(min: null, max: null);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('product_search_by_price'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Prix minimum (FCFA)',
              hintText: 'Ex: 1000',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.arrow_downward, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Prix maximum (FCFA)',
              hintText: 'Ex: 50000',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.arrow_upward, size: 18),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.controller.hasPriceFilter)
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Effacer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        TextButton(
          onPressed: () => Get.back(),
          child: Text('product_search_reference_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: Text('product_search_reference_button'.tr),
        ),
      ],
    );
  }
}
