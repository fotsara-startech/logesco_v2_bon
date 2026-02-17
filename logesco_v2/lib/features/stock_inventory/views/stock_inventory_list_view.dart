import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_inventory_controller.dart';
import '../models/inventory_model.dart';
import 'inventory_form_view.dart';
import '../widgets/inventories_sort_bar.dart';

/// Vue de la liste des inventaires
class StockInventoryListView extends StatelessWidget {
  const StockInventoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final StockInventoryController controller = Get.put(StockInventoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire de Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInventories(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersSection(controller),

          // Barre de tri
          const InventoriesSortBar(),

          // Liste des inventaires
          Expanded(
            child: _buildInventoryList(controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInventoryDialog(controller),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Inventaire'),
      ),
    );
  }

  Widget _buildFiltersSection(StockInventoryController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => controller.updateSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Rechercher un inventaire...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<InventoryStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                  ),
                  items: InventoryStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // TODO: Implémenter le filtrage par statut
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<InventoryType>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: InventoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // TODO: Implémenter le filtrage par type
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(StockInventoryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final inventories = controller.filteredInventories;

      if (inventories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun inventaire trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre premier inventaire pour commencer',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inventories.length,
        itemBuilder: (context, index) {
          final inventory = inventories[index];
          return _buildInventoryCard(inventory, controller);
        },
      );
    });
  }

  Widget _buildInventoryCard(StockInventory inventory, StockInventoryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventory.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (inventory.description != null && inventory.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          inventory.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(inventory.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inventory.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(inventory.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  label: inventory.type.displayName,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                if (inventory.nomCategorie != null)
                  _buildInfoChip(
                    icon: Icons.folder,
                    label: inventory.nomCategorie!,
                    color: Colors.purple,
                  ),
                const Spacer(),
                Text(
                  'Par ${inventory.nomUtilisateur ?? 'Utilisateur'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (inventory.stats != null) ...[
              const SizedBox(height: 12),
              _buildProgressSection(inventory),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewInventoryDetails(inventory, controller),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir'),
                  ),
                ),
                const SizedBox(width: 8),
                if (inventory.canBeModified)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _continueInventory(inventory, controller),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Continuer'),
                    ),
                  ),
                if (inventory.status == InventoryStatus.TERMINE)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printInventory(inventory, controller),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(StockInventory inventory) {
    final stats = inventory.stats!;
    final progress = stats.progressPercentage / 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression: ${stats.countedItems}/${stats.totalItems} articles',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${stats.progressPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : Colors.blue,
          ),
        ),
        if (stats.itemsWithVariance > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: Colors.orange.shade600),
              const SizedBox(width: 4),
              Text(
                '${stats.itemsWithVariance} écart(s) détecté(s)',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.BROUILLON:
        return Colors.grey;
      case InventoryStatus.EN_COURS:
        return Colors.blue;
      case InventoryStatus.TERMINE:
        return Colors.green;
      case InventoryStatus.CLOTURE:
        return Colors.purple;
    }
  }

  void _showCreateInventoryDialog(StockInventoryController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Nouvel Inventaire'),
        content: const Text('Choisissez le type d\'inventaire à créer:'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            onPressed: () {
              Get.back();
              _createInventory(InventoryType.PARTIEL, controller);
            },
            child: const Text('Inventaire Partiel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _createInventory(InventoryType.TOTAL, controller);
            },
            child: const Text('Inventaire Total'),
          ),
        ],
      ),
    );
  }

  void _createInventory(InventoryType type, StockInventoryController controller) {
    controller.selectInventory(null);
    Get.to(() => const InventoryFormView(), arguments: {'type': type});
  }

  void _viewInventoryDetails(StockInventory inventory, StockInventoryController controller) {
    controller.selectInventory(inventory);
    Get.toNamed('/stock-inventory/${inventory.id}');
  }

  void _continueInventory(StockInventory inventory, StockInventoryController controller) {
    controller.selectInventory(inventory);
    Get.toNamed('/stock-inventory/${inventory.id}/count');
  }

  void _printInventory(StockInventory inventory, StockInventoryController controller) {
    controller.printCountingSheet(inventory.id!);
  }
}
