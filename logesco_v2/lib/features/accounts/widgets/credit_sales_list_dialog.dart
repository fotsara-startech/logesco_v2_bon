import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/account_api_service.dart';

/// Dialogue de consultation (lecture seule) des ventes à crédit d'un client,
/// c'est-à-dire ses ventes encore partiellement ou totalement impayées
/// (`montantRestant > 0`). Contrairement à [UnpaidSalesSelectorDialog], ce
/// dialogue ne permet pas de sélectionner une vente pour la payer : il sert
/// uniquement à consulter la liste directement depuis le compte client.
class CreditSalesListDialog extends StatefulWidget {
  final int clientId;
  final String clientName;

  const CreditSalesListDialog({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CreditSalesListDialog> createState() => _CreditSalesListDialogState();
}

class _CreditSalesListDialogState extends State<CreditSalesListDialog> {
  List<UnpaidSale> _creditSales = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCreditSales();
  }

  Future<void> _loadCreditSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = Get.find<AccountService>();
      if (service is! AccountApiService) {
        throw Exception('Le service de comptes ne supporte pas cette fonctionnalité');
      }
      final sales = await service.getUnpaidSales(widget.clientId);
      if (mounted) {
        setState(() {
          _creditSales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les ventes à crédit: $e';
        });
      }
    }
  }

  double get _totalRestant => _creditSales.fold(0.0, (sum, s) => sum + s.montantRestant);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('accounts_credit_sales_title'.trParams({'name': widget.clientName})),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : _errorMessage != null
                ? SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                : _creditSales.isEmpty
                    ? SizedBox(
                        height: 100,
                        child: Center(child: Text('accounts_no_credit_sales'.tr)),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('accounts_credit_sales_count'.trParams({'count': '${_creditSales.length}'}), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text(
                                    '${_totalRestant.toStringAsFixed(0)} FCFA',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._creditSales.map(_buildSaleCard),
                          ],
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('close'.tr),
        ),
      ],
    );
  }

  Widget _buildSaleCard(UnpaidSale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('accounts_sale_reference'.trParams({'reference': sale.reference}), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sale.dateVenteFormatted, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text('accounts_articles_count'.trParams({'count': '${sale.nombreArticles}'}), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('customers_sale_total'.trParams({'amount': sale.montantTotalFormatted})),
                Text('customers_sale_paid'.trParams({'amount': sale.montantPayeFormatted})),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'accounts_remaining_to_pay'.trParams({'amount': sale.montantRestantFormatted}),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
