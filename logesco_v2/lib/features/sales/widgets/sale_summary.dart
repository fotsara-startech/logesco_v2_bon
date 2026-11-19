import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../customers/models/customer.dart';
import '../../customers/controllers/customer_controller.dart';
import '../controllers/sales_controller.dart';

class SaleSummary extends StatelessWidget {
  final Function(Customer?) onCustomerChanged;
  final Function(String) onPaymentModeChanged;
  final Function(double) onDiscountChanged;
  final Function(double) onAmountPaidChanged;
  final VoidCallback onCreateSale;

  const SaleSummary({
    super.key,
    required this.onCustomerChanged,
    required this.onPaymentModeChanged,
    required this.onDiscountChanged,
    required this.onAmountPaidChanged,
    required this.onCreateSale,
  });

  @override
  Widget build(BuildContext context) {
    final salesController = Get.find<SalesController>();
    final customersController = Get.find<CustomerController>();

    return Obx(() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du client
            DropdownButtonFormField<Customer?>(
              decoration: InputDecoration(
                labelText: 'sales_customer_optional'.tr,
                border: OutlineInputBorder(),
              ),
              value: salesController.selectedCustomer,
              items: [
                DropdownMenuItem<Customer?>(
                  value: null,
                  child: Text('sales_sale_without_customer'.tr),
                ),
                ...customersController.customers.map(
                  (customer) => DropdownMenuItem<Customer?>(
                    value: customer,
                    child: Text('${customer.nom} ${customer.prenom ?? ''}'),
                  ),
                ),
              ],
              onChanged: onCustomerChanged,
            ),

            const SizedBox(height: 16),

            // Mode de paiement
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'suppliers_payment_method'.tr,
                border: OutlineInputBorder(),
              ),
              value: salesController.paymentMode,
              items: [
                DropdownMenuItem(value: 'comptant', child: Text('sales_payment_cash_mode'.tr)),
                DropdownMenuItem(value: 'credit', child: Text('sales_payment_credit_mode'.tr)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPaymentModeChanged(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Remise
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Remise',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: salesController.discount.toStringAsFixed(2),
              onChanged: (value) {
                final discount = double.tryParse(value);
                if (discount != null && discount >= 0) {
                  onDiscountChanged(discount);
                }
              },
            ),

            const SizedBox(height: 16),

            // Montant payé
            TextFormField(
              decoration: InputDecoration(
                labelText: 'sales_amount_paid'.tr,
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: salesController.amountPaid.toStringAsFixed(2),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount >= 0) {
                  onAmountPaidChanged(amount);
                }
              },
            ),

            const SizedBox(height: 16),

            // Résumé des montants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow('lbl_subtotal_colon'.tr, '${salesController.cartSubtotal.toStringAsFixed(0)} FCFA'),
                    if (salesController.discount > 0) ...[
                      _buildSummaryRow('lbl_discount_colon'.tr, '-${salesController.discount.toStringAsFixed(0)} FCFA', color: Colors.green),
                    ],
                    const Divider(),
                    _buildSummaryRow(
                      'plain_total_colon'.tr,
                      '${salesController.cartTotal.toStringAsFixed(0)} FCFA',
                      isTotal: true,
                    ),
                    _buildSummaryRow('sales_summary_paid'.tr, '${salesController.amountPaid.toStringAsFixed(0)} FCFA'),
                    if (salesController.remainingAmount != 0) ...[
                      _buildSummaryRow(
                        salesController.remainingAmount > 0 ? 'Restant:' : 'Rendu:',
                        '${salesController.remainingAmount.abs().toStringAsFixed(0)} FCFA',
                        color: salesController.remainingAmount > 0 ? Colors.orange : Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton de validation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: salesController.cartItems.isNotEmpty && !salesController.isCreating ? onCreateSale : null,
                icon: salesController.isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.point_of_sale),
                label: Text(salesController.isCreating ? 'sales_creating'.tr : 'sales_finalize_sale'.tr),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Validation des erreurs
            if (salesController.cartItems.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'sales_add_products_to_continue'.tr,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            if (salesController.paymentMode == 'credit' && salesController.selectedCustomer == null) ...[
              const SizedBox(height: 8),
              Text(
                'sales_select_customer_for_credit'.tr,
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
