import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';
import '../../../core/widgets/product_image_preview.dart';

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
      print('=== ');
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
                '${'error'.tr}: ${controller.stocksError.value}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadStocks(refresh: true),
                child: Text('stock_error_retry'.tr),
              ),
            ],
          ),
        );
      }

      if (controller.filteredStocks.isEmpty) {
        return Center(
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
                controller.stockStatusFilter.value.isNotEmpty ? 'Aucun produit pour ce filtre' : 'stock_no_stocks'.tr,
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'stock_stock_will_appear'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadStocks(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: controller.filteredStocks.length,
          itemBuilder: (context, index) {
            final stock = controller.filteredStocks[index];
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
        leading: Stack(
          children: [
            ProductImageThumbnail(
              imageUrl: product?.imageUrl,
              size: 48,
              productName: product?.nom ?? '',
            ),
            // Indicateur de statut stock (coin bas-gauche)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.red
                      : isLowStock
                          ? Colors.orange
                          : Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          product?.nom ?? 'Produit ${stock.produitId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product?.reference != null) Text('${'stock_stock_ref'.tr} ${product!.reference}'),
            Text('${'stock_stock_available'.tr} ${stock.quantiteDisponible}'),
            if (stock.quantiteReservee > 0) Text('${'stock_stock_reserved'.tr} ${stock.quantiteReservee}'),
            if (isLowStock)
              Text(
                'stock_stock_low'.tr,
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isOutOfStock)
              Text(
                'stock_stock_rupture_status'.tr,
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
            PopupMenuItem(
              value: 'detail',
              child: ListTile(
                leading: const Icon(Icons.info),
                title: Text('stock_stock_details'.tr),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'movement',
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text('stock_movement_title'.tr),
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
