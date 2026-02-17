import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

/// Barre de filtres pour les produits
class ProductFilterBar extends StatelessWidget {
  const ProductFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    return Obx(() {
      // N'afficher la barre que si des filtres sont actifs
      final hasActiveFilters = controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty;

      if (!hasActiveFilters) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.blue.shade100),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtres actifs:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.clearFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Effacer tout',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Filtre de recherche
                if (controller.searchQuery.value.isNotEmpty)
                  _buildFilterChip(
                    label: 'Recherche: "${controller.searchQuery.value}"',
                    onRemove: () => controller.updateSearchQuery(''),
                  ),

                // Filtre de catégorie
                if (controller.selectedCategory.value.isNotEmpty)
                  _buildFilterChip(
                    label: 'Catégorie: ${controller.selectedCategory.value}',
                    onRemove: () => controller.updateSelectedCategory(''),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Construit un chip de filtre
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
