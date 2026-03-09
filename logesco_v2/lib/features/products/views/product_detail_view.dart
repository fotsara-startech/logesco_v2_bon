import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/product_detail_controller.dart';
import '../widgets/expiration_dates_list_widget.dart';
import '../../../shared/constants/constants.dart';
import '../../../core/widgets/permission_widget.dart';

/// Vue des détails d'un produit
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductDetailController());

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingView();
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorView(controller.errorMessage.value);
      }

      final product = controller.product.value;
      if (product == null) {
        return _buildErrorView('product_detail_not_found'.tr);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(product.nom),
          elevation: 0,
          actions: [
            PermissionWidget(
              module: 'products',
              privilege: 'UPDATE',
              child: IconButton(
                onPressed: () => Get.toNamed('/products/${product.id}/edit', arguments: product),
                icon: const Icon(Icons.edit),
                tooltip: 'product_detail_edit'.tr,
              ),
            ),
            PermissionWidget(
              module: 'products',
              privilege: 'DELETE',
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _showDeleteDialog(product);
                      break;
                    case 'duplicate':
                      _duplicateProduct(product);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text('product_detail_duplicate'.tr),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text('product_detail_delete'.tr, style: const TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut du produit
              _buildStatusBanner(product),
              const SizedBox(height: 24),

              // Informations principales
              _buildInfoCard(
                'product_detail_general_info'.tr,
                Icons.info_outline,
                [
                  _buildInfoRow('product_detail_reference'.tr, product.reference),
                  _buildInfoRow('product_detail_name'.tr, product.nom),
                  if (product.description != null && product.description!.isNotEmpty) _buildInfoRow('product_detail_description'.tr, product.description!),
                  if (product.categorie != null && product.categorie!.isNotEmpty) _buildInfoRow('product_detail_category'.tr, product.categorie!),
                ],
              ),
              const SizedBox(height: 16),

              // Informations commerciales
              _buildInfoCard(
                'product_detail_commercial_info'.tr,
                Icons.attach_money,
                [
                  _buildInfoRow('product_detail_sale_price'.tr, CurrencyConstants.formatAmount(product.prixUnitaire)),
                  if (product.prixAchat != null) ...[
                    _buildInfoRow('product_detail_purchase_price'.tr, CurrencyConstants.formatAmount(product.prixAchat!)),
                    _buildInfoRow('product_detail_margin'.tr, product.marge != null ? CurrencyConstants.formatAmount(product.marge!) : 'product_detail_na'.tr),
                    _buildInfoRow('product_detail_margin_percent'.tr, product.pourcentageMarge != null ? '${product.pourcentageMarge!.toStringAsFixed(1)}%' : 'product_detail_na'.tr),
                  ],
                  if (product.codeBarre != null && product.codeBarre!.isNotEmpty) _buildInfoRow('product_detail_barcode'.tr, product.codeBarre!),
                  if (product.categorie != null && product.categorie!.isNotEmpty)
                    _buildInfoRow('product_detail_category'.tr, product.categorie!)
                  else if (product.categorieId != null)
                    _buildInfoRow('product_detail_category'.tr, 'product_detail_category_unresolved'.tr.replaceAll('@id', product.categorieId.toString()))
                  else
                    _buildInfoRow('product_detail_category'.tr, 'product_detail_category_none'.tr),
                  if (!product.estService) _buildInfoRow('product_detail_stock_threshold'.tr, '${product.seuilStockMinimum} ${'product_detail_units'.tr}'),
                ],
              ),
              const SizedBox(height: 16),

              // Informations système
              _buildInfoCard(
                'product_detail_system_info'.tr,
                Icons.schedule,
                [
                  _buildInfoRow('product_detail_creation_date'.tr, _formatDate(product.dateCreation)),
                  _buildInfoRow('product_detail_modification_date'.tr, _formatDate(product.dateModification)),
                  _buildInfoRow('product_detail_type'.tr, product.estService ? 'product_detail_service'.tr : 'product_detail_physical'.tr),
                  _buildInfoRow('product_detail_status'.tr, product.estActif ? 'product_detail_active_status'.tr : 'product_detail_inactive_status'.tr),
                  _buildInfoRow('product_detail_expiration_management'.tr, product.gestionPeremption ? 'product_detail_expiration_enabled'.tr : 'product_detail_expiration_disabled'.tr),
                ],
              ),
              const SizedBox(height: 16),

              // Dates de péremption (si activé)
              if (product.gestionPeremption) ...[
                _buildExpirationDatesSection(product),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        floatingActionButton: PermissionWidget(
          module: 'products',
          privilege: 'UPDATE',
          child: FloatingActionButton(
            onPressed: () => Get.toNamed('/products/${product.id}/edit', arguments: product),
            tooltip: 'product_detail_edit'.tr,
            child: const Icon(Icons.edit),
          ),
        ),
      );
    });
  }

  /// Construit la bannière de statut
  Widget _buildStatusBanner(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: product.estActif ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: product.estActif ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            product.estActif ? Icons.check_circle : Icons.cancel,
            color: product.estActif ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.estActif ? 'product_detail_active'.tr : 'product_detail_inactive'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: product.estActif ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                Text(
                  product.estActif ? 'product_detail_active_subtitle'.tr : 'product_detail_inactive_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: product.estActif ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte d'informations
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des dates de péremption
  Widget _buildExpirationDatesSection(Product product) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpirationDatesListWidget(
          produitId: product.id,
          gestionPeremption: product.gestionPeremption,
        ),
      ),
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Affiche la boîte de dialogue de suppression
  void _showDeleteDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: Text('product_detail_delete_confirm_title'.tr),
        content: Text(
          'product_detail_delete_confirm_message'.tr.replaceAll('@name', product.nom),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('product_detail_delete_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implémenter la suppression
              Get.snackbar(
                'product_detail_delete'.tr,
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('product_detail_delete_button'.tr),
          ),
        ],
      ),
    );
  }

  /// Duplique un produit
  void _duplicateProduct(Product product) {
    Get.toNamed('/products/create', arguments: {
      'duplicate': true,
      'product': product,
    });
  }

  /// Construit la vue d'erreur
  Widget _buildErrorView([String? message]) {
    return Scaffold(
      appBar: AppBar(
        title: Text('product_detail_not_found'.tr),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'product_detail_not_found'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'product_detail_error'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/products'),
              icon: const Icon(Icons.arrow_back),
              label: Text('product_detail_back'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView([String? productId]) {
    return Scaffold(
      appBar: AppBar(
        title: Text('product_detail_loading'.tr),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${'product_detail_loading'.tr}${productId != null ? ' $productId' : ''}...'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('product_detail_delete_cancel'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
