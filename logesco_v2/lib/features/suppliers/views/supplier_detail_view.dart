import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supplier_detail_controller.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/debug_banner.dart';

/// Vue de détail d'un fournisseur
class SupplierDetailView extends StatelessWidget {
  const SupplierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierDetailController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du fournisseur'),
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
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
          return const LoadingWidget(message: 'Chargement du fournisseur...');
        }

        if (controller.hasError.value) {
          return ErrorDisplayWidget(
            message: controller.errorMessage.value,
            onRetry: controller.loadSupplier,
          );
        }

        final supplier = controller.supplier.value;
        if (supplier == null) {
          return const Center(
            child: Text('Fournisseur non trouvé'),
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
                title: 'Informations générales',
                icon: Icons.business,
                children: [
                  _buildInfoRow('Nom', supplier.nom),
                  if (supplier.personneContact != null) _buildInfoRow('Contact', supplier.personneContact!),
                ],
              ),
              const SizedBox(height: 16),

              // Coordonnées
              _buildInfoCard(
                title: 'Coordonnées',
                icon: Icons.contact_phone,
                children: [
                  if (supplier.telephone != null) _buildInfoRow('Téléphone', supplier.telephone!, actionIcon: Icons.call, onActionTap: () => controller.callSupplier(supplier.telephone!)),
                  if (supplier.email != null) _buildInfoRow('Email', supplier.email!, actionIcon: Icons.email, onActionTap: () => controller.emailSupplier(supplier.email!)),
                  if (supplier.adresse != null) _buildInfoRow('Adresse', supplier.adresse!, actionIcon: Icons.map, onActionTap: () => controller.showAddressOnMap(supplier.adresse!)),
                ],
              ),
              const SizedBox(height: 16),

              // Informations système
              _buildInfoCard(
                title: 'Informations système',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('ID', '#${supplier.id}'),
                  _buildInfoRow('Créé le', _formatDate(supplier.dateCreation)),
                  _buildInfoRow('Modifié le', _formatDate(supplier.dateModification)),
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
        const Text(
          'Actions rapides',
          style: TextStyle(
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
                label: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.viewOrders,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Commandes'),
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
