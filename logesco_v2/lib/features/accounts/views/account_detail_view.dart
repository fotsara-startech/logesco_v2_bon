import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../models/account.dart';
import '../widgets/transaction_form_dialog.dart';
import '../widgets/credit_limit_dialog.dart';
import '../widgets/transaction_list_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

/// Vue de détail d'un compte (client ou fournisseur)
class AccountDetailView extends GetView<AccountController> {
  const AccountDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final bool isClient = arguments is CompteClient;
    final Account compte = arguments as Account;

    return Scaffold(
      appBar: AppBar(
        title: Text(isClient
            ? 'customers_account'.trParams({'name': (compte as CompteClient).client.nomComplet})
            : 'accounts_supplier_account_title'.trParams({'name': (compte as CompteFournisseur).fournisseur.nom})),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            onPressed: () => _showCreditLimitDialog(compte, isClient),
            tooltip: 'accounts_edit_credit_limit_tooltip'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshTransactions(compte, isClient),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAccountSummary(compte, isClient),
          _buildActionButtons(compte, isClient),
          const Divider(),
          _buildTransactionsHeader(),
          Expanded(
            child: _buildTransactionsList(compte, isClient),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionDialog(compte, isClient),
        child: const Icon(Icons.add),
        tooltip: 'accounts_new_transaction'.tr,
      ),
    );
  }

  /// Construit le résumé du compte
  Widget _buildAccountSummary(Account compte, bool isClient) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).primaryColor,
            Theme.of(Get.context!).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du client/fournisseur
          Text(
            isClient ? (compte as CompteClient).client.nomComplet : (compte as CompteFournisseur).fournisseur.nom,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Informations financières
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: isClient ? 'sales_current_debt'.tr : 'accounts_supplier_debt'.tr,
                  value: '${compte.soldeActuel.toStringAsFixed(0)} FCFA',
                  icon: Icons.account_balance,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'accounts_credit_limit'.tr,
                  value: '${compte.limiteCredit.toStringAsFixed(0)} FCFA',
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'customers_available_credit'.tr,
                  value: '${compte.creditDisponible.toStringAsFixed(0)} FCFA',
                  icon: Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'status'.tr,
                  value: compte.estEnDepassement ? 'accounts_overlimit_badge'.tr : 'ok'.tr,
                  icon: compte.estEnDepassement ? Icons.warning : Icons.check_circle,
                ),
              ),
            ],
          ),

          // Barre de progression du crédit
          if (compte.limiteCredit > 0) ...[
            const SizedBox(height: 16),
            _buildCreditProgressBar(compte),
          ],
        ],
      ),
    );
  }

  /// Construit un élément du résumé
  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit la barre de progression du crédit
  Widget _buildCreditProgressBar(Account compte) {
    final pourcentageUtilise = compte.limiteCredit > 0 ? (compte.soldeActuel / compte.limiteCredit).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'accounts_credit_usage'.tr,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(pourcentageUtilise * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pourcentageUtilise,
          backgroundColor: Colors.white30,
          valueColor: AlwaysStoppedAnimation<Color>(
            pourcentageUtilise >= 1.0 ? Colors.red : Colors.white,
          ),
        ),
      ],
    );
  }

  /// Construit les boutons d'action
  Widget _buildActionButtons(Account compte, bool isClient) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showTransactionDialog(compte, isClient, 'paiement'),
              icon: const Icon(Icons.payment),
              label: Text('customers_payment'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showTransactionDialog(compte, isClient, 'debit'),
              icon: const Icon(Icons.add_circle),
              label: Text(isClient ? 'stock_filter_sale'.tr : 'stock_filter_purchase'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête des transactions
  Widget _buildTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.history),
          const SizedBox(width: 8),
          Text(
            'accounts_transactions_history'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
                'accounts_transactions_count'.trParams({'count': '${controller.transactions.length}'}),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              )),
        ],
      ),
    );
  }

  /// Construit la liste des transactions
  Widget _buildTransactionsList(Account compte, bool isClient) {
    return Obx(() {
      if (controller.isLoadingTransactions.value && controller.transactions.isEmpty) {
        return LoadingWidget(message: 'accounts_loading_transactions'.tr);
      }

      if (controller.transactions.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.receipt_long,
          title: 'customers_no_transactions'.tr,
          message: 'accounts_empty_transactions_message'.tr,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.transactions.length + (controller.hasMoreDataTransactions.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.transactions.length) {
            if (controller.isLoadingMoreTransactions.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.loadTransactions(
                  isClient: isClient,
                  accountId: isClient ? (compte as CompteClient).clientId : (compte as CompteFournisseur).fournisseurId,
                );
              });
              return const SizedBox.shrink();
            }
          }

          final transaction = controller.transactions[index];
          return TransactionListItem(transaction: transaction);
        },
      );
    });
  }

  /// Affiche le dialogue de transaction
  void _showTransactionDialog(Account compte, bool isClient, [String? typeTransaction]) {
    showDialog(
      context: Get.context!,
      builder: (context) => TransactionFormDialog(
        isClient: isClient,
        accountId: isClient ? (compte as CompteClient).clientId : (compte as CompteFournisseur).fournisseurId,
        initialType: typeTransaction,
        onTransactionCreated: () => _refreshTransactions(compte, isClient),
      ),
    );
  }

  /// Affiche le dialogue de limite de crédit
  void _showCreditLimitDialog(Account compte, bool isClient) {
    showDialog(
      context: Get.context!,
      builder: (context) => CreditLimitDialog(
        isClient: isClient,
        accountId: isClient ? (compte as CompteClient).clientId : (compte as CompteFournisseur).fournisseurId,
        currentLimit: compte.limiteCredit,
        accountName: isClient ? (compte as CompteClient).client.nomComplet : (compte as CompteFournisseur).fournisseur.nom,
      ),
    );
  }

  /// Actualise les transactions
  void _refreshTransactions(Account compte, bool isClient) {
    controller.loadTransactions(
      isClient: isClient,
      accountId: isClient ? (compte as CompteClient).clientId : (compte as CompteFournisseur).fournisseurId,
      refresh: true,
    );
  }
}
