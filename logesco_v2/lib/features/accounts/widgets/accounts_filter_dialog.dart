import 'package:flutter/material.dart';
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
      title: const Text('Filtrer les comptes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtre par solde minimum
            TextField(
              controller: _soldeMinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Solde minimum (${CurrencyConstants.defaultCurrency})',
                hintText: 'Ex: 100',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Filtre par solde maximum
            TextField(
              controller: _soldeMaxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Solde maximum (${CurrencyConstants.defaultCurrency})',
                hintText: 'Ex: 1000',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Filtre par dépassement de crédit
            const Text(
              'Statut du crédit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Column(
              children: [
                RadioListTile<bool?>(
                  title: const Text('Tous les comptes'),
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
                  title: const Text('En dépassement uniquement'),
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
                  title: const Text('Dans les limites uniquement'),
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
          child: const Text('Effacer'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: const Text('Appliquer'),
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
        _showErrorSnackBar('Le solde minimum doit être un nombre valide');
        return;
      }
    }

    // Valider et parser le solde maximum
    if (_soldeMaxController.text.isNotEmpty) {
      soldeMax = double.tryParse(_soldeMaxController.text);
      if (soldeMax == null) {
        _showErrorSnackBar('Le solde maximum doit être un nombre valide');
        return;
      }
    }

    // Vérifier que le solde minimum n'est pas supérieur au solde maximum
    if (soldeMin != null && soldeMax != null && soldeMin > soldeMax) {
      _showErrorSnackBar('Le solde minimum ne peut pas être supérieur au solde maximum');
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
