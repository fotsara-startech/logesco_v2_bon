import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/sale.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/models/models.dart';
import '../../printing/views/receipt_preview_page.dart';
import '../../company_settings/controllers/company_settings_controller.dart';

class SalesListItem extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SalesListItem({
    super.key,
    required this.sale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'sales_sale_number'.trParams({'number': sale.numeroVente}),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sale.client != null) Text('sales_client_name'.trParams({'name': '${sale.client!.nom} ${sale.client!.prenom ?? ''}'})),
            Text('sales_total_label'.trParams({'amount': sale.montantFinal.toStringAsFixed(0)})),
            // SOLUTION 2: Ne plus afficher les détails de paiement partiel
            // La dette est gérée au niveau du compte client
            Text(
              'sales_paid_label'.trParams({'amount': sale.montantPaye.toStringAsFixed(0)}),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(sale.dateCreation),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Bouton de réimpression
              if (!sale.isCancelled)
                IconButton(
                  onPressed: () => _reprintReceipt(context),
                  icon: const Icon(Icons.print),
                  tooltip: 'sales_reprint_receipt'.tr,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor() {
    // SOLUTION 2: Toutes les ventes sont vertes (terminées) sauf si annulées
    if (sale.isCancelled) return Colors.red;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    // SOLUTION 2: Icône simple - terminée ou annulée
    if (sale.isCancelled) return Icons.cancel;
    return Icons.check_circle;
  }

  Widget _buildStatusChip() {
    String label;
    Color color;

    // SOLUTION 2: Toutes les ventes sont "Terminée" sauf si annulées
    // La gestion des dettes se fait au niveau du compte client
    if (sale.isCancelled) {
      label = 'sales_status_cancelled'.tr;
      color = Colors.red;
    } else {
      label = 'sales_status_completed'.tr;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _reprintReceipt(BuildContext context) async {
    try {
      // Récupérer les contrôleurs nécessaires
      final printingController = Get.find<PrintingController>();
      final companyController = Get.find<CompanySettingsController>();

      // S'assurer que le profil d'entreprise est chargé
      if (companyController.companyProfile == null) {
        await companyController.loadCompanyProfile();
      }

      if (companyController.companyProfile == null) {
        Get.snackbar(
          'sales_error'.tr,
          'sales_company_not_configured'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      // Générer le reçu pour cette vente (sans dialogue de chargement)
      final success = await printingController.generateReceiptForSale(
        sale.id.toString(),
        format: PrintFormat.thermal, // Format par défaut
        companyProfile: companyController.companyProfile,
      );

      if (success && printingController.currentReceipt != null) {
        // Naviguer vers la page de prévisualisation
        Get.to(
          () => const ReceiptPreviewPage(),
          arguments: printingController.currentReceipt,
        );
      } else {
        Get.snackbar(
          'sales_error'.tr,
          'sales_cannot_generate_receipt'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'sales_error'.tr,
        'sales_receipt_generation_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
