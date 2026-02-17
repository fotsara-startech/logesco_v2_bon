import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_inventory_controller.dart';

/// Barre de tri pour les inventaires
class InventoriesSortBar extends StatelessWidget {
  const InventoriesSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockInventoryController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Trier par:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            _buildSortButton(
              context: context,
              controller: controller,
              sortField: 'nom',
              label: 'Nom',
            ),
            const SizedBox(width: 8),
            _buildSortButton(
              context: context,
              controller: controller,
              sortField: 'date',
              label: 'Date',
            ),
            const SizedBox(width: 8),
            _buildSortButton(
              context: context,
              controller: controller,
              sortField: 'statut',
              label: 'Statut',
            ),
            const SizedBox(width: 12),
            // Bouton pour basculer l'ordre
            Obx(() => Tooltip(
                  message: controller.sortAscending.value ? 'Ordre croissant' : 'Ordre décroissant',
                  child: GestureDetector(
                    onTap: controller.toggleInventoriesSort,
                    child: Icon(
                      controller.sortAscending.value ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Construit un bouton de tri
  Widget _buildSortButton({
    required BuildContext context,
    required StockInventoryController controller,
    required String sortField,
    required String label,
  }) {
    return Obx(() {
      final isActive = controller.sortBy.value == sortField;
      return GestureDetector(
        onTap: () => controller.setInventoriesSortBy(sortField),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey.shade700,
                ),
              ),
              if (isActive) const SizedBox(width: 4),
              if (isActive)
                Icon(
                  controller.sortAscending.value ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      );
    });
  }
}
