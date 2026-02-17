import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/account_api_service.dart';

/// Dialog pour sélectionner une vente impayée à payer
class UnpaidSalesSelectorDialog extends StatefulWidget {
  final int clientId;
  final Function(UnpaidSale, double) onSaleSelected;

  const UnpaidSalesSelectorDialog({
    super.key,
    required this.clientId,
    required this.onSaleSelected,
  });

  @override
  State<UnpaidSalesSelectorDialog> createState() => _UnpaidSalesSelectorDialogState();
}

class _UnpaidSalesSelectorDialogState extends State<UnpaidSalesSelectorDialog> {
  List<UnpaidSale> _unpaidSales = [];
  UnpaidSale? _selectedSale;
  final _montantController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnpaidSales();
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _loadUnpaidSales() async {
    try {
      final service = Get.find<AccountService>();
      if (service is! AccountApiService) {
        throw Exception('Le service de comptes ne supporte pas cette fonctionnalité');
      }
      final apiService = service as AccountApiService;
      final sales = await apiService.getUnpaidSales(widget.clientId);
      if (mounted) {
        setState(() {
          _unpaidSales = sales;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les ventes impayées: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une vente à payer'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _errorMessage != null
              ? SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                )
              : _unpaidSales.isEmpty
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('Aucune vente impayée pour ce client'),
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ..._unpaidSales.map((sale) => _buildSaleCard(sale)),
                            if (_selectedSale != null) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _montantController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Montant à payer',
                                  suffixText: 'FCFA',
                                  helperText: 'Max: ${_selectedSale!.montantRestantFormatted}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (_selectedSale != null)
          ElevatedButton(
            onPressed: _validateAndPay,
            child: const Text('Payer'),
          ),
      ],
    );
  }

  Widget _buildSaleCard(UnpaidSale sale) {
    final isSelected = _selectedSale?.id == sale.id;

    return Card(
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<int>(
        value: sale.id,
        groupValue: _selectedSale?.id,
        onChanged: (value) {
          setState(() {
            _selectedSale = sale;
            _montantController.text = sale.montantRestant.toStringAsFixed(0);
          });
        },
        title: Text(
          'Vente #${sale.reference}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${sale.dateVenteFormatted}'),
            Text('Articles: ${sale.nombreArticles}'),
            const Divider(),
            Text('Total: ${sale.montantTotalFormatted}'),
            Text('Déjà payé: ${sale.montantPayeFormatted}'),
            Text(
              'Reste: ${sale.montantRestantFormatted}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndPay() {
    print('🔵 [UnpaidSalesSelectorDialog] _validateAndPay appelée');

    final montant = double.tryParse(_montantController.text);
    print('  - Montant saisi: ${_montantController.text}');
    print('  - Montant parsé: $montant');

    if (montant == null || montant <= 0) {
      print('❌ [UnpaidSalesSelectorDialog] Montant invalide');
      Get.snackbar(
        'Erreur',
        'Veuillez saisir un montant valide',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (montant > _selectedSale!.montantRestant) {
      print('❌ [UnpaidSalesSelectorDialog] Montant dépasse le reste à payer');
      Get.snackbar(
        'Erreur',
        'Le montant dépasse le reste à payer (${_selectedSale!.montantRestantFormatted})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    print('✅ [UnpaidSalesSelectorDialog] Validation OK, appel du callback');
    print('  - Vente: ${_selectedSale!.reference}');
    print('  - Montant: $montant');

    // Appeler le callback qui fermera le dialog avec les données
    widget.onSaleSelected(_selectedSale!, montant);
  }
}
