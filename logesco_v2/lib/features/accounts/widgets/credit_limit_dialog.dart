import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../../../shared/constants/constants.dart';

/// Dialogue pour modifier la limite de crédit
class CreditLimitDialog extends StatefulWidget {
  final bool isClient;
  final int accountId;
  final double currentLimit;
  final String accountName;

  const CreditLimitDialog({
    super.key,
    required this.isClient,
    required this.accountId,
    required this.currentLimit,
    required this.accountName,
  });

  @override
  State<CreditLimitDialog> createState() => _CreditLimitDialogState();
}

class _CreditLimitDialogState extends State<CreditLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('accounts_edit_credit_limit_title'.tr),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du compte
            Text(
              widget.isClient
                  ? 'accounts_account_name_client'.trParams({'name': widget.accountName})
                  : 'accounts_account_name_supplier'.trParams({'name': widget.accountName}),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Limite actuelle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'accounts_current_limit'.trParams({'amount': CurrencyConstants.formatAmount(widget.currentLimit)}),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nouvelle limite
            TextFormField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'accounts_new_credit_limit_label'.trParams({'currency': CurrencyConstants.defaultCurrency}),
                hintText: 'accounts_credit_limit_hint'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'accounts_credit_limit_required'.tr;
                }
                final limit = double.tryParse(value);
                if (limit == null || limit < 0) {
                  return 'accounts_credit_limit_invalid'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Avertissement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'accounts_credit_limit_warning'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('common_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCreditLimit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('edit'.tr),
        ),
      ],
    );
  }

  /// Met à jour la limite de crédit
  Future<void> _updateCreditLimit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newLimit = double.parse(_limitController.text);

    // Vérifier si la limite a changé
    if (newLimit == widget.currentLimit) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = Get.find<AccountController>();

      if (widget.isClient) {
        await controller.updateLimiteCreditClient(widget.accountId, newLimit);
      } else {
        await controller.updateLimiteCreditFournisseur(widget.accountId, newLimit);
      }

      // Fermer le dialogue
      Navigator.of(context).pop();
    } catch (e) {
      // L'erreur est déjà gérée dans le contrôleur
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
