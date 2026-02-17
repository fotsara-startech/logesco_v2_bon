import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_inventory_controller.dart';
import '../models/inventory_model.dart';

/// Vue de détail d'inventaire
class InventoryDetailView extends StatelessWidget {
  const InventoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final StockInventoryController controller = Get.find<StockInventoryController>();
    final String? inventoryIdStr = Get.parameters['id'];

    if (inventoryIdStr == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('ID d\'inventaire manquant')),
      );
    }

    final int inventoryId = int.tryParse(inventoryIdStr) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Inventaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInventories(),
          ),
        ],
      ),
      body: Obx(() {
        final inventory = controller.inventories.firstWhereOrNull(
          (inv) => inv.id == inventoryId,
        );

        if (inventory == null) {
          return const Center(
            child: Text('Inventaire non trouvé'),
          );
        }

        return _buildInventoryDetail(inventory, controller);
      }),
    );
  }

  Widget _buildInventoryDetail(StockInventory inventory, StockInventoryController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(inventory),
          const SizedBox(height: 16),
          _buildStatsCard(inventory),
          const SizedBox(height: 16),
          _buildActionsCard(inventory, controller),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(StockInventory inventory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inventory.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                    ),
                  ),
                ),
              ],
            ),
            if (inventory.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                inventory.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoRow('Type', inventory.type.displayName),
            if (inventory.nomCategorie != null) _buildInfoRow('Catégorie', inventory.nomCategorie!),
            _buildInfoRow('Créé par', inventory.nomUtilisateur),
            _buildInfoRow('Date de création', _formatDate(inventory.dateCreation)),
            if (inventory.dateDebut != null) _buildInfoRow('Date de début', _formatDate(inventory.dateDebut!)),
            if (inventory.dateFin != null) _buildInfoRow('Date de fin', _formatDate(inventory.dateFin!)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(StockInventory inventory) {
    if (inventory.stats == null) {
      return const SizedBox.shrink();
    }

    final stats = inventory.stats!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Articles',
                    '${stats.countedItems}/${stats.totalItems}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Écarts',
                    '${stats.itemsWithVariance}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.progressPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.progressPercentage == 100 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progression: ${stats.progressPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(StockInventory inventory, StockInventoryController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inventory.status == InventoryStatus.BROUILLON)
                  ElevatedButton.icon(
                    onPressed: () => controller.startInventory(inventory.id!),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (inventory.status == InventoryStatus.EN_COURS) ...[
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCount(inventory),
                    icon: const Icon(Icons.edit),
                    label: const Text('Continuer le comptage'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.finishInventory(inventory.id!),
                    icon: const Icon(Icons.check),
                    label: const Text('Terminer'),
                  ),
                ],
                if (inventory.status == InventoryStatus.TERMINE) ...[
                  ElevatedButton.icon(
                    onPressed: () => controller.printCountingSheet(inventory.id!),
                    icon: const Icon(Icons.print),
                    label: const Text('Feuille comptage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => controller.printInventoryReport(inventory.id!),
                    icon: const Icon(Icons.assessment),
                    label: const Text('Rapport complet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.closeInventory(inventory.id!),
                    icon: const Icon(Icons.lock),
                    label: const Text('Clôturer'),
                  ),
                ],
                if (inventory.canBeModified)
                  OutlinedButton.icon(
                    onPressed: () => _editInventory(inventory),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                if (inventory.status == InventoryStatus.BROUILLON)
                  OutlinedButton.icon(
                    onPressed: () => controller.confirmDeleteInventory(inventory),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToCount(StockInventory inventory) {
    Get.toNamed('/stock-inventory/${inventory.id}/count');
  }

  void _editInventory(StockInventory inventory) {
    // TODO: Implémenter l'édition d'inventaire
    Get.snackbar(
      'Info',
      'Édition d\'inventaire - En cours de développement',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
