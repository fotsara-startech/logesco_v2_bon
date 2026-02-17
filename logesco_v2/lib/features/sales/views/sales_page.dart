import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../widgets/sales_list_item.dart';
import '../widgets/sales_filters.dart';
import '../widgets/sales_search_bar.dart';
import 'create_sale_page.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/models/models.dart';
import '../../printing/views/receipt_preview_page.dart';
import '../../company_settings/controllers/company_settings_controller.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SalesController>() ? Get.find<SalesController>() : Get.put(SalesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes'),
        actions: [
          // Bouton pour recharger les stocks réels
          IconButton(
            onPressed: () async {
              await controller.refreshStocks();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger stocks réels',
          ),

          ElevatedButton.icon(
            onPressed: () => Get.to(() => const CreateSalePage()),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle vente'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barre de recherche
            const SalesSearchBar(),
            const SizedBox(height: 16),

            // Filtres
            const SalesFilters(),
            const SizedBox(height: 16),

            // Liste des ventes
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.sales.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune vente',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par créer votre première vente',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadSales(refresh: true),
                  child: ListView.builder(
                    itemCount: controller.sales.length + (controller.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.sales.length) {
                        // Indicateur de chargement pour plus de données
                        if (controller.hasMoreData) {
                          // Defer the call to avoid setState during build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.loadMoreSales();
                          });
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final sale = controller.sales[index];
                      return SalesListItem(
                        sale: sale,
                        onTap: () => _showSaleDetails(context, sale),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDetails(BuildContext context, sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vente ${sale.numeroVente}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sale.client != null) ...[
                Text('Client: ${sale.client!.nom} ${sale.client!.prenom ?? ''}'),
                const SizedBox(height: 8),
              ],
              Text('Mode de paiement: ${sale.modePaiement}'),
              Text('Montant total: ${sale.montantTotal.toStringAsFixed(0)} FCFA'),
              if (sale.montantRemise > 0) ...[
                Text('Remise: ${sale.montantRemise.toStringAsFixed(0)} FCFA'),
              ],
              Text('Montant final: ${sale.montantFinal.toStringAsFixed(0)} FCFA'),
              Text('Montant payé lors de cette vente: ${sale.montantPaye.toStringAsFixed(0)} FCFA'),
              // SOLUTION 2: Ne plus afficher le montant restant car la dette est gérée au niveau du compte client
              if (sale.client != null && sale.montantRestant > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          const Text(
                            'Dette gérée au compte client',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultez le compte du client pour voir sa dette totale.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
              Text('Statut: ${sale.statut}'),
              const SizedBox(height: 16),
              const Text('Détails:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (sale.details != null && sale.details.isNotEmpty) ...[
                ...sale.details.map((detail) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('${detail.produit?.nom ?? 'Produit ${detail.produitId}'} x${detail.quantite} = ${detail.montantLigne.toStringAsFixed(0)} FCFA'),
                    )),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('Aucun détail disponible'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!sale.isCancelled) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _reprintReceipt(context, sale);
              },
              icon: const Icon(Icons.print),
              label: const Text('Réimprimer reçu'),
            ),
          ],
          // SOLUTION 2: Suppression du bouton "Ajouter paiement"
          // Les paiements se font via de nouvelles ventes, la dette est gérée au compte client
          if (!sale.isCancelled) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmCancelSale(context, sale);
              },
              child: const Text('Annuler vente'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // SOLUTION 2: Méthode désactivée - Les paiements ne se font plus sur les ventes individuelles
  // La dette est gérée au niveau du compte client
  // Pour encaisser un paiement, créer une nouvelle vente qui inclura automatiquement la dette
  /*
  void _showPaymentDialog(BuildContext context, sale) {
    final controller = Get.find<SalesController>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Montant restant: ${sale.montantRestant.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Montant payé',
                suffixText: 'FCFA',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.of(context).pop();
                await controller.addPayment(
                  sale.id,
                  amount,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
  */

  void _confirmCancelSale(BuildContext context, sale) {
    final controller = Get.find<SalesController>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: Text('Êtes-vous sûr de vouloir annuler la vente ${sale.numeroVente} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.cancelSale(sale.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _reprintReceipt(BuildContext context, sale) async {
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
          'Erreur',
          'Profil d\'entreprise non configuré.\nAllez dans Paramètres > Entreprise pour configurer les informations.',
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
          'Erreur',
          'Impossible de générer le reçu pour cette vente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du reçu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
