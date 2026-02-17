import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget d'explication du calcul de la marge
class MarginExplanationWidget extends StatelessWidget {
  final FinancialBalance balance;

  const MarginExplanationWidget({
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
                Icon(Icons.calculate, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Calcul de la Rentabilité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showDetailedExplanation(context),
                  tooltip: 'Plus d\'informations',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Étapes du calcul
            _buildCalculationStep(
              '1. Revenus des Ventes',
              balance.totalRevenueFormatted,
              'Prix de vente × Quantités vendues',
              Colors.green.shade600,
              Icons.attach_money,
            ),
            const SizedBox(height: 8),

            _buildCalculationStep(
              '2. Coût des Marchandises',
              '- ${balance.totalCostOfGoodsFormatted}',
              'Prix d\'achat × Quantités vendues',
              Colors.orange.shade600,
              Icons.shopping_basket,
            ),
            const SizedBox(height: 8),

            Container(
              height: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 8),

            _buildCalculationStep(
              '= Marge Brute',
              balance.grossProfitFormatted,
              'Revenus - Coût marchandises (${balance.grossMarginFormatted})',
              Colors.blue.shade600,
              Icons.trending_up,
            ),
            const SizedBox(height: 8),

            _buildCalculationStep(
              '3. Dépenses Opérationnelles',
              '- ${balance.totalExpensesFormatted}',
              'Frais généraux, salaires, etc.',
              Colors.red.shade600,
              Icons.money_off,
            ),
            const SizedBox(height: 8),

            Container(
              height: 2,
              color: Colors.grey.shade400,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 8),

            _buildCalculationStep(
              '= Bénéfice Net',
              balance.netProfitFormatted,
              'Marge brute - Dépenses (${balance.profitMarginFormatted})',
              balance.isProfitable ? Colors.green.shade700 : Colors.red.shade700,
              balance.isProfitable ? Icons.check_circle : Icons.warning,
              isResult: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une étape du calcul
  Widget _buildCalculationStep(
    String title,
    String amount,
    String description,
    Color color,
    IconData icon, {
    bool isResult = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isResult ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: isResult ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isResult ? 16 : 14,
                    fontWeight: isResult ? FontWeight.bold : FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isResult ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une explication détaillée
  void _showDetailedExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            SizedBox(width: 8),
            Text('Comment calculer la rentabilité'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExplanationSection(
                'Marge Brute',
                'La marge brute représente le bénéfice réalisé sur la vente des produits, avant déduction des frais généraux.',
                'Formule: Prix de Vente - Prix d\'Achat',
                Colors.blue.shade600,
              ),
              const SizedBox(height: 16),
              _buildExplanationSection(
                'Bénéfice Net',
                'Le bénéfice net est le résultat final après déduction de toutes les charges (salaires, loyer, électricité, etc.).',
                'Formule: Marge Brute - Dépenses Opérationnelles',
                Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              _buildExplanationSection(
                'Marge en %',
                'La marge en pourcentage permet de comparer la rentabilité sur différentes périodes.',
                'Formule: (Bénéfice / Chiffre d\'Affaires) × 100',
                Colors.purple.shade600,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Construit une section d'explication
  Widget _buildExplanationSection(String title, String description, String formula, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            formula,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
