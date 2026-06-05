import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/inventory_getx_controller.dart';
import '../services/export_service.dart';
import '../services/inventory_pdf_service.dart';
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
                value: 'export_stock_pdf',
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('${'stock_export_stock'.tr} (PDF)'),
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
                value: 'export_movements_pdf',
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('${'stock_export_movements'.tr} (PDF)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // PopupMenuItem(
              //   value: 'bulk_adjust',
              //   child: ListTile(
              //     leading: const Icon(Icons.edit_note),
              //     title: Text('stock_bulk_adjustment'.tr),
              //     contentPadding: EdgeInsets.zero,
              //   ),
              // ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          if (isMobile) return _buildMobileInventoryLayout(context, controller);
          return _buildDesktopInventoryLayout(context, controller);
        },
      ),
    );
  }

  Widget _buildMobileInventoryLayout(BuildContext context, InventoryGetxController controller) {
    return Column(
      children: [
        ListenableBuilder(listenable: _tabController, builder: (context, child) => InventorySearchBar(currentTabIndex: _tabController.index)),
        const InventoryFilterBar(),
        ListenableBuilder(listenable: _tabController, builder: (context, child) => _tabController.index != 2 ? const StockSortBar() : const SizedBox.shrink()),
        // Résumé de stock horizontal (mobile)
        _buildMobileSummaryBanner(controller),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.inventory, size: 18), text: 'stock_tab_stocks'.tr),
            Tab(icon: const Icon(Icons.warning, size: 18), text: 'stock_tab_alerts'.tr),
            Tab(icon: const Icon(Icons.history, size: 18), text: 'stock_tab_movements'.tr),
            Tab(icon: const Icon(Icons.event_busy, size: 18), text: 'stock_tab_expiration'.tr),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [StockListGetxView(), StockAlertsGetxView(), StockMovementsGetxView(), ExpirationTabView()],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSummaryBanner(InventoryGetxController controller) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null) return const SizedBox.shrink();

      final items = [
        (label: 'stock_summary_products'.tr, value: summary.totalProduits.toString(), icon: Icons.inventory_2, color: Colors.blue),
        (label: 'stock_summary_purchases'.tr, value: _formatValue(summary.valeurStockAchat), icon: Icons.shopping_cart, color: Colors.green),
        (label: 'stock_summary_sales'.tr, value: _formatValue(summary.valeurStockVente ?? summary.valeurTotaleStock), icon: Icons.sell, color: Colors.teal),
        (label: 'stock_summary_alerts'.tr, value: summary.produitsEnAlerte.toString(), icon: Icons.warning, color: summary.produitsEnAlerte > 0 ? Colors.orange : Colors.grey),
        (label: 'stock_summary_ruptures'.tr, value: summary.produitsEnRupture.toString(), icon: Icons.error, color: summary.produitsEnRupture > 0 ? Colors.red : Colors.grey),
        (label: 'stock_summary_in_stock'.tr, value: '${summary.pourcentageEnStock}%', icon: Icons.check_circle, color: Colors.indigo),
      ];

      return Container(
        height: 80,
        color: Colors.grey[50],
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final item = items[i];
            return Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(item.icon, size: 13, color: item.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: item.color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildDesktopInventoryLayout(BuildContext context, InventoryGetxController controller) {
    return Row(
      children: [
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildVerticalTab(icon: Icons.inventory, label: 'stock_tab_stocks'.tr, index: 0, controller: _tabController),
              _buildVerticalTab(icon: Icons.warning, label: 'stock_tab_alerts'.tr, index: 1, controller: _tabController),
              _buildVerticalTab(icon: Icons.history, label: 'stock_tab_movements'.tr, index: 2, controller: _tabController),
              _buildVerticalTab(icon: Icons.event_busy, label: 'stock_tab_expiration'.tr, index: 3, controller: _tabController),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              ListenableBuilder(listenable: _tabController, builder: (context, child) => InventorySearchBar(currentTabIndex: _tabController.index)),
              const InventoryFilterBar(),
              ListenableBuilder(listenable: _tabController, builder: (context, child) => _tabController.index != 2 ? const StockSortBar() : const SizedBox.shrink()),
              Expanded(child: TabBarView(controller: _tabController, children: const [StockListGetxView(), StockAlertsGetxView(), StockMovementsGetxView(), ExpirationTabView()])),
            ],
          ),
        ),
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(-2, 0))],
          ),
          child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildVerticalSummary(controller)),
        ),
      ],
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
      case 'export_stock_pdf':
        _exportStockPdf();
        break;
      case 'export_movements':
        _exportMovements();
        break;
      case 'export_movements_pdf':
        _exportMovementsPdf();
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
      SnackbarHelper.info('stock_export_fetching'.tr, title: 'stock_export_in_progress'.tr, duration: const Duration(seconds: 2));

      final filePath = await controller.exportStockToExcel();
      if (filePath != null) {
        // En mode web, filePath est juste le nom du fichier, pas un chemin complet
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          // Sur le web, le fichier est automatiquement téléchargé par le navigateur
          SnackbarHelper.success(
            'Fichier téléchargé: $filename',
            title: 'stock_export_success'.tr,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Sur desktop/mobile, ouvrir le fichier
          SnackbarHelper.info('Ouverture du fichier...', duration: const Duration(seconds: 1));
          await ExportService.openExcelFile(filePath);

          // Afficher le dialog de confirmation
          Get.dialog(
            AlertDialog(
              title: Text('stock_export_success'.tr),
              content: Text('${'stock_export_success_message'.tr}\n'
                  'Fichier: $filename\n'
                  'Le fichier a été ouvert automatiquement.\n'
                  '${'stock_export_share_question'.tr}'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('close'.tr),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await ExportService.shareExcelFile(filePath);
                  },
                  child: Text('stock_export_share'.tr),
                ),
              ],
            ),
          );
        }
      } else {
        SnackbarHelper.error('stock_export_error'.tr);
      }
    } catch (e) {
      print('❌ Erreur export: $e');
      SnackbarHelper.error('Erreur lors de l\'exportation des stocks: ${e.toString()}');
    }
  }

  void _exportMovements() async {
    final controller = Get.find<InventoryGetxController>();

    try {
      // Afficher un indicateur de chargement
      SnackbarHelper.info('stock_export_movements_in_progress'.tr, title: 'stock_export_in_progress'.tr, duration: const Duration(seconds: 2));

      final filePath = await controller.exportMovementsToExcel();
      if (filePath != null) {
        // En mode web, filePath est juste le nom du fichier, pas un chemin complet
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          // Sur le web, le fichier est automatiquement téléchargé par le navigateur
          SnackbarHelper.success(
            'Fichier téléchargé: $filename',
            title: 'stock_export_success'.tr,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Sur desktop/mobile, ouvrir le fichier
          await ExportService.openExcelFile(filePath);

          // Afficher le dialog de confirmation
          Get.dialog(
            AlertDialog(
              title: Text('stock_export_success'.tr),
              content: Text('${'stock_export_success_message'.tr}\n'
                  'Fichier: $filename\n'
                  '${'stock_export_share_question'.tr}'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('close'.tr),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await ExportService.shareExcelFile(filePath);
                  },
                  child: Text('stock_export_share'.tr),
                ),
              ],
            ),
          );
        }
      } else {
        SnackbarHelper.error('stock_export_movements_error'.tr);
      }
    } catch (e) {
      print('❌ Erreur export mouvements: $e');
      SnackbarHelper.error('Erreur lors de l\'exportation des mouvements: ${e.toString()}');
    }
  }

  void _showBulkAdjustment() {
    Get.toNamed('/inventory/bulk-adjustment');
  }

  void _exportStockPdf() async {
    final controller = Get.find<InventoryGetxController>();
    try {
      SnackbarHelper.info('Génération du PDF...', duration: const Duration(seconds: 2));
      final filePath = await controller.exportStockToPdf();
      if (filePath != null) {
        // En mode web, filePath est juste le nom du fichier
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          // Sur le web, le fichier est automatiquement téléchargé par le navigateur
          SnackbarHelper.success(
            'PDF téléchargé: $filename',
            title: 'Export réussi',
            duration: const Duration(seconds: 3),
          );
        } else {
          // Sur desktop/mobile, ouvrir le fichier
          SnackbarHelper.info('Ouverture du PDF...', duration: const Duration(seconds: 1));
          await InventoryPdfService.openPdf(filePath);
          _showExportSuccessDialog(filePath, isPdf: true);
        }
      } else {
        SnackbarHelper.error('stock_export_error'.tr);
      }
    } catch (e) {
      print('❌ Erreur export PDF: $e');
      SnackbarHelper.error('Erreur lors de l\'export PDF: ${e.toString()}');
    }
  }

  void _exportMovementsPdf() async {
    final controller = Get.find<InventoryGetxController>();
    try {
      SnackbarHelper.info('Génération du PDF des mouvements...', duration: const Duration(seconds: 2));
      final filePath = await controller.exportMovementsToPdf();
      if (filePath != null) {
        // En mode web, filePath est juste le nom du fichier
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          // Sur le web, le fichier est automatiquement téléchargé par le navigateur
          SnackbarHelper.success(
            'PDF téléchargé: $filename',
            title: 'Export réussi',
            duration: const Duration(seconds: 3),
          );
        } else {
          // Sur desktop/mobile, ouvrir le fichier
          SnackbarHelper.info('Ouverture du PDF...', duration: const Duration(seconds: 1));
          await InventoryPdfService.openPdf(filePath);
          _showExportSuccessDialog(filePath, isPdf: true);
        }
      } else {
        SnackbarHelper.error('stock_export_movements_error'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('stock_export_error_message'.trParams({'error': e.toString()}));
    }
  }

  void _showExportSuccessDialog(String filePath, {bool isPdf = false}) {
    Get.dialog(
      AlertDialog(
        title: Text('stock_export_success'.tr),
        content: Text('Fichier: ${kIsWeb ? filePath : filePath.split('/').last}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              if (isPdf) {
                InventoryPdfService.sharePdf(filePath);
              } else {
                ExportService.shareExcelFile(filePath);
              }
            },
            icon: const Icon(Icons.share),
            label: Text('stock_export_share'.tr),
          ),
        ],
      ),
    );
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
    if (value == null) return 'N/A';
    if (value == 0) return '0 FCFA';
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }
}
