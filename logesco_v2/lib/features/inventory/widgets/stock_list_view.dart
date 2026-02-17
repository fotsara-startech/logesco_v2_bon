import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../models/stock_model.dart';
import '../views/stock_detail_page.dart';

class StockListView extends StatefulWidget {
  const StockListView({Key? key}) : super(key: key);

  @override
  State<StockListView> createState() => _StockListViewState();
}

class _StockListViewState extends State<StockListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Charger plus de données quand on approche de la fin
      Get.find<InventoryController>().loadStocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<InventoryController>(
      builder: (controller) {
        if (controller.isLoading && controller.stocks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null && controller.stocks.isEmpty) {
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
                  'Erreur: ${controller.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadStocks(refresh: true),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (controller.stocks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun stock trouvé',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Aucun produit ne correspond aux critères',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadStocks(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: controller.stocks.length + (controller.hasMoreStocks ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.stocks.length) {
                // Indicateur de chargement en bas de liste
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final stock = controller.stocks[index];
              return StockListItem(
                stock: stock,
                onTap: () => _navigateToStockDetail(stock),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToStockDetail(Stock stock) {
    Get.to(() => StockDetailPage(stock: stock));
  }
}

class StockListItem extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const StockListItem({
    Key? key,
    required this.stock,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = stock.produit;
    final isLowStock = stock.stockFaible ?? false;
    final isOutOfStock = stock.quantiteDisponible == 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(isOutOfStock, isLowStock),
          child: Icon(
            _getStatusIcon(isOutOfStock, isLowStock),
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
                  Icons.inventory,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Disponible: ${stock.quantiteDisponible}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (stock.quantiteReservee > 0) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Réservé: ${stock.quantiteReservee}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusChip(isOutOfStock, isLowStock),
            const SizedBox(height: 4),
            if (product?.seuilStockMinimum != null)
              Text(
                'Seuil: ${product!.seuilStockMinimum}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) return Icons.error;
    if (isLowStock) return Icons.warning;
    return Icons.check_circle;
  }

  Widget _buildStatusChip(bool isOutOfStock, bool isLowStock) {
    String label;
    Color color;

    if (isOutOfStock) {
      label = 'Rupture';
      color = Colors.red;
    } else if (isLowStock) {
      label = 'Alerte';
      color = Colors.orange;
    } else {
      label = 'OK';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
