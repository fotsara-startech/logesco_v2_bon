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
        title: Text(isClient ? 'Compte Client' : 'Compte Fournisseur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            onPressed: () => _showCreditLimitDialog(compte, isClient),
            tooltip: 'Modifier limite de crédit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshTransactions(compte, isClient),
            tooltip: 'Actualiser',
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
        tooltip: 'Nouvelle transaction',
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
                  label: isClient ? 'Dette actuelle' : 'Dette envers fournisseur',
                  value: '${compte.soldeActuel.toStringAsFixed(0)} FCFA',
                  icon: Icons.account_balance,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Limite de crédit',
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
                  label: 'Crédit disponible',
                  value: '${compte.creditDisponible.toStringAsFixed(0)} FCFA',
                  icon: Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Statut',
                  value: compte.estEnDepassement ? 'DÉPASSEMENT' : 'OK',
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
            const Text(
              'Utilisation du crédit',
              style: TextStyle(
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
              label: const Text('Paiement'),
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
              label: Text(isClient ? 'Vente' : 'Achat'),
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
          const Text(
            'Historique des transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
                '${controller.transactions.length} transaction(s)',
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
        return const LoadingWidget(message: 'Chargement des transactions...');
      }

      if (controller.transactions.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.receipt_long,
          title: 'Aucune transaction',
          message: 'L\'historique des transactions apparaîtra ici.',
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
