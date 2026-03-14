import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import 'inventory_error_widget.dart';

/// Widget de résumé des stocks utilisant GetX
class StockSummaryGetxCard extends GetView<InventoryGetxController> {
  const StockSummaryGetxCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Bouton pour masquer/afficher le résumé
      if (!controller.isSummaryVisible.value) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.visibility, color: Colors.blue),
            title: Text('stock_summary_show'.tr),
            subtitle: Text('stock_summary_show_hint'.tr),
            trailing: const Icon(Icons.expand_more),
            onTap: () => controller.isSummaryVisible.value = true,
          ),
        );
      }

      if (controller.isLoadingSummary.value && controller.summary.value == null) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.summaryError.value.isNotEmpty) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              SizedBox(
                height: 120, // Hauteur fixe pour éviter les changements de layout
                child: InventoryErrorWidget(
                  message: controller.summaryError.value,
                  onRetry: controller.loadSummary,
                  icon: Icons.assessment,
                ),
              ),
            ],
          ),
        );
      }

      final summary = controller.summary.value;
      if (summary == null) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('stock_summary_no_data'.tr),
              ),
            ],
          ),
        );
      }

      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactStatCard(
                      '1',
                      'stock_summary_products'.tr,
                      summary.totalProduits.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                    _buildCompactStatCard(
                      '2',
                      'stock_summary_purchases'.tr,
                      _formatValueCompact(summary.valeurStockAchat),
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                    _buildCompactStatCard(
                      '3',
                      'stock_summary_sales'.tr,
                      _formatValueCompact(summary.valeurStockVente ?? summary.valeurTotaleStock),
                      Icons.sell,
                      Colors.teal,
                    ),
                    _buildCompactStatCard(
                      '4',
                      'stock_summary_alerts'.tr,
                      summary.produitsEnAlerte.toString(),
                      Icons.warning,
                      summary.produitsEnAlerte > 0 ? Colors.orange : Colors.grey,
                    ),
                    _buildCompactStatCard(
                      '5',
                      'stock_summary_ruptures'.tr,
                      summary.produitsEnRupture.toString(),
                      Icons.error,
                      summary.produitsEnRupture > 0 ? Colors.red : Colors.grey,
                    ),
                    _buildCompactStatCard(
                      '6',
                      'stock_summary_in_stock'.tr,
                      '${summary.pourcentageEnStock}%',
                      Icons.check_circle,
                      Colors.indigo,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatValueCompact(double? value) {
    if (value == null) {
      return 'N/A';
    }
    if (value == 0) {
      return '0';
    }
    // Format compact pour les grandes valeurs
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Construit l'en-tête avec le bouton de masquage
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assessment,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'stock_summary_title'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_off, size: 20),
            onPressed: () => controller.isSummaryVisible.value = false,
            tooltip: 'stock_summary_hide'.tr,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String number, String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),

          // Valeur principale
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Titre
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
