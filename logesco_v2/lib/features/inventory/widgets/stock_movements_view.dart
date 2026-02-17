import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../models/stock_model.dart';

class StockMovementsView extends StatefulWidget {
  const StockMovementsView({Key? key}) : super(key: key);

  @override
  State<StockMovementsView> createState() => _StockMovementsViewState();
}

class _StockMovementsViewState extends State<StockMovementsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Charger les mouvements au premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<InventoryController>();
      controller.loadMovements(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Charger plus de données quand on approche de la fin
      final controller = Get.find<InventoryController>();
      controller.loadMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<InventoryController>(
      builder: (controller) {
        if (controller.isLoadingMovements && controller.movements.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.movementsError != null && controller.movements.isEmpty) {
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
                  'Erreur: ${controller.movementsError}',
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
                  'Aucun mouvement trouvé',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Aucun mouvement de stock enregistré',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadMovements(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: controller.movements.length + (controller.hasMoreMovements ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.movements.length) {
                // Indicateur de chargement en bas de liste
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final movement = controller.movements[index];
              return StockMovementItem(movement: movement);
            },
          ),
        );
      },
    );
  }
}

class StockMovementItem extends StatelessWidget {
  final StockMovement movement;

  const StockMovementItem({
    Key? key,
    required this.movement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = movement.produit;
    final isPositive = movement.changementQuantite > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMovementColor(movement.typeMouvement),
          child: Icon(
            _getMovementIcon(movement.typeMouvement),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          product?.nom ?? 'Produit inconnu',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product?.reference != null)
              Text(
                'Réf: ${product!.reference}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(movement.dateMouvement),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.category,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getMovementTypeLabel(movement.typeMouvement),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (movement.notes != null && movement.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      movement.notes!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${movement.changementQuantite}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getTimeAgo(movement.dateMouvement),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMovementColor(String type) {
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
      default:
        return Colors.grey;
    }
  }

  IconData _getMovementIcon(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
      case 'approvisionnement':
        return Icons.add_shopping_cart;
      case 'vente':
        return Icons.shopping_bag;
      case 'ajustement':
        return Icons.tune;
      case 'retour':
        return Icons.undo;
      default:
        return Icons.swap_horiz;
    }
  }

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final movementDate = DateTime(date.year, date.month, date.day);

    if (movementDate == today) {
      return 'Aujourd\'hui ${_formatTime(date)}';
    } else if (movementDate == yesterday) {
      return 'Hier ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}
