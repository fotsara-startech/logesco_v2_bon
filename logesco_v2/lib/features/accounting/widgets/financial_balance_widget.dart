import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget d'affichage du bilan financier principal
class FinancialBalanceWidget extends StatelessWidget {
  final FinancialBalance balance;

  const FinancialBalanceWidget({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bilan Financier',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _parseColor(balance.statusColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    balance.statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _parseColor(balance.statusColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              balance.periodFormatted,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Résumé principal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance.isProfitable ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance.isProfitable ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    balance.isProfitable ? Icons.trending_up : Icons.trending_down,
                    color: balance.isProfitable ? Colors.green.shade600 : Colors.red.shade600,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultat Net',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          balance.netProfitFormatted,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: balance.isProfitable ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                        Text(
                          'Marge: ${balance.profitMarginFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Métriques détaillées - Première ligne
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Revenus Totaux',
                    balance.totalRevenueFormatted,
                    '${balance.totalSales} ventes',
                    Icons.attach_money,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'Coût Marchandises',
                    balance.totalCostOfGoodsFormatted,
                    'Prix d\'achat',
                    Icons.shopping_basket,
                    Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deuxième ligne - Marges
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Marge Brute',
                    balance.grossProfitFormatted,
                    'Marge: ${balance.grossMarginFormatted}',
                    Icons.trending_up,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'Dépenses Opérat.',
                    balance.totalExpensesFormatted,
                    '${balance.totalExpenseItems} dépenses',
                    Icons.money_off,
                    Colors.red.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Moyennes
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Vente Moyenne',
                    balance.averageSaleAmountFormatted,
                    'Par transaction',
                    Icons.shopping_cart,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'Bénéfice/Jour',
                    balance.averageDailyProfitFormatted,
                    '${balance.periodDays} jours',
                    Icons.calendar_today,
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte de détail
  Widget _buildDetailCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Parse une couleur depuis une chaîne hexadécimale
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
