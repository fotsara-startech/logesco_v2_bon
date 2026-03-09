import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';
import '../controllers/customer_controller.dart';

/// Vue pour afficher l'historique des transactions d'un client
class CustomerTransactionsView extends StatefulWidget {
  const CustomerTransactionsView({super.key});

  @override
  State<CustomerTransactionsView> createState() => _CustomerTransactionsViewState();
}

class _CustomerTransactionsViewState extends State<CustomerTransactionsView> {
  late final CustomerController controller;
  late final int customerId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerController>();

    final String? customerIdStr = Get.parameters['customerId'];
    customerId = int.tryParse(customerIdStr ?? '0') ?? 0;

    if (customerId > 0) {
      // Charger les transactions une seule fois
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isInitialized) {
          _isInitialized = true;
          controller.loadCustomerTransactions(customerId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (customerId == 0) {
      return Scaffold(
        appBar: AppBar(title: Text('error'.tr)),
        body: Center(child: Text('customers_missing_id'.tr)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('customers_transaction_history'.tr),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final customer = controller.customers.firstWhereOrNull(
          (c) => c.id == customerId,
        );

        if (customer == null) {
          return Center(
            child: Text('customers_not_found'.tr),
          );
        }

        return _buildTransactionsContent(customer, controller);
      }),
    );
  }

  Widget _buildTransactionsContent(Customer customer, CustomerController controller) {
    return Column(
      children: [
        // En-tête avec info client
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  customer.nom.isNotEmpty ? customer.nom[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customer.nom} ${customer.prenom ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'customers_client_id'.trParams({'id': customer.id.toString()}),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste des transactions
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.customerTransactions.isEmpty) {
              return _buildEmptyState();
            }

            return _buildTransactionsList(controller.customerTransactions);
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'customers_no_transactions'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'customers_transactions_empty'.tr,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<CustomerTransaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(CustomerTransaction transaction) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          transaction.typeTransactionDisplay,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null) ...[
              Text(
                transaction.description!,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              _formatDate(transaction.dateTransaction),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (transaction.referenceType != null && transaction.referenceId != null) ...[
              const SizedBox(height: 2),
              Text(
                'customers_ref'.trParams({
                  'type': transaction.referenceType!,
                  'id': transaction.referenceId.toString(),
                }),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}${transaction.montant.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCredit ? 'customers_credit'.tr.toUpperCase() : 'customers_debit'.tr.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(CustomerTransaction transaction) {
    Get.dialog(
      AlertDialog(
        title: Text('customers_transaction_details'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('customers_transaction_type'.tr, transaction.typeTransactionDisplay),
            _buildDetailRow('customers_transaction_amount'.tr, '${transaction.montant.toStringAsFixed(0)} FCFA'),
            _buildDetailRow('description'.tr, transaction.description ?? 'N/A'),
            _buildDetailRow('customers_transaction_date'.tr, _formatDate(transaction.dateTransaction)),
            if (transaction.referenceType != null && transaction.referenceId != null) _buildDetailRow('customers_transaction_reference'.tr, '${transaction.referenceType} #${transaction.referenceId}'),
            _buildDetailRow('customers_balance_after'.tr, '${transaction.soldeApres.toStringAsFixed(0)} FCFA'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
