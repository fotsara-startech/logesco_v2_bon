import 'package:flutter/material.dart';
import '../models/activity_report.dart';

/// Widget pour afficher les dettes clients
class CustomerDebtsWidget extends StatelessWidget {
  final CustomerDebtsData debtsData;

  const CustomerDebtsWidget({
    super.key,
    required this.debtsData,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: afficher les données reçues
    print('🔍 [CustomerDebtsWidget] Données reçues:');
    print('  - totalOutstandingDebt: ${debtsData.totalOutstandingDebt}');
    print('  - customersWithDebt: ${debtsData.customersWithDebt}');
    print('  - averageDebtPerCustomer: ${debtsData.averageDebtPerCustomer}');
    print('  - topDebtors count: ${debtsData.topDebtors.length}');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 12),
                const Text('Dettes Clients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildDebtItem('Total Dettes', debtsData.totalOutstandingDebtFormatted, Icons.account_balance, Colors.red.shade600)),
                  Container(width: 1, height: 50, color: Colors.orange.shade200),
                  Expanded(child: _buildDebtItem('Clients Débiteurs', debtsData.customersWithDebt.toString(), Icons.person, Colors.orange.shade600)),
                  Container(width: 1, height: 50, color: Colors.orange.shade200),
                  Expanded(child: _buildDebtItem('Dette Moyenne', debtsData.averageDebtPerCustomerFormatted, Icons.trending_up, Colors.blue.shade600)),
                ],
              ),
            ),
            if (debtsData.topDebtors.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Principaux Débiteurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...debtsData.topDebtors.take(5).map((debt) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(child: Text(debt.customerName)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(debt.debtAmountFormatted, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                        Text('${debt.daysOverdue} jours', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItem(String label, String value, IconData icon, Color color) {
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