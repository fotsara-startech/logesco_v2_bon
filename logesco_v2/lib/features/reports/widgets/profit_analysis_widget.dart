import 'package:flutter/material.dart';
import '../models/activity_report.dart';

/// Widget pour afficher l'analyse des bénéfices
class ProfitAnalysisWidget extends StatelessWidget {
  final ProfitData profitData;

  const ProfitAnalysisWidget({
    super.key,
    required this.profitData,
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
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: profitData.isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analyse des Bénéfices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildProfitabilityBadge(),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Résumé des bénéfices
            _buildProfitSummary(),
            
            const SizedBox(height: 20),
            
            // Détails des coûts
            _buildCostBreakdown(),
            
            const SizedBox(height: 20),
            
            // Tendance
            _buildTrendAnalysis(),
          ],
        ),
      ),
    );
  }

  /// Badge de rentabilité
  Widget _buildProfitabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: profitData.isProfitable ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        profitData.isProfitable ? 'RENTABLE' : 'DÉFICITAIRE',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Résumé des bénéfices
  Widget _buildProfitSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: profitData.isProfitable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: profitData.isProfitable ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildProfitItem(
              'Marge Brute',
              profitData.grossProfitFormatted,
              Icons.account_balance_wallet,
              Colors.blue.shade600,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: profitData.isProfitable ? Colors.green.shade200 : Colors.red.shade200,
          ),
          Expanded(
            child: _buildProfitItem(
              'Bénéfice Net',
              profitData.netProfitFormatted,
              Icons.monetization_on,
              profitData.isProfitable ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: profitData.isProfitable ? Colors.green.shade200 : Colors.red.shade200,
          ),
          Expanded(
            child: _buildProfitItem(
              'Marge (%)',
              profitData.profitMarginFormatted,
              Icons.percent,
              Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Item de profit
  Widget _buildProfitItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Répartition des coûts
  Widget _buildCostBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Répartition des Coûts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildCostItem(
                'Coût des Marchandises Vendues',
                profitData.costOfGoodsSoldFormatted,
                Colors.orange.shade600,
              ),
              const SizedBox(height: 12),
              _buildCostItem(
                'Dépenses Opérationnelles',
                profitData.operatingExpensesFormatted,
                Colors.red.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item de coût
  Widget _buildCostItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Analyse de tendance
  Widget _buildTrendAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Évolution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: profitData.profitTrend.isIncreasing ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: profitData.profitTrend.isIncreasing ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                profitData.profitTrend.isIncreasing ? Icons.trending_up : Icons.trending_down,
                color: profitData.profitTrend.isIncreasing ? Colors.green.shade600 : Colors.red.shade600,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profitData.profitTrend.isIncreasing ? 'Tendance Positive' : 'Tendance Négative',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: profitData.profitTrend.isIncreasing ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Période précédente: ${profitData.profitTrend.previousPeriodProfitFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Croissance: ${profitData.profitTrend.growthRateFormatted}',
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
      ],
    );
  }
}