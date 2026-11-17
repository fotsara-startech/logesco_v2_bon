import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/constants/constants.dart';

/// Dialogue pour filtrer les comptes
class AccountsFilterDialog extends StatefulWidget {
  final Function({
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
  }) onApplyFilters;
  final VoidCallback onClearFilters;
  final double? currentSoldeMin;
  final double? currentSoldeMax;
  final bool? currentEnDepassement;

  const AccountsFilterDialog({
    super.key,
    required this.onApplyFilters,
    required this.onClearFilters,
    this.currentSoldeMin,
    this.currentSoldeMax,
    this.currentEnDepassement,
  });

  @override
  State<AccountsFilterDialog> createState() => _AccountsFilterDialogState();
}

class _AccountsFilterDialogState extends State<AccountsFilterDialog> {
  late TextEditingController _soldeMinController;
  late TextEditingController _soldeMaxController;
  bool? _enDepassement;

  @override
  void initState() {
    super.initState();
    _soldeMinController = TextEditingController(
      text: widget.currentSoldeMin?.toString() ?? '',
    );
    _soldeMaxController = TextEditingController(
      text: widget.currentSoldeMax?.toString() ?? '',
    );
    _enDepassement = widget.currentEnDepassement;
  }

  @override
  void dispose() {
    _soldeMinController.dispose();
    _soldeMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('accounts_filter_title'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtre par solde minimum
            TextField(
              controller: _soldeMinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'accounts_balance_min_label'.trParams({'currency': CurrencyConstants.defaultCurrency}),
                hintText: 'accounts_balance_min_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Filtre par solde maximum
            TextField(
              controller: _soldeMaxController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'accounts_balance_max_label'.trParams({'currency': CurrencyConstants.defaultCurrency}),
                hintText: 'accounts_balance_max_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Filtre par dépassement de crédit
            Text(
              'accounts_credit_status'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Column(
              children: [
                RadioListTile<bool?>(
                  title: Text('accounts_filter_all'.tr),
                  value: null,
                  groupValue: _enDepassement,
                  onChanged: (value) {
                    setState(() {
                      _enDepassement = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool?>(
                  title: Text('accounts_filter_overlimit_only'.tr),
                  value: true,
                  groupValue: _enDepassement,
                  onChanged: (value) {
                    setState(() {
                      _enDepassement = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool?>(
                  title: Text('accounts_filter_within_limits_only'.tr),
                  value: false,
                  groupValue: _enDepassement,
                  onChanged: (value) {
                    setState(() {
                      _enDepassement = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClearFilters();
            Navigator.of(context).pop();
          },
          child: Text('stock_clear'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: Text('common_apply'.tr),
        ),
      ],
    );
  }

  void _applyFilters() {
    double? soldeMin;
    double? soldeMax;

    // Valider et parser le solde minimum
    if (_soldeMinController.text.isNotEmpty) {
      soldeMin = double.tryParse(_soldeMinController.text);
      if (soldeMin == null) {
        _showErrorSnackBar('accounts_balance_min_invalid'.tr);
        return;
      }
    }

    // Valider et parser le solde maximum
    if (_soldeMaxController.text.isNotEmpty) {
      soldeMax = double.tryParse(_soldeMaxController.text);
      if (soldeMax == null) {
        _showErrorSnackBar('accounts_balance_max_invalid'.tr);
        return;
      }
    }

    // Vérifier que le solde minimum n'est pas supérieur au solde maximum
    if (soldeMin != null && soldeMax != null && soldeMin > soldeMax) {
      _showErrorSnackBar('accounts_balance_min_exceeds_max'.tr);
      return;
    }

    // Appliquer les filtres
    widget.onApplyFilters(
      soldeMin: soldeMin,
      soldeMax: soldeMax,
      enDepassement: _enDepassement,
    );

    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
