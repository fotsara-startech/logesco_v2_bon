import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';

/// Barre de filtres pour l'inventaire
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return Obx(() {
      // N'afficher la barre que si des filtres sont actifs
      if (!controller.hasActiveFilters) {
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
                  onPressed: controller.clearAllFilters,
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

                // Filtre de statut de stock
                if (controller.stockStatusFilter.value.isNotEmpty)
                  _buildFilterChip(
                    label: 'Statut: ${_getStatusLabel(controller.stockStatusFilter.value)}',
                    onRemove: () => controller.updateStockStatusFilter(''),
                  ),

                // Filtre de type de mouvement
                if (controller.movementTypeFilter.value != null && controller.movementTypeFilter.value!.isNotEmpty)
                  _buildFilterChip(
                    label: 'Type: ${_getMovementTypeLabel(controller.movementTypeFilter.value!)}',
                    onRemove: () => controller.movementTypeFilter.value = null,
                  ),

                // Filtre de date
                if (controller.dateDebutFilter.value != null || controller.dateFinFilter.value != null)
                  _buildFilterChip(
                    label: 'Période: ${_getDateRangeLabel(controller.dateDebutFilter.value, controller.dateFinFilter.value)}',
                    onRemove: () {
                      controller.dateDebutFilter.value = null;
                      controller.dateFinFilter.value = null;
                      controller.loadMovements(refresh: true);
                    },
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

  /// Obtient le libellé du statut de stock
  String _getStatusLabel(String status) {
    switch (status) {
      case 'alerte':
        return 'En alerte';
      case 'rupture':
        return 'En rupture';
      case 'disponible':
        return 'Disponible';
      default:
        return status;
    }
  }

  /// Obtient le libellé du type de mouvement
  String _getMovementTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
        return 'Achat';
      case 'vente':
        return 'Vente';
      case 'ajustement':
        return 'Ajustement';
      case 'retour':
        return 'Retour';
      case 'approvisionnement':
        return 'Approvisionnement';
      default:
        return type;
    }
  }

  /// Obtient le libellé de la plage de dates
  String _getDateRangeLabel(DateTime? debut, DateTime? fin) {
    if (debut != null && fin != null) {
      return '${_formatDate(debut)} - ${_formatDate(fin)}';
    } else if (debut != null) {
      return 'Depuis ${_formatDate(debut)}';
    } else if (fin != null) {
      return 'Jusqu\'au ${_formatDate(fin)}';
    }
    return 'Période personnalisée';
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}