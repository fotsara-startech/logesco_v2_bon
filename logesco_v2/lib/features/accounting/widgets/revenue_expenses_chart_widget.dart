import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget de graphique revenus vs dépenses
class RevenueExpensesChartWidget extends StatelessWidget {
  final FinancialBalance balance;

  const RevenueExpensesChartWidget({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Revenus vs Dépenses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Graphique en barres simple
            _buildSimpleBarChart(),
            const SizedBox(height: 12), // Réduit de 16 à 12

            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Revenus', Colors.green.shade600, balance.totalRevenueFormatted),
                _buildLegendItem('Dépenses', Colors.red.shade600, balance.totalExpensesFormatted),
                _buildLegendItem('Bénéfice', balance.isProfitable ? Colors.blue.shade600 : Colors.orange.shade600, balance.netProfitFormatted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un graphique en barres simple
  Widget _buildSimpleBarChart() {
    final maxAmount = [balance.totalRevenue, balance.totalExpenses].reduce((a, b) => a > b ? a : b);
    final revenueHeight = maxAmount > 0 ? (balance.totalRevenue / maxAmount) * 100 : 0.0; // Réduit de 120 à 100
    final expensesHeight = maxAmount > 0 ? (balance.totalExpenses / maxAmount) * 100 : 0.0; // Réduit de 120 à 100

    return SizedBox(
      height: 120, // Réduit de 140 à 120
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar('Revenus', revenueHeight, Colors.green.shade600),
          _buildBar('Dépenses', expensesHeight, Colors.red.shade600),
          _buildBar(
            'Bénéfice',
            balance.netProfit > 0 ? (balance.netProfit / maxAmount) * 100 : 0.0, // Réduit de 120 à 100
            balance.isProfitable ? Colors.blue.shade600 : Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  /// Construit une barre du graphique
  Widget _buildBar(String label, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 60,
          height: height.clamp(10.0, 100.0), // Réduit de 120 à 100
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 4), // Réduit de 8 à 4
        Text(
          label,
          style: TextStyle(
            fontSize: 10, // Réduit de 12 à 10
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Construit un élément de légende
  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10, // Réduit de 11 à 10
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
