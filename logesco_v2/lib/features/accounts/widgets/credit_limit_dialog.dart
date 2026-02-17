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
      title: Text('Modifier la limite de crédit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du compte
            Text(
              widget.isClient ? 'Client: ${widget.accountName}' : 'Fournisseur: ${widget.accountName}',
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
                    'Limite actuelle: ${CurrencyConstants.formatAmount(widget.currentLimit)}',
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
              decoration: const InputDecoration(
                labelText: 'Nouvelle limite de crédit (${CurrencyConstants.defaultCurrency})',
                hintText: 'Ex: 5000.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir une limite de crédit';
                }
                final limit = double.tryParse(value);
                if (limit == null || limit < 0) {
                  return 'Veuillez saisir une limite valide (≥ 0)';
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
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La modification de la limite de crédit prendra effet immédiatement.',
                      style: TextStyle(
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
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCreditLimit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Modifier'),
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
