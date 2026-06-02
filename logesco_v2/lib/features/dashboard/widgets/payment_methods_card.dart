import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Widget pour afficher la répartition des méthodes de paiement
class PaymentMethodsCard extends StatelessWidget {
  final double cashAmount;
  final double creditAmount;
  final bool isLoading;

  const PaymentMethodsCard({
    super.key,
    required this.cashAmount,
    required this.creditAmount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 0,
    );

    final totalAmount = cashAmount + creditAmount;
    final cashPercent = totalAmount > 0 ? (cashAmount / totalAmount * 100) : 0.0;
    final creditPercent = totalAmount > 0 ? (creditAmount / totalAmount * 100) : 0.0;

    if (isLoading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Text(
            '💳 ${'dashboard_payment_methods'.tr}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 20),

          // Comptant
          _buildPaymentMethodItem(
            icon: '💵',
            label: 'dashboard_cash'.tr,
            amount: cashAmount,
            percent: cashPercent,
            color: Colors.green,
            formatter: formatter,
          ),
          const SizedBox(height: 12),

          // Crédit
          _buildPaymentMethodItem(
            icon: '📋',
            label: 'dashboard_credit'.tr,
            amount: creditAmount,
            percent: creditPercent,
            color: Colors.blue,
            formatter: formatter,
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dashboard_total'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${formatter.format(totalAmount.toInt())} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required String icon,
    required String label,
    required double amount,
    required double percent,
    required Color color,
    required NumberFormat formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatter.format(amount.toInt())} FCFA',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}
