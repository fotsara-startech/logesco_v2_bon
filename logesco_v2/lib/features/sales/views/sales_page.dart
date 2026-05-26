import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/sales_controller.dart';
import '../widgets/sales_list_item.dart';
import '../widgets/sales_table_view.dart';
import '../widgets/sales_details_view.dart';
import '../widgets/sales_filters.dart';
import '../widgets/sales_search_bar.dart';
import 'create_sale_page.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/models/models.dart';
import '../../printing/views/receipt_preview_page.dart';
import '../../company_settings/controllers/company_settings_controller.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> with AutomaticKeepAliveClientMixin {
  late SalesController controller;

  @override
  bool get wantKeepAlive => false; // Ne pas garder l'état en cache

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SalesController>() ? Get.find<SalesController>() : Get.put(SalesController());

    // Charger les ventes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSales(refresh: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les ventes à chaque fois que la page devient visible
    // Mais seulement si ce n'est pas le premier chargement (déjà fait dans initState)
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          controller.loadSales(refresh: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          String viewLabel;
          switch (controller.viewMode) {
            case 'table':
              viewLabel = ' - ${'sales_table_view'.tr}';
              break;
            case 'details':
              viewLabel = ' - ${'sales_details_view'.tr}';
              break;
            default:
              viewLabel = '';
          }
          return Text('${'sales_title'.tr}$viewLabel');
        }),
        actions: [
          // Bouton pour masquer/afficher les filtres
          Obx(() => IconButton(
                onPressed: () => controller.toggleFiltersVisibility(),
                icon: Icon(controller.filtersVisible ? Icons.filter_list_off : Icons.filter_list),
                tooltip: controller.filtersVisible ? 'Masquer les filtres' : 'Afficher les filtres',
              )),

          // Bouton pour basculer entre les vues (liste -> tableau -> détails -> liste)
          Obx(() {
            IconData icon;
            String tooltip;
            String nextMode;

            switch (controller.viewMode) {
              case 'list':
                icon = Icons.table_chart;
                tooltip = 'sales_table_view'.tr;
                nextMode = 'table';
                break;
              case 'table':
                icon = Icons.list_alt;
                tooltip = 'sales_details_view'.tr;
                nextMode = 'details';
                break;
              case 'details':
                icon = Icons.view_list;
                tooltip = 'sales_list_view'.tr;
                nextMode = 'list';
                break;
              default:
                icon = Icons.view_list;
                tooltip = 'sales_list_view'.tr;
                nextMode = 'list';
            }

            return IconButton(
              onPressed: () => controller.setViewMode(nextMode),
              icon: Icon(icon),
              tooltip: tooltip,
            );
          }),

          // Bouton pour recharger les stocks réels
          IconButton(
            onPressed: () async {
              await controller.refreshStocks();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'sales_refresh_stocks'.tr,
          ),

          ElevatedButton.icon(
            onPressed: () => Get.to(() => const CreateSalePage()),
            icon: const Icon(Icons.add),
            label: Text('sales_new'.tr),
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

            // Filtres (conditionnels)
            Obx(() => controller.filtersVisible
                ? Column(
                    children: const [
                      SalesFilters(),
                      SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink()),

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
                          'sales_no_sales'.tr,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'sales_start_first_sale'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                // Basculer entre vue liste, tableau et détails
                if (controller.viewMode == 'table') {
                  return SalesTableView(
                    sales: controller.sales,
                    onTap: (sale) => _showSaleDetails(context, sale),
                    hasMoreData: controller.hasMoreData,
                    onLoadMore: () => controller.loadMoreSales(),
                  );
                }

                if (controller.viewMode == 'details') {
                  return SalesDetailsView(
                    sales: controller.sales,
                    onTap: (sale) => _showSaleDetails(context, sale),
                    hasMoreData: controller.hasMoreData,
                    onLoadMore: () => controller.loadMoreSales(),
                  );
                }

                // Vue liste par défaut
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
        title: Text('sales_sale_details'.trParams({'number': sale.numeroVente})),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sale.client != null) ...[
                Text('sales_client_name'.trParams({'name': '${sale.client!.nom} ${sale.client!.prenom ?? ''}'})),
                const SizedBox(height: 8),
              ],
              if (sale.vendeur != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Vendeur: ${sale.vendeur!.nomUtilisateur}', style: const TextStyle(color: Colors.blueGrey)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text('sales_payment_mode'.tr + ': ${sale.modePaiement}'),
              Text('sales_total_amount_label'.tr + ': ${sale.montantTotal.toStringAsFixed(0)} FCFA'),
              if (sale.montantRemise > 0) ...[
                Text('sales_discount_label'.tr + ': ${sale.montantRemise.toStringAsFixed(0)} FCFA'),
              ],
              Text('sales_final_amount'.tr + ': ${sale.montantFinal.toStringAsFixed(0)} FCFA'),
              Text('sales_amount_paid_this_sale'.tr + ': ${sale.montantPaye.toStringAsFixed(0)} FCFA'),
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
                          Text(
                            'sales_debt_managed_client'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'sales_check_client_account'.tr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
              Text('sales_status'.tr + ': ${sale.statut}'),
              const SizedBox(height: 16),
              Text('sales_details'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (sale.details != null && sale.details.isNotEmpty) ...[
                ...sale.details.map((detail) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('sales_product_line'
                          .trParams({'product': detail.produit?.nom ?? 'Produit ${detail.produitId}', 'quantity': detail.quantite.toString(), 'amount': detail.montantLigne.toStringAsFixed(0)})),
                    )),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('sales_no_details'.tr),
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
              label: Text('sales_reprint'.tr),
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
              child: Text('sales_cancel_sale'.tr),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('sales_close'.tr),
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
        title: Text('sales_confirm_cancel'.tr),
        content: Text('sales_confirm_cancel_message'.trParams({'number': sale.numeroVente})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('no'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.cancelSale(sale.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('sales_yes_cancel'.tr),
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
        SnackbarHelper.error('sales_company_not_configured'.tr, title: 'sales_error'.tr);
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
        SnackbarHelper.error('sales_cannot_generate_receipt'.tr, title: 'sales_error'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('sales_receipt_generation_error'.trParams({'error': e.toString()}), title: 'sales_error'.tr);
    }
  }
}
