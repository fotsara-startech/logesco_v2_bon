import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../company_settings/controllers/company_settings_controller.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';

/// Dialog de validation d'une proforma → conversion en vente réelle
/// Reprend exactement le même UI que FinalizeSaleDialog du module de vente
class ValidateProformaDialog extends StatefulWidget {
  final ProformaInvoice proforma;
  final ProformaController controller;

  const ValidateProformaDialog({
    super.key,
    required this.proforma,
    required this.controller,
  });

  @override
  State<ValidateProformaDialog> createState() => _ValidateProformaDialogState();
}

class _ValidateProformaDialogState extends State<ValidateProformaDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amountPaid = 0.0;
  bool _tvaEnabled = false;
  final TextEditingController _amountController = TextEditingController();

  double get _baseAmount => widget.proforma.sousTotal;
  double get _tvaRate {
    if (!_tvaEnabled) return 0.0;
    try {
      final ctrl = Get.find<CompanySettingsController>();
      return ctrl.companyProfile?.tvaRate ?? 0.0;
    } catch (_) {
      return widget.proforma.tauxTva ?? 0.0;
    }
  }

  double get _tvaAmount => _baseAmount * _tvaRate / 100;
  double get _totalTTC => _baseAmount + _tvaAmount;

  double? get _configuredTvaRate {
    try {
      return Get.find<CompanySettingsController>().companyProfile?.tvaRate;
    } catch (_) {
      return widget.proforma.tauxTva;
    }
  }

  @override
  void initState() {
    super.initState();
    // Si la proforma a déjà de la TVA, activer le toggle
    if ((widget.proforma.montantTva) > 0 && widget.proforma.tauxTva != null) {
      _tvaEnabled = true;
    }
    _amountPaid = widget.proforma.montantTotal;
    _amountController.text = _amountPaid.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 620),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        _buildTotalSummary(),
                        const SizedBox(height: 16),
                        _buildTvaToggle(),
                        const SizedBox(height: 24),
                        _buildAmountPaidField(),
                        const SizedBox(height: 24),
                        _buildFinalSummary(),
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
                      child: GetBuilder<ProformaController>(
                        builder: (ctrl) => ElevatedButton.icon(
                          onPressed: ctrl.isValidating ? null : _validate,
                          icon: ctrl.isValidating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(ctrl.isValidating ? 'proforma_validating'.tr : 'proforma_confirm_validate'.tr),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildTotalSummary() {
    final total = _totalTTC;
    final tvaAmount = _tvaAmount;
    final customer = widget.proforma.client;
    final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
    final totalWithDebt = total + customerDebt;

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tvaEnabled ? 'Montant HT' : 'sales_order_amount'.tr,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_baseAmount.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: _tvaEnabled ? 20 : 28,
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
                    '${widget.proforma.items.length} article${widget.proforma.items.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),

            // Ligne TVA si activée
            if (_tvaEnabled) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'TVA (${_tvaRate % 1 == 0 ? _tvaRate.toStringAsFixed(0) : _tvaRate.toStringAsFixed(2)}%)',
                        style: TextStyle(fontSize: 14, color: Colors.orange[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '+${tvaAmount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Montant TTC', style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                  Text(
                    '${total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ],

            // Dette existante
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
                      Text('sales_existing_debt'.tr, style: TextStyle(fontSize: 14, color: Colors.red[700], fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(
                    '${customerDebt.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('sales_total_to_pay'.tr, style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                  Text(
                    '${totalWithDebt.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTvaToggle() {
    final tvaRate = _configuredTvaRate;
    if (tvaRate == null || tvaRate <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _tvaEnabled ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tvaEnabled ? Colors.orange.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: _tvaEnabled ? Colors.orange[700] : Colors.grey[600], size: 22),
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
                    color: _tvaEnabled ? Colors.orange[800] : Colors.grey[700],
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
            value: _tvaEnabled,
            onChanged: (value) {
              setState(() {
                _tvaEnabled = value;
                // Recalculer le montant suggéré
                final customer = widget.proforma.client;
                final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
                _amountPaid = _totalTTC + customerDebt;
                _amountController.text = _amountPaid.toStringAsFixed(0);
              });
            },
            activeThumbColor: Colors.orange[700],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountPaidField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'sales_amount_paid_by_customer'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'sales_amount_label'.tr,
            hintText: 'sales_enter_amount'.tr,
            suffixText: 'FCFA',
            suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          onChanged: (value) {
            setState(() {
              _amountPaid = double.tryParse(value) ?? 0.0;
            });
          },
          validator: (value) {
            final amount = double.tryParse(value ?? '') ?? 0.0;
            if (amount < 0) return 'sales_amount_negative_error'.tr;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFinalSummary() {
    final customer = widget.proforma.client;
    final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
    final totalWithDebt = _totalTTC + customerDebt;
    final difference = _amountPaid - totalWithDebt;

    if (_amountPaid == 0) return const SizedBox.shrink();

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
                style: TextStyle(fontSize: 16, color: color.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            '${difference.abs().toStringAsFixed(0)} FCFA',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _validate() async {
    if (!_formKey.currentState!.validate()) return;

    // Déterminer le mode de paiement selon le montant payé
    final customer = widget.proforma.client;
    final customerDebt = customer != null && customer.solde < 0 ? -customer.solde : 0.0;
    final totalWithDebt = _totalTTC + customerDebt;
    final remaining = totalWithDebt - _amountPaid;
    final modePaiement = remaining > 0 ? 'credit' : widget.proforma.modePaiement;

    if (!mounted) return;
    Navigator.of(context).pop();

    await widget.controller.validateProforma(
      widget.proforma,
      modePaiement: modePaiement,
      montantPaye: _amountPaid,
      montantTva: _tvaEnabled ? _tvaAmount : 0.0,
      tauxTva: _tvaEnabled ? _tvaRate : null,
    );
  }
}
