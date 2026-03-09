import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/views/receipt_preview_page.dart';

/// Dialog simplifié pour finaliser la vente
/// Contient UNIQUEMENT les informations de paiement
/// Les informations client et antidatage sont gérées sur la page principale
class FinalizeSaleDialog extends StatefulWidget {
  const FinalizeSaleDialog({super.key});

  @override
  State<FinalizeSaleDialog> createState() => _FinalizeSaleDialogState();
}

class _FinalizeSaleDialogState extends State<FinalizeSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amountPaid = 0.0;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final salesController = Get.find<SalesController>();
    _amountPaid = salesController.cartSubtotal;
    _amountController.text = _amountPaid.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesController = Get.find<SalesController>();

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    const Icon(Icons.payment, size: 28, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Paiement',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Contenu scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Résumé du montant total
                        _buildTotalSummary(salesController),

                        const SizedBox(height: 24),

                        // Montant payé
                        _buildAmountPaidField(salesController),

                        const SizedBox(height: 16),

                        // Boutons rapides pour montant
                        _buildQuickAmountButtons(salesController),

                        const SizedBox(height: 24),

                        // Résumé final (monnaie/reste)
                        _buildFinalSummary(salesController),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(() => ElevatedButton.icon(
                            onPressed: salesController.isCreating ? null : _finalizeSale,
                            icon: salesController.isCreating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(salesController.isCreating ? 'sales_creating'.tr : 'confirm'.tr),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSummary(SalesController salesController) {
    return Obx(() {
      final total = salesController.cartSubtotal;
      final itemCount = salesController.cartItems.length;
      final customer = salesController.selectedCustomer;
      final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
      final totalWithDebt = total + customerDebt;

      return Card(
        color: Colors.blue.shade50,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Montant de la commande actuelle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'sales_order_amount'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$itemCount article${itemCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              // Afficher la dette existante si présente
              if (customerDebt > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'sales_existing_debt'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${customerDebt.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'sales_total_to_pay'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalWithDebt.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAmountPaidField(SalesController salesController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'sales_amount_paid_by_customer'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'sales_amount_label'.tr,
            hintText: 'sales_enter_amount'.tr,
            suffixText: 'FCFA',
            suffixStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (value) {
            setState(() {
              _amountPaid = double.tryParse(value) ?? 0.0;
            });
          },
          validator: (value) {
            final amount = double.tryParse(value ?? '') ?? 0.0;
            if (amount < 0) {
              return 'sales_amount_negative_error'.tr;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountButtons(SalesController salesController) {
    return Obx(() {
      final total = salesController.cartSubtotal;
      final customer = salesController.selectedCustomer;
      final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
      final totalWithDebt = total + customerDebt;
      final suggestions = _getAmountSuggestions(totalWithDebt);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'sales_quick_amounts'.tr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Bouton "Montant exact"
              _buildQuickButton(
                label: 'sales_exact_amount'.tr,
                amount: totalWithDebt,
                isExact: true,
              ),
              // Autres suggestions
              ...suggestions.map((amount) => _buildQuickButton(
                    label: '${(amount / 1000).toStringAsFixed(0)}k',
                    amount: amount.toDouble(),
                  )),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildQuickButton({required String label, required double amount, bool isExact = false}) {
    final isSelected = _amountPaid == amount;

    return InkWell(
      onTap: () {
        setState(() {
          _amountPaid = amount;
          _amountController.text = amount.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : (isExact ? Colors.green[50] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : (isExact ? Colors.green[300]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isExact ? Colors.green[700] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalSummary(SalesController salesController) {
    return Obx(() {
      final total = salesController.cartSubtotal;
      final customer = salesController.selectedCustomer;
      final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
      final totalWithDebt = total + customerDebt;
      final difference = _amountPaid - totalWithDebt;

      if (_amountPaid == 0) {
        return const SizedBox.shrink();
      }

      final isChange = difference >= 0;
      final color = isChange ? Colors.green : Colors.orange;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isChange ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                  color: color.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isChange ? 'sales_change_to_return'.tr : 'sales_remaining_to_pay'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: color.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '${difference.abs().toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      );
    });
  }

  List<int> _getAmountSuggestions(double total) {
    final roundedTotal = (total / 1000).ceil() * 1000;
    final suggestions = <int>[];

    // Ajouter des suggestions intelligentes
    if (roundedTotal > total) suggestions.add(roundedTotal);
    suggestions.add(roundedTotal + 1000);
    suggestions.add(roundedTotal + 2000);
    suggestions.add(roundedTotal + 5000);

    return suggestions.take(4).toList();
  }

  Future<void> _finalizeSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final salesController = Get.find<SalesController>();
    final total = salesController.cartSubtotal;
    final customer = salesController.selectedCustomer;
    final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
    final totalWithDebt = total + customerDebt;
    final remaining = totalWithDebt - _amountPaid;

    // Validation : paiement partiel nécessite un client
    if (remaining > 0 && customer == null) {
      Get.snackbar(
        'sales_customer_required'.tr,
        'sales_customer_required_partial'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // Confirmation pour paiement partiel
    if (remaining > 0 && customer != null) {
      final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text('sales_partial_payment'.tr),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sales_partial_payment_detail'.trParams({'customer': customer.nomComplet, 'paid': _amountPaid.toStringAsFixed(0), 'total': totalWithDebt.toStringAsFixed(0)}),
                  ),
                  const SizedBox(height: 16),
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
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'sales_account_impact'.tr,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (customerDebt > 0) Text('• ${'sales_current_debt'.tr}: ${customerDebt.toStringAsFixed(0)} FCFA'),
                        Text('• ${'sales_new_order'.tr}: ${total.toStringAsFixed(0)} FCFA'),
                        Text('• ${'sales_amount_paid'.tr}: ${_amountPaid.toStringAsFixed(0)} FCFA'),
                        const Divider(height: 16),
                        Text(
                          '• ${'sales_final_debt'.tr}: ${remaining.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text('confirm'.tr),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;
    }

    // Configurer les paramètres de vente
    print('=== DEBUG FINALIZE DIALOG ===');
    print('Montant payé dans dialog: $_amountPaid');
    print('Total avec dette: $totalWithDebt');
    print('Reste à payer: $remaining');
    print('Mode paiement: ${remaining > 0 ? 'credit' : 'comptant'}');
    print('============================');

    // Définir le montant payé EN PREMIER pour éviter qu'il soit écrasé
    salesController.setAmountPaid(_amountPaid);
    salesController.setPaymentMode(remaining > 0 ? 'credit' : 'comptant');
    salesController.setDiscount(0.0);

    // Créer la vente
    final success = await salesController.createSale();

    if (success) {
      Navigator.of(context).pop(); // Fermer le dialog
      _showPrintReceiptDialog();
      Get.back(); // Retour à la page précédente
    } else {
      Get.snackbar(
        'error'.tr,
        'sales_cannot_create_sale'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _showPrintReceiptDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text('sales_sale_created'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('sales_receipt_printing'.tr),
          ],
        ),
      ),
    );

    // Imprimer automatiquement
    Future.delayed(const Duration(milliseconds: 300), () {
      _printReceiptDirect();
    });
  }

  Future<void> _printReceiptDirect() async {
    try {
      final salesController = Get.find<SalesController>();

      if (salesController.lastCreatedSale == null) {
        Get.back();
        Get.snackbar(
          'error'.tr,
          'sales_no_sale_for_print'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!Get.isRegistered<PrintingController>()) {
        Get.put(PrintingController());
      }

      final printingController = Get.find<PrintingController>();
      final format = salesController.selectedReceiptFormat;

      printingController.setSelectedFormat(format);
      final success = await printingController.generateReceiptForSale(
        salesController.lastCreatedSale!.id.toString(),
        format: format,
        companyProfile: salesController.companyProfile,
      );

      if (success && printingController.currentReceipt != null) {
        final receipt = printingController.currentReceipt!;

        Get.back(); // Fermer le dialog

        // Naviguer vers la prévisualisation
        Get.to(
          () => const ReceiptPreviewPage(),
          arguments: receipt,
        );

        Get.snackbar(
          'success'.tr,
          'sales_receipt_generated'.trParams({'number': receipt.saleNumber}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.back();
        Get.snackbar(
          'error'.tr,
          'sales_cannot_generate_receipt'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        '${'error'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
