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
      title: Text('customers_select_sale'.tr),
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
                  ? SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('accounts_no_unpaid_sales'.tr),
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
                                  labelText: 'sales_amount_to_pay'.tr,
                                  suffixText: 'FCFA',
                                  helperText: 'accounts_max_amount'.trParams({'amount': _selectedSale!.montantRestantFormatted}),
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
          child: Text('common_cancel'.tr),
        ),
        if (_selectedSale != null)
          ElevatedButton(
            onPressed: _validateAndPay,
            child: Text('quick_billing_step_pay'.tr),
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
          'accounts_sale_reference'.trParams({'reference': sale.reference}),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('customers_sale_date'.trParams({'date': sale.dateVenteFormatted})),
            Text('accounts_articles_label'.trParams({'count': '${sale.nombreArticles}'})),
            const Divider(),
            Text('customers_sale_total'.trParams({'amount': sale.montantTotalFormatted})),
            Text('customers_sale_paid'.trParams({'amount': sale.montantPayeFormatted})),
            Text(
              'customers_sale_remaining'.trParams({'amount': sale.montantRestantFormatted}),
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
    print('');

    final montant = double.tryParse(_montantController.text);
    print('  - Montant saisi: ${_montantController.text}');
    print('  - Montant parsé: $montant');

    if (montant == null || montant <= 0) {
      print(' [UnpaidSalesSelectorDialog] Montant invalide');
      Get.snackbar(
        'error'.tr,
        'accounts_amount_invalid'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (montant > _selectedSale!.montantRestant) {
      print(' [UnpaidSalesSelectorDialog] Montant dépasse le reste à payer');
      Get.snackbar(
        'error'.tr,
        'accounts_amount_exceeds_remaining'.trParams({'amount': _selectedSale!.montantRestantFormatted}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    print(' [UnpaidSalesSelectorDialog] Validation OK, appel du callback');
    print('  - Vente: ${_selectedSale!.reference}');
    print('  - Montant: $montant');

    // Appeler le callback qui fermera le dialog avec les données
    widget.onSaleSelected(_selectedSale!, montant);
  }
}
