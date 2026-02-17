import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/printing_controller.dart';
import '../models/models.dart';
import 'receipt_detail_page.dart';
import 'receipt_preview_page.dart';

class ReceiptHistoryPage extends StatelessWidget {
  const ReceiptHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrintingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des reçus'),
        actions: [
          IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () => _showSearchDialog(context, controller),
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher',
          ),
          PopupMenuButton<ReceiptFilterPreset>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtres',
            onSelected: controller.applyPresetFilter,
            itemBuilder: (context) => controller.getAvailablePresets().map((preset) {
              return PopupMenuItem(
                value: preset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPresetIcon(preset),
                      size: 20,
                      color: controller.activePreset == preset ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            preset.displayName,
                            style: TextStyle(
                              fontWeight: controller.activePreset == preset ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            preset.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche rapide et filtres actifs
          _buildSearchAndFiltersBar(controller),

          // Liste des reçus
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.receipts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.receipts.isEmpty) {
                return _buildEmptyState(controller);
              }

              return RefreshIndicator(
                onRefresh: () => controller.refresh(),
                child: Column(
                  children: [
                    // En-tête avec informations de pagination
                    _buildPaginationHeader(controller),

                    // Liste des reçus
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = controller.receipts[index];
                          return _buildReceiptCard(context, receipt, controller);
                        },
                      ),
                    ),

                    // Contrôles de pagination
                    _buildPaginationControls(controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersBar(PrintingController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro de vente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          controller.searchController.clear();
                          controller.clearSearchCriteria();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            // Indicateur de filtres actifs
            if (controller.hasActiveFilters) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.activeFiltersCount} filtre(s) actif(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearSearchCriteria,
                    child: const Text('Effacer tout'),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPaginationHeader(PrintingController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Text(
              '${controller.totalReceipts} reçu(s) trouvé(s)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (controller.totalPages > 1) ...[
              Text(
                'Page ${controller.currentPage} sur ${controller.totalPages}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildReceiptCard(BuildContext context, Receipt receipt, PrintingController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToReceiptDetail(context, receipt, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'N° ${receipt.saleNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (receipt.isReprint) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  receipt.reprintIndicator,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(receipt.saleDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getFormatColor(receipt.format),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          receipt.format.displayName.split(' ')[0], // Juste "A4", "A5", ou "Thermique"
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations client et paiement
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (receipt.customer != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  receipt.customer!.nom,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              receipt.paymentMethod,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: receipt.isFullyPaid ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                receipt.paymentStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: receipt.isFullyPaid ? Colors.green[800] : Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bouton de réimpression
                  if (controller.canReprintReceipt(receipt))
                    PopupMenuButton<PrintFormat>(
                      icon: const Icon(Icons.print, color: Colors.blue),
                      tooltip: 'Réimprimer',
                      onSelected: (format) => _reprintReceipt(receipt, format),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: receipt.format,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 16, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              Text('Même format (${receipt.format.displayName})'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        ...controller.getAvailableFormats().where((f) => f != receipt.format).map((format) => PopupMenuItem(
                              value: format,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getFormatIcon(format), size: 16),
                                  const SizedBox(width: 8),
                                  Text(format.displayName),
                                ],
                              ),
                            )),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(PrintingController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            controller.hasActiveFilters ? 'Aucun reçu trouvé avec ces critères' : 'Aucun reçu disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.hasActiveFilters ? 'Essayez de modifier vos critères de recherche' : 'Les reçus apparaîtront ici après les ventes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (controller.hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.clearSearchCriteria,
              child: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationControls(PrintingController controller) {
    return Obx(() {
      if (controller.totalPages <= 1) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton précédent
            ElevatedButton.icon(
              onPressed: controller.hasPreviousPages && !controller.isLoading ? controller.loadPreviousPage : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Précédent'),
            ),

            // Indicateur de page
            if (controller.totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '${controller.currentPage} / ${controller.totalPages}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

            // Bouton suivant
            ElevatedButton.icon(
              onPressed: controller.hasMorePages && !controller.isLoading ? controller.loadNextPage : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Suivant'),
            ),
          ],
        ),
      );
    });
  }

  void _showSearchDialog(BuildContext context, PrintingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche avancée'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.saleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de vente',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateSearchCriteria(
                saleNumber: controller.saleNumberController.text.trim(),
                customerName: controller.customerNameController.text.trim(),
              );
              controller.searchReceipts();
              Get.back();
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _navigateToReceiptDetail(BuildContext context, Receipt receipt, PrintingController controller) {
    controller.selectReceipt(receipt);
    Get.to(() => const ReceiptDetailPage());
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getFormatColor(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return Colors.blue;
      case PrintFormat.a5:
        return Colors.green;
      case PrintFormat.thermal:
        return Colors.orange;
    }
  }

  IconData _getFormatIcon(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return Icons.description;
      case PrintFormat.a5:
        return Icons.note;
      case PrintFormat.thermal:
        return Icons.receipt;
    }
  }

  IconData _getPresetIcon(ReceiptFilterPreset preset) {
    switch (preset) {
      case ReceiptFilterPreset.all:
        return Icons.all_inclusive;
      case ReceiptFilterPreset.today:
        return Icons.today;
      case ReceiptFilterPreset.thisWeek:
        return Icons.date_range;
      case ReceiptFilterPreset.thisMonth:
        return Icons.calendar_month;
      case ReceiptFilterPreset.reprints:
        return Icons.content_copy;
      case ReceiptFilterPreset.cash:
        return Icons.money;
      case ReceiptFilterPreset.credit:
        return Icons.credit_card;
      case ReceiptFilterPreset.highValue:
        return Icons.trending_up;
    }
  }

  Future<void> _reprintReceipt(Receipt receipt, PrintFormat format) async {
    try {
      final controller = Get.find<PrintingController>();

      // Naviguer directement vers la page de prévisualisation avec le reçu existant
      controller.selectReceipt(receipt.copyWith(format: format));

      Get.to(
        () => const ReceiptPreviewPage(),
        arguments: controller.currentReceipt,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la réimpression: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
