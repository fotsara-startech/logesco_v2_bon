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
                hintText: 'Rechercher par nom ou référence...',
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
            tooltip: 'Options de recherche',
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

            // Recherche par catégorie
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filtrer par catégorie'),
              subtitle: const Text('Afficher seulement une catégorie'),
              onTap: () {
                Get.back();
                _showCategoryFilter();
              },
            ),

            // Recherche par prix
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Filtrer par prix'),
              subtitle: const Text('Définir une fourchette de prix'),
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
    final controller = Get.find<ProductController>();
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

  /// Affiche le filtre par catégorie
  void _showCategoryFilter() {
    final controller = Get.find<ProductController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Filtrer par catégorie'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Option "Toutes les catégories"
                  ListTile(
                    title: const Text('Toutes les catégories'),
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
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Aucune catégorie disponible',
                              style: TextStyle(color: Colors.grey),
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
            child: const Text('Fermer'),
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
            onPressed: () async {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                Get.back();
                await _searchByBarcode(barcode);
              }
            },
            child: const Text('Rechercher'),
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
          'Produit trouvé',
          'Produit "${product.nom}" trouvé avec le code-barre $barcode',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Aucun produit trouvé
        controller.setSearchResults([]);
        Get.snackbar(
          'Aucun résultat',
          'Aucun produit trouvé avec le code-barre $barcode',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la recherche par code-barre: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Affiche le filtre par prix
  void _showPriceFilter() {
    Get.snackbar(
      'Fonctionnalité',
      'Filtre par prix à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
