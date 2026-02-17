import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';

/// Vue de liste des stocks utilisant GetX
class StockListGetxView extends StatefulWidget {
  const StockListGetxView({super.key});

  @override
  State<StockListGetxView> createState() => _StockListViewState();
}

class _StockListViewState extends State<StockListGetxView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return Obx(() {
      print('=== 📋 WIDGET RECONSTRUIT ===');
      print('   - Stocks chargés: ${controller.stocks.length}');
      print('   - isLoading: ${controller.isLoading.value}');
      print('   - Erreur: ${controller.stocksError.value.isEmpty ? 'Aucune' : controller.stocksError.value}');
      print('===========================');

      if (controller.isLoading.value && controller.stocks.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.stocksError.value.isNotEmpty && controller.stocks.isEmpty) {
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
                'Erreur: ${controller.stocksError.value}',
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
                Icons.inventory_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Aucun stock disponible',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Les stocks apparaîtront ici une fois ajoutés',
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
          itemCount: controller.stocks.length,
          itemBuilder: (context, index) {
            final stock = controller.stocks[index];
            return _buildStockItem(stock, controller);
          },
        ),
      );
    });
  }

  Widget _buildStockItem(Stock stock, InventoryGetxController controller) {
    final product = stock.produit;
    final isLowStock = stock.stockFaible ?? false;
    final isOutOfStock = stock.quantiteDisponible == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutOfStock
              ? Colors.red.withOpacity(0.1)
              : isLowStock
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
          child: Icon(
            Icons.inventory_2,
            color: isOutOfStock
                ? Colors.red
                : isLowStock
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
        title: Text(
          product?.nom ?? 'Produit ${stock.produitId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product?.reference != null) Text('Réf: ${product!.reference}'),
            Text('Disponible: ${stock.quantiteDisponible}'),
            if (stock.quantiteReservee > 0) Text('Réservé: ${stock.quantiteReservee}'),
            if (isLowStock)
              Text(
                'Stock faible',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isOutOfStock)
              Text(
                'Rupture de stock',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'detail':
                controller.goToStockDetail(stock);
                break;
              case 'movement':
                controller.goToStockMovement(stock);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detail',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('Détails'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'movement',
              child: ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('Mouvement de stock'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => controller.goToStockDetail(stock),
      ),
    );
  }
}
