import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';

/// Widget d'aperçu de la rentabilité
class ProfitabilityOverviewWidget extends StatelessWidget {
  const ProfitabilityOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountingController>();

    return Obx(() {
      final summary = controller.quickSummary.value;
      if (summary.isEmpty) {
        return const SizedBox.shrink();
      }

      final isProfitable = summary['isProfitable'] ?? false;
      final netProfit = (summary['netProfit'] ?? 0.0) as double;
      final profitMargin = (summary['profitMargin'] ?? 0.0) as double;
      final statusMessage = summary['statusMessage'] ?? 'Statut inconnu';
      final statusColor = _parseColor(summary['statusColor'] ?? '#6B7280');
      final totalRevenue = (summary['totalRevenue'] ?? 0.0) as double;
      final totalExpenses = (summary['totalExpenses'] ?? 0.0) as double;

      return Card(
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.1),
                statusColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isProfitable ? Icons.trending_up : Icons.trending_down,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rentabilité du mois',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusMessage,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Métriques principales
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Bénéfice Net',
                        '${netProfit.toStringAsFixed(0)} FCFA',
                        isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                        isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Marge',
                        '${profitMargin.toStringAsFixed(1)}%',
                        Icons.percent,
                        statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Revenus et dépenses
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Revenus',
                        '${totalRevenue.toStringAsFixed(0)} FCFA',
                        Icons.attach_money,
                        Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Dépenses',
                        '${totalExpenses.toStringAsFixed(0)} FCFA',
                        Icons.money_off,
                        Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barre de progression de la rentabilité
                _buildProfitabilityBar(profitMargin, statusColor),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Construit une carte de métrique
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
        ],
      ),
    );
  }

  /// Construit la barre de progression de rentabilité
  Widget _buildProfitabilityBar(double profitMargin, Color statusColor) {
    // Normaliser la marge pour l'affichage (0-100%)
    final normalizedMargin = (profitMargin + 50).clamp(0.0, 100.0) / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Indicateur de rentabilité',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${profitMargin.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalizedMargin,
            child: Container(
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Critique',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              'Excellent',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
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
