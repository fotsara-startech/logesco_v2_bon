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
        return 'Rechercher un produit (nom, référence, code-barre)...';
      case 1:
        return 'Rechercher dans les alertes...';
      case 2:
        return 'Rechercher dans les mouvements...';
      default:
        return 'Rechercher...';
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
            tooltip: 'Options de recherche',
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
            const Text(
              'Options de recherche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Recherche par référence exacte
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Recherche par référence exacte'),
              subtitle: const Text('Rechercher une référence précise'),
              onTap: () {
                Get.back();
                _showReferenceSearch();
              },
            ),

            // Recherche par code-barre
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Recherche par code-barre'),
              subtitle: const Text('Scanner ou saisir un code-barre'),
              onTap: () {
                Get.back();
                _showBarcodeSearch();
              },
            ),

            // Filtre par catégorie
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filtrer par catégorie'),
              subtitle: const Text('Afficher seulement une catégorie'),
              onTap: () {
                Get.back();
                _showCategoryFilter();
              },
            ),

            // Filtre par statut de stock
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Filtrer par statut de stock'),
              subtitle: const Text('Stocks en alerte, rupture, etc.'),
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
                      label: const Text('Effacer tous les filtres'),
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
        title: const Text('Recherche par référence'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Référence exacte',
            hintText: 'Ex: REF001',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateSearchQuery(textController.text.trim());
              Get.back();
            },
            child: const Text('Rechercher'),
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
        title: const Text('Recherche par code-barre'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Code-barre',
            hintText: 'Scanner ou saisir le code-barre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                controller.updateSearchQuery(barcode);
                Get.back();
              }
            },
            child: const Text('Rechercher'),
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
        title: const Text('Filtrer par statut de stock'),
        content: Obx(() => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Tous les stocks'),
                    leading: Radio<String>(
                      value: '',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Stocks en alerte'),
                    leading: Radio<String>(
                      value: 'alerte',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Stocks en rupture'),
                    leading: Radio<String>(
                      value: 'rupture',
                      groupValue: controller.stockStatusFilter.value,
                      onChanged: (value) => controller.updateStockStatusFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Stocks disponibles'),
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
            child: const Text('Fermer'),
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
        title: const Text('Filtrer par type de mouvement'),
        content: Obx(() => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Tous les mouvements'),
                    leading: Radio<String>(
                      value: '',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Achats'),
                    leading: Radio<String>(
                      value: 'achat',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Ventes'),
                    leading: Radio<String>(
                      value: 'vente',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Ajustements'),
                    leading: Radio<String>(
                      value: 'ajustement',
                      groupValue: controller.movementTypeFilter.value ?? '',
                      onChanged: (value) => controller.updateMovementTypeFilter(value ?? ''),
                    ),
                  ),
                  ListTile(
                    title: const Text('Retours'),
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
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
