import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';

/// Dialog de validation d'une proforma → conversion en vente réelle
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
  late String _modePaiement;
  late double _montantPaye;
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _modePaiement = widget.proforma.modePaiement;
    _montantPaye = widget.proforma.montantTotal;
    _amountCtrl.text = _montantPaye.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final total = widget.proforma.montantTotal;
    final monnaie = _montantPaye - total;

    return Dialog(
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('proforma_validate_title'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(widget.proforma.numeroProforma, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24),

              // Résumé montant
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('proforma_total_to_pay'.tr, style: TextStyle(color: Colors.grey[700])),
                    Text(
                      '${fmt.format(total)} FCFA',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode de paiement
              Text('proforma_payment_mode'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _modePaiement,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: 'comptant', child: Text('proforma_cash'.tr)),
                  DropdownMenuItem(value: 'credit', child: Text('proforma_credit'.tr)),
                  DropdownMenuItem(value: 'mobile_money', child: Text('proforma_mobile_money'.tr)),
                  DropdownMenuItem(value: 'virement', child: Text('proforma_transfer'.tr)),
                ],
                onChanged: (v) => setState(() => _modePaiement = v ?? 'comptant'),
              ),
              const SizedBox(height: 16),

              // Montant payé
              Text('proforma_amount_paid'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixText: 'FCFA',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (v) => setState(() => _montantPaye = double.tryParse(v) ?? 0),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'proforma_amount_required'.tr;
                  if ((double.tryParse(v) ?? 0) <= 0) return 'proforma_amount_invalid'.tr;
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Monnaie / reste
              if (_montantPaye > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      monnaie >= 0 ? '${'proforma_change'.tr}: ${fmt.format(monnaie)} FCFA' : '${'proforma_remaining'.tr}: ${fmt.format(-monnaie)} FCFA',
                      style: TextStyle(
                        color: monnaie >= 0 ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              const Divider(),
              const SizedBox(height: 8),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GetBuilder<ProformaController>(
                      builder: (ctrl) => ElevatedButton.icon(
                        onPressed: ctrl.isValidating ? null : _validate,
                        icon: ctrl.isValidating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle),
                        label: Text(ctrl.isValidating ? 'proforma_validating'.tr : 'proforma_confirm_validate'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green[600],
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
    );
  }

  Future<void> _validate() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();
    await widget.controller.validateProforma(
      widget.proforma,
      modePaiement: _modePaiement,
      montantPaye: _montantPaye,
    );
  }
}
