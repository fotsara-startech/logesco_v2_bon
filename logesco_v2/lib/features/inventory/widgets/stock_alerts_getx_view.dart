import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';

/// Vue des alertes de stock utilisant GetX
class StockAlertsGetxView extends GetView<InventoryGetxController> {
  const StockAlertsGetxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingAlerts.value && controller.stockAlerts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.alertsError.value.isNotEmpty && controller.stockAlerts.isEmpty) {
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
                'Erreur: ${controller.alertsError.value}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadStockAlerts(refresh: true),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }

      if (controller.stockAlerts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                'Aucune alerte de stock',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Tous les produits ont un stock suffisant',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadStockAlerts(refresh: true),
        child: ListView.builder(
          itemCount: controller.stockAlerts.length + (controller.hasMoreAlerts.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Indicateur de chargement pour pagination
            if (index == controller.stockAlerts.length) {
              return Obx(() => controller.isLoadingAlerts.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink());
            }

            final stock = controller.stockAlerts[index];
            return _buildAlertItem(stock);
          },
        ),
      );
    });
  }

  Widget _buildAlertItem(Stock stock) {
    final product = stock.produit;
    final isOutOfStock = stock.quantiteDisponible == 0;
    final seuilMinimum = product?.seuilStockMinimum ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutOfStock ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          child: Icon(
            isOutOfStock ? Icons.error : Icons.warning,
            color: isOutOfStock ? Colors.red : Colors.orange,
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
            Text('Stock actuel: ${stock.quantiteDisponible}'),
            Text('Seuil minimum: $seuilMinimum'),
            Text(
              isOutOfStock ? 'RUPTURE DE STOCK' : 'STOCK FAIBLE',
              style: TextStyle(
                color: isOutOfStock ? Colors.red[700] : Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                // TODO: Naviguer vers commande d'approvisionnement
                Get.snackbar(
                  'Info',
                  'Fonction d\'approvisionnement à venir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              tooltip: 'Commander',
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => controller.goToStockMovement(stock),
              tooltip: 'Mouvement de stock',
            ),
          ],
        ),
        onTap: () => controller.goToStockDetail(stock),
      ),
    );
  }
}
