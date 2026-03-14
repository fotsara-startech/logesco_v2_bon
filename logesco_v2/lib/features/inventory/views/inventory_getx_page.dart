import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/stock_list_getx_view.dart';
import '../widgets/stock_alerts_getx_view.dart';
import '../widgets/stock_movements_getx_view.dart';
import '../widgets/expiration_tab_view.dart';
import '../widgets/stock_sort_bar.dart';

/// Page principale de gestion de l'inventaire utilisant GetX
class InventoryGetxPage extends StatefulWidget {
  const InventoryGetxPage({super.key});

  @override
  State<InventoryGetxPage> createState() => _InventoryGetxPageState();
}

class _InventoryGetxPageState extends State<InventoryGetxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Écouter les changements d'onglet pour nettoyer la recherche
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Nettoyer la recherche quand on change d'onglet
        final controller = Get.find<InventoryGetxController>();
        controller.updateSearchQuery('');
      }
    });

    // Charger les données initiales après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<InventoryGetxController>();
      // Charger directement les données sans vérification d'auth complexe
      controller.loadSummary();
      controller.loadCategories();
      controller.loadStocks(refresh: true);
      controller.loadStockAlerts(refresh: true);
      controller.loadMovements(refresh: true);
      controller.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('stock_title'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAll(),
            tooltip: 'refresh'.tr,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_stock',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text('stock_export_stock'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export_movements',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('stock_export_movements'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'bulk_adjust',
                child: ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text('stock_bulk_adjustment'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation verticale à gauche
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildVerticalTab(
                  icon: Icons.inventory,
                  label: 'stock_tab_stocks'.tr,
                  index: 0,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.warning,
                  label: 'stock_tab_alerts'.tr,
                  index: 1,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.history,
                  label: 'stock_tab_movements'.tr,
                  index: 2,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.event_busy,
                  label: 'stock_tab_expiration'.tr,
                  index: 3,
                  controller: _tabController,
                ),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Barre de recherche contextuelle
                ListenableBuilder(
                  listenable: _tabController,
                  builder: (context, child) {
                    return InventorySearchBar(
                      currentTabIndex: _tabController.index,
                    );
                  },
                ),

                // Barre de filtres (affichée seulement si des filtres sont actifs)
                const InventoryFilterBar(),

                // Barre de tri (affichée seulement pour les onglets Stocks et Alertes)
                ListenableBuilder(
                  listenable: _tabController,
                  builder: (context, child) {
                    return _tabController.index != 2 ? const StockSortBar() : const SizedBox.shrink();
                  },
                ),

                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      StockListGetxView(),
                      StockAlertsGetxView(),
                      StockMovementsGetxView(),
                      ExpirationTabView(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Résumé du stock à droite (vertical)
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildVerticalSummary(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTab({
    required IconData icon,
    required String label,
    required int index,
    required TabController controller,
  }) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isSelected = controller.index == index;
        return InkWell(
          onTap: () => controller.animateTo(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_stock':
        _exportStock();
        break;
      case 'export_movements':
        _exportMovements();
        break;
      case 'bulk_adjust':
        _showBulkAdjustment();
        break;
    }
  }

  void _exportStock() async {
    final controller = Get.find<InventoryGetxController>();

    try {
      // Afficher un indicateur de chargement
      Get.snackbar(
        'stock_export_in_progress'.tr,
        'stock_export_fetching'.tr,
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportStockToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        Get.dialog(
          AlertDialog(
            title: Text('stock_export_success'.tr),
            content: Text('${'stock_export_success_message'.tr}\n'
                'Fichier: ${filePath.split('/').last}\n'
                '${'stock_export_share_question'.tr}'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('close'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: Implémenter le partage de fichier
                  Get.snackbar(
                    'stock_export_share'.tr,
                    'feature_coming_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text('stock_export_share'.tr),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'stock_export_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'stock_export_error_message'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _exportMovements() async {
    final controller = Get.find<InventoryGetxController>();

    try {
      // Afficher un indicateur de chargement
      Get.snackbar(
        'stock_export_in_progress'.tr,
        'stock_export_movements_in_progress'.tr,
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportMovementsToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        Get.dialog(
          AlertDialog(
            title: Text('stock_export_success'.tr),
            content: Text('${'stock_export_success_message'.tr}\n'
                'Fichier: ${filePath.split('/').last}\n'
                '${'stock_export_share_question'.tr}'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('close'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: Implémenter le partage de fichier
                  Get.snackbar(
                    'stock_export_share'.tr,
                    'feature_coming_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text('stock_export_share'.tr),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'stock_export_movements_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'stock_export_error_message'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _showBulkAdjustment() {
    Get.toNamed('/inventory/bulk-adjustment');
  }

  Widget _buildVerticalSummary(InventoryGetxController controller) {
    return Obx(() {
      if (controller.isLoadingSummary.value && controller.summary.value == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.summaryError.value.isNotEmpty) {
        return Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'stock_error_loading'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.loadSummary,
              child: Text('stock_error_retry'.tr),
            ),
          ],
        );
      }

      final summary = controller.summary.value;
      if (summary == null) {
        return Center(
          child: Text('stock_no_data'.tr),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
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
            ],
          ),
          const SizedBox(height: 16),

          // Cartes statistiques en colonne
          _buildVerticalStatCard(
            'stock_summary_products'.tr,
            summary.totalProduits.toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'stock_summary_purchases'.tr,
            _formatValue(summary.valeurStockAchat),
            Icons.shopping_cart,
            Colors.green,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'stock_summary_sales'.tr,
            _formatValue(summary.valeurStockVente ?? summary.valeurTotaleStock),
            Icons.sell,
            Colors.teal,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'stock_summary_alerts'.tr,
            summary.produitsEnAlerte.toString(),
            Icons.warning,
            summary.produitsEnAlerte > 0 ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'stock_summary_ruptures'.tr,
            summary.produitsEnRupture.toString(),
            Icons.error,
            summary.produitsEnRupture > 0 ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'stock_summary_in_stock'.tr,
            '${summary.pourcentageEnStock}%',
            Icons.check_circle,
            Colors.indigo,
          ),
        ],
      );
    });
  }

  Widget _buildVerticalStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double? value) {
    if (value == null) {
      return 'N/A';
    }
    if (value == 0) {
      return '0 F';
    }
    // Format compact pour les grandes valeurs
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M F';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K F';
    }
    return '${value.toStringAsFixed(0)} F';
  }
}
