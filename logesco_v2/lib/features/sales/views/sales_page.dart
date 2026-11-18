import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/sales_controller.dart';
import '../widgets/sales_list_item.dart';
import '../widgets/sales_table_view.dart';
import '../widgets/sales_details_view.dart';
import '../widgets/sales_grid_view.dart';
import '../widgets/sales_filters.dart';
import '../widgets/replace_item_dialog.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSales(refresh: true);
      // Recharger automatiquement quand une vente est créée depuis n'importe quelle page
      ever(controller.saleCreatedTrigger, (_) {
        if (mounted) controller.loadSales(refresh: true);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
            case 'grid':
              viewLabel = ' - ${'sales_grid_view'.tr}';
              break;
            default:
              viewLabel = '';
          }
          return Text('${'sales_title'.tr}$viewLabel');
        }),
        actions: [
          Builder(builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            if (isMobile) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () async {
                        await Get.to(() => const CreateSalePage());
                        // Recharger la liste quand on revient de la page de création
                        controller.loadSales(refresh: true);
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'sales_new'.tr),
                  IconButton(
                      onPressed: () async {
                        await Get.to(() => const CreateSalePage(startInQuickView: true));
                        controller.loadSales(refresh: true);
                      },
                      icon: const Icon(Icons.bolt),
                      tooltip: 'quick_billing_quick_view'.tr),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'filter') controller.toggleFiltersVisibility();
                      if (value == 'view') {
                        final next = controller.viewMode == 'list'
                            ? 'table'
                            : controller.viewMode == 'table'
                                ? 'details'
                                : controller.viewMode == 'details'
                                    ? 'grid'
                                    : 'list';
                        controller.setViewMode(next);
                      }
                      if (value == 'refresh') controller.refreshStocks();
                      if (value == 'export') controller.exportToExcel();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'filter',
                          child: ListTile(
                              leading: Icon(controller.filtersVisible ? Icons.filter_list_off : Icons.filter_list),
                              title: Text(controller.filtersVisible ? 'sales_hide_filters'.tr : 'sales_show_filters'.tr),
                              contentPadding: EdgeInsets.zero)),
                      PopupMenuItem(value: 'view', child: ListTile(leading: const Icon(Icons.view_list), title: Text('sales_table_view'.tr), contentPadding: EdgeInsets.zero)),
                      PopupMenuItem(value: 'refresh', child: ListTile(leading: const Icon(Icons.refresh), title: Text('sales_refresh_stocks'.tr), contentPadding: EdgeInsets.zero)),
                      PopupMenuItem(value: 'export', child: ListTile(leading: const Icon(Icons.file_download), title: Text('sales_export_excel'.tr), contentPadding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => IconButton(onPressed: () => controller.toggleFiltersVisibility(), icon: Icon(controller.filtersVisible ? Icons.filter_list_off : Icons.filter_list))),
                Obx(() {
                  final next = controller.viewMode == 'list'
                      ? 'table'
                      : controller.viewMode == 'table'
                          ? 'details'
                          : controller.viewMode == 'details'
                              ? 'grid'
                              : 'list';
                  final icon = controller.viewMode == 'list'
                      ? Icons.table_chart
                      : controller.viewMode == 'table'
                          ? Icons.list_alt
                          : controller.viewMode == 'details'
                              ? Icons.grid_view
                              : Icons.view_list;
                  return IconButton(onPressed: () => controller.setViewMode(next), icon: Icon(icon));
                }),
                IconButton(onPressed: () async => await controller.refreshStocks(), icon: const Icon(Icons.refresh)),
                Obx(() => IconButton(
                      onPressed: controller.isExporting ? null : () => controller.exportToExcel(),
                      icon: controller.isExporting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.file_download),
                      tooltip: 'sales_export_excel'.tr,
                    )),
                OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () async {
                      await Get.to(() => const CreateSalePage(startInQuickView: true));
                      controller.loadSales(refresh: true);
                    },
                    icon: const Icon(Icons.bolt),
                    label: Text('quick_billing_quick_view'.tr)),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                    onPressed: () async {
                      await Get.to(() => const CreateSalePage());
                      controller.loadSales(refresh: true);
                    },
                    icon: const Icon(Icons.add),
                    label: Text('sales_new'.tr)),
              ],
            );
          }),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 8 : 16,
          vertical: 16,
        ),
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

                if (controller.viewMode == 'grid') {
                  return SalesGridView(
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
                    Text('sales_seller_label'.trParams({'name': sale.vendeur!.nomUtilisateur}), style: const TextStyle(color: Colors.blueGrey)),
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
              if (!sale.isCancelled && !sale.sessionOuverte) ...[
                const SizedBox(height: 8),
                Text(
                  'sales_origin_session_closed_hint'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ],
              const SizedBox(height: 16),
              Text('sales_details'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (sale.details != null && sale.details.isNotEmpty) ...[
                ...sale.details.map((detail) {
                  final ligne = 'sales_product_line'.trParams({
                    'product': detail.produit?.nom ?? 'sales_product_fallback'.trParams({'id': '${detail.produitId}'}),
                    'quantity': detail.quantite.toString(),
                    'amount': detail.montantLigne.toStringAsFixed(0),
                  });
                  final peutAnnuler = !sale.isCancelled && !detail.annule && sale.sessionOuverte;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail.annule ? '$ligne (${'sales_item_cancelled'.tr})' : ligne,
                            style: detail.annule ? const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough) : null,
                          ),
                        ),
                        if (peutAnnuler)
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.blue),
                            tooltip: 'sales_replace_item_tooltip'.tr,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => ReplaceItemDialog(sale: sale, detail: detail),
                              );
                            },
                          ),
                        if (peutAnnuler)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                            tooltip: 'sales_cancel_item_tooltip'.tr,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmCancelItem(context, sale, detail);
                            },
                          ),
                      ],
                    ),
                  );
                }),
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
            // Bouton pour imprimer le reçu de suivi de compte si le client a utilisé son avance
            if (controller.saleUsedAccountBalance(sale))
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.printAccountUsageReceipt(sale);
                },
                icon: const Icon(Icons.receipt_long),
                label: Text('sales_print_account_followup'.tr),
              ),
          ],
          // Pas de bouton "Ajouter paiement" : les paiements se font via de
          // nouvelles ventes, la dette est gérée au compte client.
          // Annulation/échange : uniquement dans la session de caisse qui a créé la vente.
          if (!sale.isCancelled && sale.sessionOuverte) ...[
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

  void _confirmCancelItem(BuildContext context, sale, detail) {
    final controller = Get.find<SalesController>();
    final articlesActifs = sale.details.where((d) => !d.annule).length;
    final estDernier = articlesActifs <= 1;
    final nomProduit = detail.produit?.nom ?? 'sales_product_fallback'.trParams({'id': '${detail.produitId}'});

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sales_cancel_item_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('sales_cancel_item_message'.trParams({
              'product': nomProduit,
              'amount': detail.montantLigne.toStringAsFixed(0),
              'number': sale.numeroVente,
            })),
            if (estDernier) ...[
              const SizedBox(height: 12),
              Text(
                'sales_cancel_item_last_warning'.tr,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('no'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.cancelSaleItems(sale.id, [detail.id]);
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
