import 'package:flutter/material.dart';
import '../models/activity_report.dart';

/// Widget pour afficher les mouvements financiers
class FinancialMovementsWidget extends StatelessWidget {
  final FinancialMovementsData financialData;

  const FinancialMovementsWidget({
    super.key,
    required this.financialData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                const Text('Mouvements Financiers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildMovementItem('Entrées', financialData.totalIncomeFormatted, Icons.arrow_downward, Colors.green.shade600)),
                  Container(width: 1, height: 50, color: Colors.blue.shade200),
                  Expanded(child: _buildMovementItem('Sorties', financialData.totalExpensesFormatted, Icons.arrow_upward, Colors.red.shade600)),
                  Container(width: 1, height: 50, color: Colors.blue.shade200),
                  Expanded(child: _buildMovementItem('Flux Net', financialData.netCashFlowFormatted, Icons.account_balance_wallet, Colors.blue.shade600)),
                ],
              ),
            ),
            if (financialData.movementsByCategory.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Mouvements par Catégorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...financialData.movementsByCategory.take(3).map((movement) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(movement.isIncome ? Icons.add_circle : Icons.remove_circle, 
                         color: movement.isIncome ? Colors.green : Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(movement.categoryName)),
                    Text(movement.amountFormatted, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMovementItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
      ],
    );
  }
}