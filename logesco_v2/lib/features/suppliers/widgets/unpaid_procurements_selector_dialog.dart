import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import '../services/api_supplier_service.dart';

/// Dialog pour sélectionner une commande impayée à payer
class UnpaidProcurementsSelectorDialog extends StatefulWidget {
  final int supplierId;
  final Function(UnpaidProcurement, double) onProcurementSelected;

  const UnpaidProcurementsSelectorDialog({
    super.key,
    required this.supplierId,
    required this.onProcurementSelected,
  });

  @override
  State<UnpaidProcurementsSelectorDialog> createState() => _UnpaidProcurementsSelectorDialogState();
}

class _UnpaidProcurementsSelectorDialogState extends State<UnpaidProcurementsSelectorDialog> {
  List<UnpaidProcurement> _unpaidProcurements = [];
  UnpaidProcurement? _selectedProcurement;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnpaidProcurements();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUnpaidProcurements() async {
    try {
      final service = Get.find<SupplierService>();
      if (service is! ApiSupplierService) {
        throw Exception('Le service de fournisseurs ne supporte pas cette fonctionnalité');
      }
      final apiService = service;
      final procurements = await apiService.getUnpaidProcurements(widget.supplierId);
      if (mounted) {
        setState(() {
          _unpaidProcurements = procurements;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les commandes impayées: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('suppliers_select_order'.tr),
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
              : _unpaidProcurements.isEmpty
                  ? SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('suppliers_no_unpaid_orders'.tr),
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ..._unpaidProcurements.map((procurement) => _buildProcurementCard(procurement)),
                          ],
                        ),
                      ),
                    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('suppliers_form_cancel'.tr),
        ),
        if (_selectedProcurement != null)
          ElevatedButton(
            onPressed: _validateAndSelect,
            child: Text('suppliers_select'.tr),
          ),
      ],
    );
  }

  Widget _buildProcurementCard(UnpaidProcurement procurement) {
    final isSelected = _selectedProcurement?.id == procurement.id;

    return Card(
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<int>(
        value: procurement.id,
        groupValue: _selectedProcurement?.id,
        onChanged: (value) {
          setState(() {
            _selectedProcurement = procurement;
          });
        },
        title: Text(
          'suppliers_order_reference_label'.trParams({'reference': procurement.reference}),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('suppliers_order_date_label'.trParams({'date': procurement.dateCommandeFormatted})),
            Text('suppliers_order_items_label'.trParams({'count': procurement.nombreArticles.toString()})),
            const Divider(),
            Text('suppliers_order_total_label'.trParams({'amount': procurement.montantTotalFormatted})),
            Text('suppliers_order_paid_label'.trParams({'amount': procurement.montantPayeFormatted})),
            Text(
              'suppliers_order_remaining_label'.trParams({'amount': procurement.montantRestantFormatted}),
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

  void _validateAndSelect() {
    print('🔵 [UnpaidProcurementsSelectorDialog] _validateAndSelect appelée');
    print('  - Commande sélectionnée: ${_selectedProcurement!.reference}');
    print('  - Montant restant: ${_selectedProcurement!.montantRestant}');

    // Retourner la commande sélectionnée avec le montant restant par défaut
    widget.onProcurementSelected(_selectedProcurement!, _selectedProcurement!.montantRestant);
  }
}
