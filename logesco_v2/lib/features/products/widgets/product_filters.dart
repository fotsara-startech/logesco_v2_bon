import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import 'category_selector.dart';

/// Widget de filtres pour les produits
class ProductFilters extends GetView<ProductController> {
  const ProductFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtres',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Barre de recherche
          TextField(
            onChanged: controller.updateSearchQuery,
            decoration: const InputDecoration(
              labelText: 'Rechercher un produit',
              hintText: 'Nom, référence, code-barre...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Sélecteur de catégorie
          const CategorySelector(),

          const SizedBox(height: 16),

          // Filtres actifs
          Obx(() {
            final hasFilters = controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty;

            if (!hasFilters) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtres actifs:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (controller.searchQuery.value.isNotEmpty)
                      Chip(
                        label: Text('Recherche: "${controller.searchQuery.value}"'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => controller.updateSearchQuery(''),
                      ),
                    const CategoryChip(),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: controller.clearFilters,
                  child: const Text('Effacer tous les filtres'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Bottom sheet pour les filtres de produits
class ProductFiltersBottomSheet extends StatelessWidget {
  const ProductFiltersBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const ProductFilters(),
    );
  }

  static void show() {
    Get.bottomSheet(
      const ProductFiltersBottomSheet(),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
    );
  }
}
