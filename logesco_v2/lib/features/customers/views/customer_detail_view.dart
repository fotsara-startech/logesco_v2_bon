import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/widgets/permission_widget.dart';
import '../models/customer.dart';

/// Vue de détail d'un client (version simplifiée)
class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final Customer customer = Get.arguments as Customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.nomComplet),
        elevation: 0,
        actions: [
          PermissionWidget(
            module: 'customers',
            privilege: 'UPDATE',
            child: IconButton(
              onPressed: () => Get.toNamed('/customers/${customer.id}/edit', arguments: customer),
              icon: const Icon(Icons.edit),
              tooltip: 'edit'.tr,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'informations principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.nomComplet,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'customers_client_id'.trParams({'id': customer.id.toString()}),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations de contact
            _buildInfoSection(
              'customers_contact_info'.tr,
              [
                if (customer.telephone != null) _buildInfoRow(Icons.phone, 'customers_phone'.tr, customer.telephone!),
                if (customer.email != null) _buildInfoRow(Icons.email, 'customers_email'.tr, customer.email!),
                if (customer.adresse != null) _buildInfoRow(Icons.location_on, 'customers_address'.tr, customer.adresse!),
              ],
            ),

            const SizedBox(height: 16),

            // Section Compte et Transactions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'customers_account'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'customers_account_history'.tr,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed(
                          '/customers/${customer.id}/transactions',
                          arguments: customer,
                        ),
                        icon: const Icon(Icons.history),
                        label: Text('customers_view_transactions'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations système
            _buildInfoSection(
              'customers_system_info'.tr,
              [
                _buildInfoRow(
                  Icons.calendar_today,
                  'customers_created_date'.tr,
                  _formatDate(customer.dateCreation),
                ),
                _buildInfoRow(
                  Icons.update,
                  'customers_modified_date'.tr,
                  _formatDate(customer.dateModification),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: PermissionWidget(
                    module: 'customers',
                    privilege: 'UPDATE',
                    child: OutlinedButton.icon(
                      onPressed: () => Get.toNamed('/customers/${customer.id}/edit', arguments: customer),
                      icon: const Icon(Icons.edit),
                      label: Text('edit'.tr),
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

  /// Construit une section d'informations
  Widget _buildInfoSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
