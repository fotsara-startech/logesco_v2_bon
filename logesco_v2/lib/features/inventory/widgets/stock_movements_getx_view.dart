import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';
import 'movement_filter_dialog.dart';
import 'stock_movements_sort_bar.dart';

/// Vue des mouvements de stock utilisant GetX
class StockMovementsGetxView extends GetView<InventoryGetxController> {
  const StockMovementsGetxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'outils pour les mouvements
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Text(
                'Mouvements de stock',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => Get.dialog(const MovementFilterDialog()),
                tooltip: 'Filtrer les mouvements',
              ),
            ],
          ),
        ),

        // Barre de tri
        const StockMovementsSortBar(),

        // Liste des mouvements
        Expanded(
          child: Obx(() {
            if (controller.isLoadingMovements.value && controller.movements.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.movementsError.value.isNotEmpty && controller.movements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${controller.movementsError.value}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadMovements(refresh: true),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (controller.movements.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucun mouvement de stock',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'L\'historique des mouvements apparaîtra ici',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadMovements(refresh: true),
              child: ListView.builder(
                itemCount: controller.movements.length + (controller.hasMoreMovements.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // Indicateur de chargement pour pagination
                  if (index == controller.movements.length) {
                    return Obx(() => controller.isLoadingMovements.value
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink());
                  }

                  final movement = controller.movements[index];
                  return _buildMovementItem(movement);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMovementItem(StockMovement movement) {
    final isPositive = movement.changementQuantite > 0;
    final typeColor = _getTypeColor(movement.typeMouvement);

    // Calculer le stock initial et final
    final stockActuel = movement.produit?.stockActuel ?? 0;
    final stockInitial = stockActuel - movement.changementQuantite;
    final stockFinal = stockActuel;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.1),
          child: Icon(
            _getTypeIcon(movement.typeMouvement),
            color: typeColor,
          ),
        ),
        title: Text(
          movement.produit?.nom ?? 'Produit ${movement.produitId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movement.produit?.reference != null) Text('Réf: ${movement.produit!.reference}'),
            Text('Type: ${_getTypeLabel(movement.typeMouvement)}'),
            Text('Date: ${_formatDate(movement.dateMouvement)}'),
            const SizedBox(height: 4),
            // Affichage du stock initial → changement → stock final
            Row(
              children: [
                Text(
                  'Stock: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$stockInitial',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: Colors.grey[500],
                ),
                Text(
                  '${isPositive ? '+' : ''}${movement.changementQuantite}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: Colors.grey[500],
                ),
                Text(
                  '$stockFinal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (movement.notes != null && movement.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Notes: ${movement.notes}'),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${movement.changementQuantite}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            Text(
              'Qté: ${movement.changementQuantite.abs()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
      case 'approvisionnement':
        return Colors.green;
      case 'vente':
        return Colors.blue;
      case 'ajustement':
        return Colors.orange;
      case 'retour':
        return Colors.purple;
      case 'perte':
      case 'casse':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
      case 'approvisionnement':
        return Icons.add_shopping_cart;
      case 'vente':
        return Icons.point_of_sale;
      case 'ajustement':
        return Icons.tune;
      case 'retour':
        return Icons.keyboard_return;
      case 'perte':
      case 'casse':
        return Icons.error;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
        return 'Achat';
      case 'approvisionnement':
        return 'Approvisionnement';
      case 'vente':
        return 'Vente';
      case 'ajustement':
        return 'Ajustement';
      case 'retour':
        return 'Retour';
      case 'perte':
        return 'Perte';
      case 'casse':
        return 'Casse';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
