import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/customer.dart';
import '../controllers/customer_controller.dart';
import '../services/statement_pdf_service.dart';
import '../../accounts/models/account.dart';
import '../../accounts/widgets/unpaid_sales_selector_dialog.dart';
import '../../financial_movements/controllers/financial_movement_controller.dart';
import '../../../core/services/cash_register_refresh_service.dart';

/// Vue du compte client - SOLUTION 2: Système centralisé
///
/// Affiche le solde du compte et l'historique des transactions
/// C'est la source de vérité pour les dettes du client
class CustomerAccountView extends StatefulWidget {
  const CustomerAccountView({super.key});

  @override
  State<CustomerAccountView> createState() => _CustomerAccountViewState();
}

class _CustomerAccountViewState extends State<CustomerAccountView> {
  final CustomerController _controller = Get.find<CustomerController>();
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _customer = Get.arguments as Customer?;
    if (_customer != null) {
      // Utiliser WidgetsBinding pour charger après la construction
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTransactions();
      });
    }
  }

  Future<void> _loadTransactions() async {
    await _controller.loadCustomerTransactions(_customer!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: Text('error'.tr)),
        body: Center(child: Text('customers_not_found'.tr)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('customers_account'.trParams({'name': _customer!.nomComplet})),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadTransactions,
          child: Column(
            children: [
              _buildAccountSummary(),
              const Divider(height: 1),
              Expanded(child: _buildTransactionsList()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAccountSummary() {
    // Calculer le solde à partir des transactions
    double solde = 0.0;
    if (_controller.customerTransactions.isNotEmpty) {
      solde = _controller.customerTransactions.first.soldeApres;
    }

    final bool aDette = solde < 0;
    final double montantDette = aDette ? -solde : 0.0;
    final double creditDisponible = !aDette ? solde : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: aDette ? [Colors.red.shade400, Colors.red.shade600] : [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'customers_account_balance'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${solde.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (aDette)
                _buildSummaryCard(
                  'customers_has_debt'.tr,
                  '${montantDette.toStringAsFixed(0)} FCFA',
                  Icons.warning,
                  Colors.white.withOpacity(0.9),
                )
              else
                _buildSummaryCard(
                  'customers_available_credit'.tr,
                  '${creditDisponible.toStringAsFixed(0)} FCFA',
                  Icons.account_balance_wallet,
                  Colors.white.withOpacity(0.9),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (aDette)
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(montantDette),
                  icon: const Icon(Icons.payment),
                  label: Text('customers_pay_debt'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              if (aDette) const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _printTransactions,
                icon: const Icon(Icons.print),
                label: Text('print'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Obx(() {
      if (_controller.customerTransactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'customers_no_transactions'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.customerTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _controller.customerTransactions[index];
          return _buildTransactionItem(transaction);
        },
      );
    });
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final bool isCredit = transaction.typeTransaction.contains('paiement');
    final IconData icon = isCredit ? Icons.add_circle : Icons.remove_circle;
    final Color color = isCredit ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _getTransactionTypeLabel(transaction.typeTransaction),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.description ?? ''),
            const SizedBox(height: 4),
            Text(
              _formatDate(transaction.dateTransaction),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}${transaction.montant.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Solde: ${transaction.soldeApres.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'achat_comptant':
        return 'Achat comptant';
      case 'achat_credit':
        return 'Achat à crédit';
      case 'paiement':
        return 'Paiement';
      case 'paiement_dette':
        return 'Paiement de dette';
      case 'credit':
        return 'Crédit';
      case 'debit':
        return 'Débit';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Affiche le dialogue de paiement de dette
  void _showPaymentDialog(double montantDette) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    UnpaidSale? selectedSale;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('customers_pay_debt_dialog_title'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'customers_current_debt'.trParams({'amount': montantDette.toStringAsFixed(0)}),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                // Sélection obligatoire d'une vente
                Text(
                  'customers_select_sale'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => UnpaidSalesSelectorDialog(
                        clientId: _customer!.id,
                        onSaleSelected: (sale, montant) {
                          Navigator.pop(context, {
                            'sale': sale,
                            'montant': montant,
                          });
                        },
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        selectedSale = result['sale'] as UnpaidSale;
                        amountController.text = (result['montant'] as double).toStringAsFixed(0);
                        descriptionController.text = 'customers_debt_payment'.trParams({'reference': selectedSale!.reference});
                      });
                    }
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: Text(selectedSale == null ? 'customers_select_sale_button'.tr : 'customers_sale_selected'.trParams({'reference': selectedSale!.reference})),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: selectedSale == null ? Colors.blue : Colors.green,
                  ),
                ),
                if (selectedSale != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'customers_sale_selected'.trParams({'reference': selectedSale!.reference}),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('customers_sale_date'.trParams({'date': selectedSale!.dateVenteFormatted})),
                        Text('customers_sale_total'.trParams({'amount': selectedSale!.montantTotalFormatted})),
                        Text('customers_sale_paid'.trParams({'amount': selectedSale!.montantPayeFormatted})),
                        Text(
                          'customers_sale_remaining'.trParams({'amount': selectedSale!.montantRestantFormatted}),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'customers_amount_to_pay'.tr,
                    suffixText: 'FCFA',
                    border: const OutlineInputBorder(),
                    helperText: 'customers_partial_payment_hint'.tr,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: selectedSale != null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'customers_description_optional'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: selectedSale != null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton.icon(
              onPressed: selectedSale == null
                  ? null
                  : () {
                      print('🔵 [Dialog] Bouton "Confirmer le paiement" cliqué');
                      print('  - selectedSale: ${selectedSale?.reference}');
                      print('  - amountController.text: ${amountController.text}');
                      print('  - descriptionController.text: ${descriptionController.text}');

                      print('✅ [Dialog] Validation OK, appel de _processPayment');
                      _processPayment(
                        amountController.text,
                        descriptionController.text,
                        selectedSale,
                      );
                    },
              icon: const Icon(Icons.check),
              label: Text('customers_confirm_payment'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Traite le paiement de la dette
  Future<void> _processPayment(String amountText, String description, UnpaidSale? selectedSale) async {
    print('🔵 [_processPayment] Début du traitement');
    print('  - amountText: $amountText');
    print('  - description: $description');
    print('  - selectedSale: ${selectedSale?.reference}');

    // Vérifier qu'une vente est sélectionnée (obligatoire)
    if (selectedSale == null) {
      print('❌ [_processPayment] Aucune vente sélectionnée');
      Get.snackbar(
        'error'.tr,
        'customers_select_sale_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      print('❌ [_processPayment] Montant invalide');
      Get.snackbar(
        'error'.tr,
        'customers_invalid_amount'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    print('✅ [_processPayment] Montant valide: $amount');
    Navigator.of(context).pop(); // Fermer le dialogue

    // Payer la vente spécifique sélectionnée
    print('🎯 [_processPayment] Appel payCustomerDebtForSale');
    print('  - customerId: ${_customer!.id}');
    print('  - amount: $amount');
    print('  - venteId: ${selectedSale.id}');

    final success = await _controller.payCustomerDebtForSale(
      _customer!.id,
      amount,
      selectedSale.id,
      description: description.isEmpty ? 'Paiement Dette (Vente #${selectedSale.reference})' : description,
    );

    print('📊 [_processPayment] Résultat payCustomerDebtForSale: $success');

    if (success) {
      print('✅ [_processPayment] Paiement réussi, rechargement des transactions');

      // Recharger les transactions du client
      await _loadTransactions();

      // Rafraîchir le cache des mouvements financiers si le contrôleur existe
      print('🔄 [_processPayment] Tentative de rafraîchissement des mouvements financiers');
      try {
        if (Get.isRegistered<FinancialMovementController>()) {
          final financialController = Get.find<FinancialMovementController>();
          await financialController.refreshMovements();
          print('✅ [_processPayment] Cache des mouvements financiers rafraîchi');
        } else {
          print('⚠️ [_processPayment] FinancialMovementController non enregistré');
        }
      } catch (e) {
        print('⚠️ [_processPayment] Erreur lors du rafraîchissement des mouvements: $e');
      }

      // Rafraîchir le solde de la caisse via le service singleton
      print('🔄 [_processPayment] Rafraîchissement du solde de la caisse via service');
      try {
        final refreshService = CashRegisterRefreshService();
        await refreshService.refreshCashRegisters();
        print('✅ [_processPayment] Solde de la caisse rafraîchi avec succès');
      } catch (e) {
        print('⚠️ [_processPayment] Erreur lors du rafraîchissement de la caisse: $e');
      }
    } else {
      print('❌ [_processPayment] Paiement échoué');
    }
  }

  /// Imprime les transactions du client
  Future<void> _printTransactions() async {
    if (_customer == null || _controller.customerTransactions.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'customers_no_transactions_to_print'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    // Afficher un dialogue de prévisualisation
    await _showPrintPreviewDialog();
  }

  /// Affiche le dialogue de prévisualisation avant impression
  Future<void> _showPrintPreviewDialog() async {
    // Calculer le solde actuel
    double solde = 0.0;
    if (_controller.customerTransactions.isNotEmpty) {
      solde = _controller.customerTransactions.first.soldeApres;
    }

    final bool aDette = solde < 0;
    final String soldeText = solde < 0 ? 'Dette: ${(-solde).toStringAsFixed(0)} FCFA' : 'Crédit: ${solde.toStringAsFixed(0)} FCFA';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('customers_statement'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'customers_name'.tr}: ${_customer!.nomComplet}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                soldeText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: aDette ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'customers_transaction_count'.trParams({'count': _controller.customerTransactions.length.toString()}),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'customers_statement_includes'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('customers_statement_client_info'.tr),
              Text('customers_statement_balance'.tr),
              Text('customers_statement_history'.tr),
              Text('customers_statement_datetime'.tr),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _generateAndPrintStatement();
            },
            icon: const Icon(Icons.print),
            label: Text('print'.tr),
          ),
        ],
      ),
    );
  }

  /// Génère et imprime le relevé de compte
  Future<void> _generateAndPrintStatement() async {
    try {
      // Afficher un indicateur de chargement
      Get.dialog(
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('customers_generating_statement'.tr),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Récupérer les données du relevé depuis l'API
      final statementData = await _controller.getCustomerStatement(_customer!.id);

      if (statementData == null) {
        throw Exception('customers_statement_error'.tr);
      }

      // Générer le PDF
      final pdfBytes = await StatementPdfService.generateStatementPDF(statementData);

      // Fermer le dialogue de chargement
      Get.back();

      // Sauvegarder le PDF
      final filename = 'releve_compte_${_customer!.nom}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await StatementPdfService.saveAndOpenPDF(pdfBytes, filename);

      // Afficher le succès avec le chemin
      Get.snackbar(
        'success'.tr,
        'customers_statement_success'.trParams({'path': filePath}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      // Fermer le dialogue de chargement si ouvert
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'error'.tr,
        'customers_statement_generation_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
