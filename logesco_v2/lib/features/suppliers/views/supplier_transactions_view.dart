import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/supplier.dart';
import '../controllers/supplier_controller.dart';

/// Vue pour afficher l'historique des transactions d'un fournisseur
class SupplierTransactionsView extends StatefulWidget {
  const SupplierTransactionsView({super.key});

  @override
  State<SupplierTransactionsView> createState() => _SupplierTransactionsViewState();
}

class _SupplierTransactionsViewState extends State<SupplierTransactionsView> {
  late final SupplierController controller;
  Supplier? supplier;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SupplierController>();

    // Récupérer le fournisseur depuis les arguments
    supplier = Get.arguments as Supplier?;

    if (supplier != null) {
      // Charger les transactions une seule fois
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isInitialized) {
          _isInitialized = true;
          controller.loadSupplierTransactions(supplier!.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supplier == null) {
      return Scaffold(
        appBar: AppBar(title: Text('suppliers_error'.tr)),
        body: Center(child: Text('suppliers_not_found'.tr)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('suppliers_transactions_title'.tr),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _buildTransactionsContent(supplier!, controller),
    );
  }

  Widget _buildTransactionsContent(Supplier supplier, SupplierController controller) {
    return Column(
      children: [
        // En-tête avec info fournisseur
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
                  supplier.nom.isNotEmpty ? supplier.nom[0].toUpperCase() : 'F',
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
                      supplier.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'suppliers_id_label'.trParams({'id': supplier.id.toString()}),
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

            if (controller.supplierTransactions.isEmpty) {
              return _buildEmptyState();
            }

            return _buildTransactionsList(controller.supplierTransactions);
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
            'suppliers_no_transactions'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'suppliers_no_transactions_hint'.tr,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<SupplierTransaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(SupplierTransaction transaction) {
    // Pour les fournisseurs:
    // - Débit/Achat (rouge, -) = Augmente la dette (on leur doit plus)
    // - Crédit/Paiement (vert, +) = Réduit la dette (on les paie)
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
                'suppliers_reference_label'.trParams({'type': transaction.referenceType!, 'id': transaction.referenceId.toString()}),
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
                isCredit ? 'suppliers_credit'.tr : 'suppliers_debit'.tr,
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

  void _showTransactionDetails(SupplierTransaction transaction) {
    Get.dialog(
      AlertDialog(
        title: Text('suppliers_transaction_details'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('suppliers_transaction_type'.tr, transaction.typeTransactionDisplay),
            _buildDetailRow('suppliers_transaction_amount'.tr, '${transaction.montant.toStringAsFixed(0)} FCFA'),
            _buildDetailRow('suppliers_transaction_description'.tr, transaction.description ?? 'N/A'),
            _buildDetailRow('suppliers_transaction_date'.tr, _formatDate(transaction.dateTransaction)),
            if (transaction.referenceType != null && transaction.referenceId != null) _buildDetailRow('suppliers_transaction_reference'.tr, '${transaction.referenceType} #${transaction.referenceId}'),
            _buildDetailRow('suppliers_balance_after'.tr, '${transaction.soldeApres.toStringAsFixed(0)} FCFA'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('suppliers_close'.tr),
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
