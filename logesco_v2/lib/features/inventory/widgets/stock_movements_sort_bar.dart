import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';

/// Barre de tri pour les mouvements de stock
class StockMovementsSortBar extends StatelessWidget {
  const StockMovementsSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'stock_sort_by'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            _buildSortButton(
              context: context,
              controller: controller,
              sortField: 'dateCreation',
              label: 'stock_sort_date_creation'.tr,
            ),
            const SizedBox(width: 8),
            _buildSortButton(
              context: context,
              controller: controller,
              sortField: 'typeMouvement',
              label: 'stock_sort_type'.tr,
            ),
            const SizedBox(width: 12),
            // Bouton pour basculer l'ordre
            Obx(() => Tooltip(
                  message: controller.sortMovementsAscending.value ? 'stock_sort_ascending'.tr : 'stock_sort_descending'.tr,
                  child: GestureDetector(
                    onTap: controller.toggleMovementsSort,
                    child: Icon(
                      controller.sortMovementsAscending.value ? Icons.arrow_upward : Icons.arrow_downward,
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
    required InventoryGetxController controller,
    required String sortField,
    required String label,
  }) {
    return Obx(() {
      final isActive = controller.sortByMovements.value == sortField;
      return GestureDetector(
        onTap: () => controller.setMovementsSortBy(sortField),
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
                  controller.sortMovementsAscending.value ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
