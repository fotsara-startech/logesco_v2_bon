import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import '../models/supplier.dart';
import '../controllers/supplier_controller.dart';
import '../widgets/unpaid_procurements_selector_dialog.dart';
import '../services/supplier_statement_pdf_service.dart';
import '../../financial_movements/controllers/financial_movement_controller.dart';

/// Vue du compte fournisseur
///
/// Affiche le solde du compte et l'historique des transactions
/// Permet de payer les dettes fournisseurs
class SupplierAccountView extends StatefulWidget {
  const SupplierAccountView({super.key});

  @override
  State<SupplierAccountView> createState() => _SupplierAccountViewState();
}

class _SupplierAccountViewState extends State<SupplierAccountView> {
  final SupplierController _controller = Get.find<SupplierController>();
  Supplier? _supplier;

  @override
  void initState() {
    super.initState();
    _supplier = Get.arguments as Supplier?;
    if (_supplier != null) {
      // Utiliser WidgetsBinding pour charger après la construction
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTransactions();
      });
    }
  }

  Future<void> _loadTransactions() async {
    await _controller.loadSupplierTransactions(_supplier!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_supplier == null) {
      return Scaffold(
        appBar: AppBar(title: Text('error'.tr)),
        body: Center(child: Text('suppliers_not_found'.tr)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('suppliers_account_of'.trParams({'name': _supplier!.nom})),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'suppliers_refresh_button'.tr,
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
    if (_controller.supplierTransactions.isNotEmpty) {
      solde = _controller.supplierTransactions.first.soldeApres;
    }

    // Pour les fournisseurs: solde POSITIF = on leur doit de l'argent (dette)
    // C'est l'inverse des clients!
    final bool aDette = solde > 0;
    final double montantDette = aDette ? solde : 0.0;
    final double avancePayee = !aDette && solde < 0 ? -solde : 0.0;

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
            'suppliers_account_balance_title'.tr,
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
                  'suppliers_to_pay'.tr,
                  '${montantDette.toStringAsFixed(0)} FCFA',
                  Icons.warning,
                  Colors.white.withOpacity(0.9),
                )
              else if (avancePayee > 0)
                _buildSummaryCard(
                  'suppliers_advance_paid'.tr,
                  '${avancePayee.toStringAsFixed(0)} FCFA',
                  Icons.account_balance_wallet,
                  Colors.white.withOpacity(0.9),
                )
              else
                _buildSummaryCard(
                  'suppliers_balanced'.tr,
                  '0 FCFA',
                  Icons.check_circle,
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
                  label: Text('suppliers_pay_supplier'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade700,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(0),
                  icon: const Icon(Icons.payment),
                  label: Text('suppliers_make_payment_button'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _printStatement,
                icon: const Icon(Icons.print),
                label: Text('suppliers_print_button'.tr),
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
      if (_controller.supplierTransactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'suppliers_no_transactions'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.supplierTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _controller.supplierTransactions[index];
          return _buildTransactionItem(transaction);
        },
      );
    });
  }

  Widget _buildTransactionItem(SupplierTransaction transaction) {
    final bool isCredit = transaction.isCredit;
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
          transaction.typeTransactionDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null) Text(transaction.description!),
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
              'suppliers_balance_after'.trParams({'amount': transaction.soldeApres.toStringAsFixed(0)}),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Affiche le dialogue de paiement
  void _showPaymentDialog(double montantDette) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    UnpaidProcurement? selectedProcurement;
    bool createFinancialMovement = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('suppliers_payment_dialog_title'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (montantDette > 0)
                  Text(
                    'suppliers_amount_to_pay_label'.trParams({'amount': montantDette.toStringAsFixed(0)}),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  )
                else
                  Text(
                    'suppliers_no_debt'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                const SizedBox(height: 16),

                // Sélection de commande (OBLIGATOIRE)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'suppliers_must_select_order_message'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => UnpaidProcurementsSelectorDialog(
                              supplierId: _supplier!.id,
                              onProcurementSelected: (procurement, montant) {
                                Navigator.pop(context, {
                                  'procurement': procurement,
                                  'montant': montant,
                                });
                              },
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              selectedProcurement = result['procurement'] as UnpaidProcurement;
                              amountController.text = (result['montant'] as double).toStringAsFixed(0);
                              descriptionController.text = 'suppliers_payment_for_order'.trParams({'reference': selectedProcurement!.reference});
                            });
                          }
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: Text(selectedProcurement == null ? 'suppliers_select_order'.tr : 'suppliers_order_reference'.trParams({'reference': selectedProcurement!.reference})),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                if (selectedProcurement != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'suppliers_order_reference'.trParams({'reference': selectedProcurement!.reference}),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('suppliers_order_info_date'.trParams({'date': selectedProcurement!.dateCommandeFormatted})),
                        Text('suppliers_order_info_total'.trParams({'amount': selectedProcurement!.montantTotalFormatted})),
                        Text('suppliers_order_info_paid'.trParams({'amount': selectedProcurement!.montantPayeFormatted})),
                        Text(
                          'suppliers_order_info_remaining'.trParams({'amount': selectedProcurement!.montantRestantFormatted}),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'suppliers_payment_amount_label'.tr,
                      suffixText: 'FCFA',
                      border: const OutlineInputBorder(),
                      helperText: 'suppliers_partial_payment_hint'.tr,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'suppliers_description_optional'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Option mouvement financier
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          value: createFinancialMovement,
                          onChanged: (value) {
                            setState(() {
                              createFinancialMovement = value ?? false;
                            });
                          },
                          title: Text('suppliers_create_financial_movement'.tr),
                          subtitle: Text('suppliers_financial_movement_subtitle'.tr),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (createFinancialMovement) ...[
                          const Divider(),
                          Row(
                            children: [
                              Icon(Icons.warning_amber, size: 20, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'suppliers_financial_movement_warning'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('suppliers_cancel'.tr),
            ),
            ElevatedButton.icon(
              onPressed: selectedProcurement == null
                  ? null
                  : () {
                      print('🔵 [Dialog] Bouton "Confirmer le paiement" cliqué');
                      print('  - selectedProcurement: ${selectedProcurement?.reference}');
                      print('  - amountController.text: ${amountController.text}');
                      print('  - createFinancialMovement: $createFinancialMovement');

                      print('✅ [Dialog] Validation OK, appel de _processPayment');
                      _processPayment(
                        amountController.text,
                        descriptionController.text,
                        selectedProcurement!,
                        createFinancialMovement,
                      );
                    },
              icon: const Icon(Icons.check),
              label: Text('suppliers_confirm_payment'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Traite le paiement au fournisseur
  Future<void> _processPayment(
    String amountText,
    String description,
    UnpaidProcurement selectedProcurement,
    bool createFinancialMovement,
  ) async {
    print('🔵 [_processPayment] Début du traitement');
    print('  - amountText: $amountText');
    print('  - description: $description');
    print('  - selectedProcurement: ${selectedProcurement.reference}');
    print('  - createFinancialMovement: $createFinancialMovement');

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      print('❌ [_processPayment] Montant invalide');
      Get.snackbar(
        'suppliers_error'.tr,
        'suppliers_invalid_amount'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    print('✅ [_processPayment] Montant valide: $amount');
    Navigator.of(context).pop(); // Fermer le dialogue

    print('🎯 [_processPayment] Appel paySupplierForProcurement');
    print('  - supplierId: ${_supplier!.id}');
    print('  - amount: $amount');
    print('  - procurementId: ${selectedProcurement.id}');
    print('  - createFinancialMovement: $createFinancialMovement');

    final success = await _controller.paySupplierForProcurement(
      _supplier!.id,
      amount,
      selectedProcurement.id,
      description: description.isEmpty ? 'suppliers_payment_for_order'.trParams({'reference': selectedProcurement.reference}) : description,
      createFinancialMovement: createFinancialMovement,
    );

    print('📊 [_processPayment] Résultat paySupplierForProcurement: $success');

    if (success) {
      print('✅ [_processPayment] Paiement réussi, rechargement des transactions');

      // Recharger les transactions du fournisseur
      await _loadTransactions();

      // CORRECTION: Invalider le cache des mouvements financiers si un mouvement a été créé
      if (createFinancialMovement) {
        print('🔄 [_processPayment] Invalidation du cache des mouvements financiers');
        try {
          final financialController = Get.find<FinancialMovementController>();
          await financialController.refreshMovements();
          print('✅ [_processPayment] Cache des mouvements financiers rafraîchi');
        } catch (e) {
          print('⚠️ [_processPayment] Erreur lors du rafraîchissement des mouvements: $e');
          // Ne pas bloquer le flux si le contrôleur n'est pas trouvé
        }
      }
    } else {
      print('❌ [_processPayment] Paiement échoué');
    }
  }

  /// Imprime le relevé de compte fournisseur
  Future<void> _printStatement() async {
    try {
      print('🖨️ Début impression relevé fournisseur ${_supplier!.id}');

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
                  Text('suppliers_generating_statement'.tr),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Récupérer les données du relevé
      final statementData = await _controller.getSupplierStatement(_supplier!.id);

      if (statementData == null) {
        Get.back(); // Fermer le dialogue de chargement
        Get.snackbar(
          'suppliers_error'.tr,
          'suppliers_statement_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      print('✅ Données du relevé récupérées');

      // Générer le PDF
      final pdfBytes = await SupplierStatementPdfService.generateStatementPDF(statementData);
      print('✅ PDF généré (${pdfBytes.length} bytes)');

      // Sauvegarder et ouvrir le PDF
      final filename = 'releve_fournisseur_${_supplier!.nom.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await SupplierStatementPdfService.saveAndOpenPDF(pdfBytes, filename);
      print('✅ PDF sauvegardé: $filePath');

      Get.back(); // Fermer le dialogue de chargement

      // Ouvrir le PDF
      await OpenFile.open(filePath);

      Get.snackbar(
        'common_success'.tr,
        'suppliers_statement_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      print('❌ Erreur impression relevé: $e');
      Get.back(); // Fermer le dialogue de chargement si ouvert

      Get.snackbar(
        'suppliers_error'.tr,
        'suppliers_statement_generation_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
