import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/printing_controller.dart';
import '../models/models.dart';
import 'receipt_preview_page.dart';

class ReceiptDetailPage extends StatelessWidget {
  const ReceiptDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrintingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du reçu'),
        actions: [
          Obx(() {
            final receipt = controller.selectedReceipt;
            if (receipt == null) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, receipt, controller),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Aperçu'),
                    ],
                  ),
                ),
                if (controller.canReprintReceipt(receipt)) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'reprint_same',
                    child: Row(
                      children: [
                        Icon(Icons.print),
                        SizedBox(width: 8),
                        Text('Réimprimer (même format)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reprint_other',
                    child: Row(
                      children: [
                        Icon(Icons.print_outlined),
                        SizedBox(width: 8),
                        Text('Réimprimer (autre format)'),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        final receipt = controller.selectedReceipt;

        if (receipt == null) {
          return const Center(
            child: Text('Aucun reçu sélectionné'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête du reçu
              _buildReceiptHeader(receipt),
              const SizedBox(height: 24),

              // Informations de l'entreprise
              _buildCompanyInfo(receipt),
              const SizedBox(height: 24),

              // Informations de la vente
              _buildSaleInfo(receipt),
              const SizedBox(height: 24),

              // Informations du client
              if (receipt.customer != null) ...[
                _buildCustomerInfo(receipt),
                const SizedBox(height: 24),
              ],

              // Articles vendus
              _buildItemsList(receipt),
              const SizedBox(height: 24),

              // Totaux
              _buildTotals(receipt),
              const SizedBox(height: 24),

              // Informations de réimpression
              if (receipt.isReprint) ...[
                _buildReprintInfo(receipt),
                const SizedBox(height: 24),
              ],

              // Actions
              _buildActions(receipt, controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReceiptHeader(Receipt receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reçu N° ${receipt.saleNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${receipt.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFormatColor(receipt.format),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        receipt.format.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (receipt.isReprint) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          receipt.reprintIndicator,
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Créé le ${_formatDateTime(receipt.saleDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(Receipt receipt) {
    final company = receipt.companyInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informations de l\'entreprise',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nom', company.name),
            _buildInfoRow('Adresse', company.address),
            if (company.location?.isNotEmpty == true) _buildInfoRow('Localisation', company.location!),
            if (company.phone?.isNotEmpty == true) _buildInfoRow('Téléphone', company.phone!),
            if (company.email?.isNotEmpty == true) _buildInfoRow('Email', company.email!),
            if (company.nuiRccm?.isNotEmpty == true) _buildInfoRow('NUI RCCM', company.nuiRccm!),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleInfo(Receipt receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informations de la vente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID de vente', receipt.saleId),
            _buildInfoRow('Numéro de vente', receipt.saleNumber),
            _buildInfoRow('Date de vente', _formatDateTime(receipt.saleDate)),
            _buildInfoRow('Mode de paiement', receipt.paymentMethod),
            Row(
              children: [
                const Text(
                  'Statut de paiement:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: receipt.isFullyPaid ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    receipt.paymentStatus,
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }

  Widget _buildCustomerInfo(Receipt receipt) {
    final customer = receipt.customer!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informations du client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nom', customer.nom),
            if (customer.telephone?.isNotEmpty == true) _buildInfoRow('Téléphone', customer.telephone!),
            if (customer.adresse?.isNotEmpty == true) _buildInfoRow('Adresse', customer.adresse!),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(Receipt receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                Text(
                  'Articles (${receipt.items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...receipt.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: index < receipt.items.length - 1 ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.productReference.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Réf: ${item.productReference}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity} × ${item.formattedUnitPrice}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.formattedTotalPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals(Receipt receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Totaux',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTotalRow('Sous-total', receipt.subtotal),
            if (receipt.discountAmount > 0) _buildTotalRow('Remise', -receipt.discountAmount, isDiscount: true),
            const Divider(),
            _buildTotalRow('Total', receipt.totalAmount, isTotal: true),
            _buildTotalRow('Montant payé', receipt.paidAmount, isPaid: true),
            if (receipt.remainingAmount > 0) _buildTotalRow('Montant restant', receipt.remainingAmount, isRemaining: true),
          ],
        ),
      ),
    );
  }

  Widget _buildReprintInfo(Receipt receipt) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_copy, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informations de réimpression',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nombre de réimpressions', receipt.reprintCount.toString()),
            if (receipt.lastReprintDate != null) _buildInfoRow('Dernière réimpression', _formatDateTime(receipt.lastReprintDate!)),
            if (receipt.reprintBy?.isNotEmpty == true) _buildInfoRow('Réimprimé par', receipt.reprintBy!),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Receipt receipt, PrintingController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPreview(receipt, controller),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Aperçu'),
                  ),
                ),
                const SizedBox(width: 12),
                if (controller.canReprintReceipt(receipt))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isReprinting ? null : () => _showReprintOptions(receipt, controller),
                      icon: controller.isReprinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print),
                      label: Text(controller.isReprinting ? 'Impression...' : 'Réimprimer'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isPaid = false,
    bool isRemaining = false,
  }) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.normal;

    if (isTotal) {
      textColor = Colors.black;
      fontWeight = FontWeight.bold;
    } else if (isDiscount) {
      textColor = Colors.red;
    } else if (isPaid) {
      textColor = Colors.green;
    } else if (isRemaining) {
      textColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Receipt receipt, PrintingController controller) {
    switch (action) {
      case 'preview':
        _showPreview(receipt, controller);
        break;
      case 'reprint_same':
        _reprintReceipt(receipt, receipt.format);
        break;
      case 'reprint_other':
        _showReprintOptions(receipt, controller);
        break;
    }
  }

  void _showPreview(Receipt receipt, PrintingController controller) {
    controller.selectReceipt(receipt);
    Get.to(() => const ReceiptPreviewPage());
  }

  void _showReprintOptions(Receipt receipt, PrintingController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le format de réimpression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.getAvailableFormats().map((format) {
            final isCurrent = format == receipt.format;

            return ListTile(
              leading: Icon(_getFormatIcon(format)),
              title: Text(format.displayName),
              subtitle: isCurrent ? const Text('Format actuel') : null,
              trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Get.back();
                _reprintReceipt(receipt, format);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
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
