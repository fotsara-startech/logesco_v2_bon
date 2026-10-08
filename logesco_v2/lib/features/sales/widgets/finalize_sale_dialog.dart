import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/sales_controller.dart';
import '../utils/post_sale_printing.dart';

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
    // Utiliser le total TTC si TVA activée, sinon le sous-total
    _amountPaid = salesController.cartTotalTTC;
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

    return Focus(
      autofocus: true,
      // Raccourcis clavier : Échap annule (miroir du bouton "Annuler"),
      // F9 confirme le paiement (miroir du bouton "Confirmer") — voir
      // le hint "F9: Paiement | Esc: Annuler" affiché sur la page de vente.
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.f9): () {
            if (!salesController.isCreating) _finalizeSale();
          },
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Écran large : récapitulatif à gauche, saisie à droite → tout est
              // visible d'un coup, sans défilement. Écran étroit (mobile) : une
              // seule colonne, qui ne défile qu'en dernier recours.
              final wide = constraints.maxWidth >= 640;
              final summary = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCustomerCard(salesController),
                  _buildTotalSummary(salesController),
                ],
              );
              final inputs = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTvaToggle(salesController),
                  const SizedBox(height: 12),
                  _buildAmountPaidField(salesController),
                  const SizedBox(height: 12),
                  _buildFinalSummary(salesController),
                ],
              );

              final body = wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 20),
                        Expanded(child: inputs),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [summary, const SizedBox(height: 12), inputs],
                      ),
                    );

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 820 : 500),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Contenu (Flexible : ne déborde jamais de l'écran)
                        Flexible(child: body),

                        const SizedBox(height: 16),

                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                                      padding: const EdgeInsets.symmetric(vertical: 14),
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
              );
            },
          ),
        ),
      ),
    );
  }

  /// Nom du client et état de son solde (dette / avance / à jour).
  /// solde < 0 = le client doit de l'argent ; solde > 0 = il a une avance.
  Widget _buildCustomerCard(SalesController salesController) {
    return Obx(() {
      final customer = salesController.selectedCustomer;
      if (customer == null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600], size: 22),
              const SizedBox(width: 10),
              Text('Aucun client sélectionné', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
        );
      }

      final solde = customer.solde;
      final MaterialColor color;
      final IconData icon;
      final String label;
      if (solde < 0) {
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        label = 'Dette : ${(-solde).toStringAsFixed(0)} FCFA';
      } else if (solde > 0) {
        color = Colors.green;
        icon = Icons.savings_outlined;
        label = 'Avance : ${solde.toStringAsFixed(0)} FCFA';
      } else {
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'Solde à jour';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: color.shade700, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.nomComplet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color.shade700),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Ligne label / montant du récapitulatif.
  Widget _summaryLine(String label, String value, {Color? color, bool strong = false, double size = 15, IconData? icon}) {
    final c = color ?? Colors.grey[800]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: c), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: strong ? 15 : 14, color: c, fontWeight: strong ? FontWeight.bold : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: c)),
      ],
    );
  }

  /// Récapitulatif : Montant HT → Remise → Net HT → TVA → Net à payer (TTC).
  /// La remise commerciale est accordée sur le HT et la TVA se calcule sur le
  /// net HT. Le panier est déjà calculé avec les prix remisés (= Net HT) ; on
  /// reconstitue le montant avant remise (prix catalogue) pour l'affichage.
  Widget _buildTotalSummary(SalesController salesController) {
    return Obx(() {
      final tvaEnabled = salesController.tvaEnabled;
      final tvaRate = salesController.tvaRate;
      final itemCount = salesController.cartItems.length;
      final customer = salesController.selectedCustomer;
      final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
      final net = salesController.cartTotalTTC;
      final totalWithDebt = net + customerDebt;

      // Remise accordée = écart prix catalogue / prix saisi, par ligne (HT)
      double remise = 0.0;
      for (final item in salesController.cartItems) {
        final diff = item.originalPrice - item.unitPrice;
        if (diff > 0) remise += diff * item.quantity;
      }
      final netHT = salesController.cartSubtotal;
      final montantHT = netHT + remise;
      String fmt(double v) => '${v.toStringAsFixed(0)} FCFA';

      return Card(
        color: Colors.blue.shade50,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '$itemCount article${itemCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 1. Montant HT (sans TVA : simple "Montant")
              _summaryLine(tvaEnabled ? 'Montant HT' : 'Montant', fmt(montantHT), size: 16),

              // 2. Remise
              if (remise > 0) ...[
                const SizedBox(height: 8),
                _summaryLine(
                  'Remise',
                  '-${remise.toStringAsFixed(0)} FCFA',
                  color: Colors.green[700],
                  icon: Icons.local_offer_outlined,
                  size: 16,
                ),
              ],

              if (tvaEnabled) ...[
                // 3. Net HT (affiché seulement s'il y a une remise, sinon identique au HT)
                if (remise > 0) ...[
                  const Divider(height: 20),
                  _summaryLine('Net HT', fmt(netHT), strong: true, size: 16),
                ],
                // 4. TVA sur le net HT
                const SizedBox(height: 8),
                _summaryLine(
                  'TVA (${tvaRate % 1 == 0 ? tvaRate.toStringAsFixed(0) : tvaRate.toStringAsFixed(2)}%)',
                  '+${salesController.tvaAmount.toStringAsFixed(0)} FCFA',
                  color: Colors.orange[700],
                  icon: Icons.receipt_long,
                  size: 16,
                ),
              ],

              // 5. Net à payer
              const Divider(height: 20),
              _summaryLine(tvaEnabled ? 'Net à payer (TTC)' : 'Net à payer', fmt(net), color: Colors.blue, strong: true, size: 26),

              // Dette existante du client (s'ajoute au net à payer)
              if (customerDebt > 0) ...[
                const Divider(height: 20),
                _summaryLine(
                  'sales_existing_debt'.tr,
                  fmt(customerDebt),
                  color: Colors.red[700],
                  icon: Icons.warning_amber_rounded,
                  size: 18,
                ),
                const SizedBox(height: 8),
                _summaryLine('sales_total_to_pay'.tr, fmt(totalWithDebt), color: Colors.deepOrange, strong: true, size: 28),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTvaToggle(SalesController salesController) {
    return Obx(() {
      final tvaRate = salesController.companyProfile?.tvaRate;
      if (tvaRate == null || tvaRate <= 0) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: salesController.tvaEnabled ? Colors.orange.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: salesController.tvaEnabled ? Colors.orange.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: salesController.tvaEnabled ? Colors.orange[700] : Colors.grey[600], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appliquer la TVA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: salesController.tvaEnabled ? Colors.orange[800] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Taux configuré : ${tvaRate % 1 == 0 ? tvaRate.toStringAsFixed(0) : tvaRate.toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: salesController.tvaEnabled,
              onChanged: (value) {
                salesController.setTvaEnabled(value);
                final newTotal = salesController.cartTotalTTC;
                final customer = salesController.selectedCustomer;
                final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
                setState(() {
                  _amountPaid = newTotal + customerDebt;
                  _amountController.text = _amountPaid.toStringAsFixed(0);
                });
              },
              activeColor: Colors.orange[700],
            ),
          ],
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
        const SizedBox(height: 8),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildFinalSummary(SalesController salesController) {
    return Obx(() {
      final total = salesController.cartTotalTTC;
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
        padding: const EdgeInsets.all(14),
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

  Future<void> _finalizeSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final salesController = Get.find<SalesController>();
    final total = salesController.cartTotalTTC;
    final customer = salesController.selectedCustomer;
    final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
    final totalWithDebt = total + customerDebt;
    final remaining = totalWithDebt - _amountPaid;

    // Validation : paiement partiel nécessite un client
    if (remaining > 0 && customer == null) {
      SnackbarHelper.warning(
        'sales_customer_required_partial'.tr,
        title: 'sales_customer_required'.tr,
        duration: const Duration(seconds: 3),
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
    // print('=== DEBUG FINALIZE DIALOG ===');
    // print('Montant payé dans dialog: $_amountPaid');
    // print('Total avec dette: $totalWithDebt');
    // print('Reste à payer: $remaining');
    // print('Mode paiement: ${remaining > 0 ? 'credit' : 'comptant'}');
    // print('============================');

    // Définir le montant payé EN PREMIER pour éviter qu'il soit écrasé
    salesController.setAmountPaid(_amountPaid);
    salesController.setPaymentMode(remaining > 0 ? 'credit' : 'comptant');
    salesController.setDiscount(0.0);

    // Créer la vente
    final success = await salesController.createSale();

    if (success) {
      Navigator.of(context).pop(); // Fermer le dialog
      handlePostSalePrinting(salesController);
    } else {
      SnackbarHelper.error('sales_cannot_create_sale'.tr, title: 'error'.tr, duration: const Duration(seconds: 3));
    }
  }
}
