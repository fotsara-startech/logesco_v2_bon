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
        title: Text('inventory_title'.tr),
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
                  title: Text('inventory_export_stock'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export_movements',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('inventory_export_movements'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'bulk_adjust',
                child: ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text('inventory_bulk_adjust'.tr),
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
                  label: 'inventory_stocks'.tr,
                  index: 0,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.warning,
                  label: 'inventory_alerts'.tr,
                  index: 1,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.history,
                  label: 'inventory_movements'.tr,
                  index: 2,
                  controller: _tabController,
                ),
                _buildVerticalTab(
                  icon: Icons.event_busy,
                  label: 'inventory_expirations'.tr,
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
        'Export en cours',
        'Génération de l\'export des stocks...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportStockToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text('Export des stocks sauvegardé avec succès.\n'
                'Fichier: ${filePath.split('/').last}\n'
                'Voulez-vous partager le fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: Implémenter le partage de fichier
                  Get.snackbar(
                    'Partage',
                    'Fonctionnalité de partage à implémenter',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Partager'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Erreur lors de l\'export des stocks',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
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
        'Export en cours',
        'Génération de l\'export des mouvements...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportMovementsToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text('Export des mouvements sauvegardé avec succès.\n'
                'Fichier: ${filePath.split('/').last}\n'
                'Voulez-vous partager le fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: Implémenter le partage de fichier
                  Get.snackbar(
                    'Partage',
                    'Fonctionnalité de partage à implémenter',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Partager'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Erreur lors de l\'export des mouvements',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
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
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.loadSummary,
              child: const Text('Réessayer'),
            ),
          ],
        );
      }

      final summary = controller.summary.value;
      if (summary == null) {
        return const Center(
          child: Text('Aucune donnée disponible'),
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
              const Expanded(
                child: Text(
                  'Résumé des stocks',
                  style: TextStyle(
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
            'Produits',
            summary.totalProduits.toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'Achat',
            _formatValue(summary.valeurStockAchat),
            Icons.shopping_cart,
            Colors.green,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'Vente',
            _formatValue(summary.valeurStockVente ?? summary.valeurTotaleStock),
            Icons.sell,
            Colors.teal,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'Alertes',
            summary.produitsEnAlerte.toString(),
            Icons.warning,
            summary.produitsEnAlerte > 0 ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'Ruptures',
            summary.produitsEnRupture.toString(),
            Icons.error,
            summary.produitsEnRupture > 0 ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),

          _buildVerticalStatCard(
            'En stock',
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
