import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/inventory/views/stock_movement_page.dart';
import '../controllers/inventory_controller.dart';
import '../services/export_service.dart';
import '../widgets/stock_summary_card.dart';
import '../widgets/stock_alerts_card.dart';
import '../widgets/stock_list_view.dart';
import '../widgets/stock_movements_view.dart';
import 'stock_adjustment_page.dart';
import 'bulk_stock_adjustment_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données initiales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<InventoryController>();
      controller.loadSummary();
      controller.loadStocks(refresh: true);
      controller.loadStockAlerts(refresh: true);
      controller.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.find<InventoryController>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Stockk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
            tooltip: 'Filtres',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_stock',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporter stocks (Excel)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_movements',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Exporter mouvements (Excel)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_adjust',
                child: ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Ajustement en lot'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory),
              text: 'Stockss',
            ),
            Tab(
              icon: Icon(Icons.warning),
              text: 'Alertess',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Mouvements',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Résumé du stock
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: StockSummaryCard(),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StockListView(),
                StockAlertsView(),
                StockMovementsView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => StockMovementPage());
        }, // _showAdjustmentDialog,
        tooltip: 'Ajuster le stock',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _refreshData() {
    final controller = Get.find<InventoryController>();
    controller.loadSummary();
    controller.loadStocks(refresh: true);
    controller.loadStockAlerts(refresh: true);
    controller.loadMovements(refresh: true);

    Get.snackbar(
      'Succès',
      'Données actualisées',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const InventoryFiltersSheet(),
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
    final controller = Get.find<InventoryController>();

    try {
      // Afficher un indicateur de chargement
      Get.snackbar(
        'Export',
        'Génération de l\'export en cours...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportStockToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        final filename = filePath.split('/').last;
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text('Export des stocks sauvegardé avec succès.\nFichier: $filename\nVoulez-vous partager le fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await ExportService.shareExcelFile(filePath);
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
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _exportMovements() async {
    final controller = Get.find<InventoryController>();

    try {
      // Afficher un indicateur de chargement
      Get.snackbar(
        'Export',
        'Génération de l\'export en cours...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final filePath = await controller.exportMovementsToExcel();
      if (filePath != null) {
        // Afficher le dialog de confirmation
        final filename = filePath.split('/').last;
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text('Export des mouvements sauvegardé avec succès.\nFichier: $filename\nVoulez-vous partager le fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await ExportService.shareExcelFile(filePath);
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
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showBulkAdjustment() {
    Get.to(() => const BulkStockAdjustmentPage());
  }

  void _showAdjustmentDialog() {
    Get.to(() => const StockAdjustmentPage());
  }
}

class InventoryFiltersSheet extends StatefulWidget {
  const InventoryFiltersSheet({Key? key}) : super(key: key);

  @override
  State<InventoryFiltersSheet> createState() => _InventoryFiltersSheetState();
}

class _InventoryFiltersSheetState extends State<InventoryFiltersSheet> {
  bool? _alerteStock;
  int? _produitId;
  String? _typeMouvement;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<InventoryController>();
    _alerteStock = controller.alertFilter;
    _produitId = controller.productFilter;
    _typeMouvement = controller.movementTypeFilter;
    _dateDebut = controller.dateDebutFilter;
    _dateFin = controller.dateFinFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtres',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Filtre alerte de stock
          CheckboxListTile(
            title: const Text('Stocks en alerte uniquement'),
            value: _alerteStock ?? false,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _alerteStock = value;
              });
            },
          ),

          // Filtre type de mouvement
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Type de mouvement',
              border: OutlineInputBorder(),
            ),
            value: _typeMouvement,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: 'achat', child: Text('Achat')),
              DropdownMenuItem(value: 'vente', child: Text('Vente')),
              DropdownMenuItem(value: 'ajustement', child: Text('Ajustement')),
              DropdownMenuItem(value: 'retour', child: Text('Retour')),
            ],
            onChanged: (value) {
              setState(() {
                _typeMouvement = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Filtres de date
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date début',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _dateDebut?.toString().split(' ')[0] ?? '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateDebut ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _dateDebut = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date fin',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _dateFin?.toString().split(' ')[0] ?? '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateFin ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _dateFin = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),

          // Espace pour le clavier
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  void _clearFilters() {
    Get.find<InventoryController>().clearFilters();
    Get.back();
  }

  void _applyFilters() {
    final controller = Get.find<InventoryController>();

    controller.applyStockFilters(
      alerteStock: _alerteStock,
      produitId: _produitId,
    );

    controller.applyMovementFilters(
      produitId: _produitId,
      typeMouvement: _typeMouvement,
      dateDebut: _dateDebut,
      dateFin: _dateFin,
    );

    Get.back();
  }
}

// Placeholder pour les vues d'alertes
class StockAlertsView extends StatelessWidget {
  const StockAlertsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<InventoryController>(
      builder: (controller) {
        if (controller.isLoadingAlerts && controller.stockAlerts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.alertsError != null) {
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
                  'Erreur: ${controller.alertsError}',
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

        return StockAlertsCard(alerts: controller.stockAlerts);
      },
    );
  }
}

// Placeholder pour la page d'ajustement en lot
class BulkStockAdjustmentPage extends StatelessWidget {
  const BulkStockAdjustmentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustement en lot'),
      ),
      body: const Center(
        child: Text('Page d\'ajustement en lot - À implémenter'),
      ),
    );
  }
}
