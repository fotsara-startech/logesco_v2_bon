import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget d'affichage des indicateurs KPI
class KPIIndicatorsWidget extends StatelessWidget {
  final KPIIndicators kpis;

  const KPIIndicatorsWidget({
    super.key,
    required this.kpis,
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
                Icon(Icons.analytics, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Indicateurs Clés (KPI)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Première ligne d'indicateurs
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'ROI',
                    kpis.roiFormatted,
                    'Retour sur investissement',
                    Icons.trending_up,
                    _getROIColor(kpis.returnOnInvestment),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    'Seuil de Rentabilité',
                    kpis.breakEvenPointFormatted,
                    'Point d\'équilibre',
                    Icons.balance,
                    Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deuxième ligne d'indicateurs
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Flux de Trésorerie',
                    kpis.cashFlowFormatted,
                    'Cash-flow',
                    Icons.account_balance_wallet,
                    _getCashFlowColor(kpis.cashFlow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    'Jours au Seuil',
                    kpis.daysToBreakEven > 0 ? '${kpis.daysToBreakEven} jours' : 'N/A',
                    'Temps pour équilibre',
                    Icons.schedule,
                    Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte KPI
  Widget _buildKPICard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtient la couleur pour le ROI
  Color _getROIColor(double roi) {
    if (roi > 20) return Colors.green.shade600;
    if (roi > 10) return Colors.lightGreen.shade600;
    if (roi > 0) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  /// Obtient la couleur pour le cash flow
  Color _getCashFlowColor(double cashFlow) {
    if (cashFlow > 0) return Colors.green.shade600;
    if (cashFlow == 0) return Colors.grey.shade600;
    return Colors.red.shade600;
  }
}
