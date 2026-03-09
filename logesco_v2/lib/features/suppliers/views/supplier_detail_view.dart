import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supplier_detail_controller.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

/// Vue de détail d'un fournisseur
class SupplierDetailView extends StatelessWidget {
  const SupplierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierDetailController());

    return Scaffold(
      appBar: AppBar(
        title: Text('suppliers_detail'.tr),
        elevation: 0,
        actions: [
          Obx(() => controller.supplier.value != null
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        controller.editSupplier();
                        break;
                      case 'delete':
                        controller.deleteSupplier();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text('suppliers_edit'.tr),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text('suppliers_delete'.tr, style: const TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return LoadingWidget(message: 'suppliers_loading'.tr);
        }

        if (controller.hasError.value) {
          return ErrorDisplayWidget(
            message: controller.errorMessage.value,
            onRetry: controller.loadSupplier,
          );
        }

        final supplier = controller.supplier.value;
        if (supplier == null) {
          return Center(
            child: Text('suppliers_not_found'.tr),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom du fournisseur
              _buildHeader(supplier.nom),
              const SizedBox(height: 24),

              // Informations générales
              _buildInfoCard(
                title: 'suppliers_info_general'.tr,
                icon: Icons.business,
                children: [
                  _buildInfoRow('suppliers_name'.tr, supplier.nom),
                  if (supplier.personneContact != null) _buildInfoRow('suppliers_contact'.tr, supplier.personneContact!),
                ],
              ),
              const SizedBox(height: 16),

              // Coordonnées
              _buildInfoCard(
                title: 'suppliers_contact_info'.tr,
                icon: Icons.contact_phone,
                children: [
                  if (supplier.telephone != null) _buildInfoRow('suppliers_phone'.tr, supplier.telephone!, actionIcon: Icons.call, onActionTap: () => controller.callSupplier(supplier.telephone!)),
                  if (supplier.email != null) _buildInfoRow('suppliers_email'.tr, supplier.email!, actionIcon: Icons.email, onActionTap: () => controller.emailSupplier(supplier.email!)),
                  if (supplier.adresse != null) _buildInfoRow('suppliers_address'.tr, supplier.adresse!, actionIcon: Icons.map, onActionTap: () => controller.showAddressOnMap(supplier.adresse!)),
                ],
              ),
              const SizedBox(height: 16),

              // Section Compte et Transactions
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'suppliers_account'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'suppliers_account_description'.tr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(
                            '/suppliers/${supplier.id}/account',
                            arguments: supplier,
                          ),
                          icon: const Icon(Icons.history),
                          label: Text('suppliers_view_account'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informations système
              _buildInfoCard(
                title: 'suppliers_system_info'.tr,
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('suppliers_id'.tr, '#${supplier.id}'),
                  _buildInfoRow('suppliers_created_at'.tr, _formatDate(supplier.dateCreation)),
                  _buildInfoRow('suppliers_updated_at'.tr, _formatDate(supplier.dateModification)),
                ],
              ),
              const SizedBox(height: 24),

              // Actions rapides
              _buildQuickActions(controller),
            ],
          ),
        );
      }),
    );
  }

  /// Construit l'en-tête avec le nom du fournisseur
  Widget _buildHeader(String nom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.business,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            nom,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte d'informations
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
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
  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? actionIcon,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (actionIcon != null && onActionTap != null)
            IconButton(
              onPressed: onActionTap,
              icon: Icon(actionIcon, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  /// Construit les actions rapides
  Widget _buildQuickActions(SupplierDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'suppliers_quick_actions'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.editSupplier,
                icon: const Icon(Icons.edit),
                label: Text('suppliers_edit'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.viewOrders,
                icon: const Icon(Icons.shopping_cart),
                label: Text('suppliers_orders'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
