import 'package:flutter/material.dart';
import '../services/movement_report_service.dart';

/// Widget pour afficher les statistiques de résumé
class SummaryStatisticsWidget extends StatelessWidget {
  final MovementSummary summary;
  final int periodDays;

  const SummaryStatisticsWidget({
    super.key,
    required this.summary,
    required this.periodDays,
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
                Icon(Icons.analytics, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Résumé de la période',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistiques principales
            _buildMainStats(),

            const SizedBox(height: 16),

            // Statistiques secondaires
            _buildSecondaryStats(),
          ],
        ),
      ),
    );
  }

  /// Construit les statistiques principales
  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total des dépenses',
            summary.totalAmountFormatted,
            Icons.money_off,
            Colors.red,
            isMain: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Nombre de mouvements',
            '${summary.totalCount}',
            Icons.receipt_long,
            Colors.blue,
            isMain: true,
          ),
        ),
      ],
    );
  }

  /// Construit les statistiques secondaires
  Widget _buildSecondaryStats() {
    final dailyAverage = periodDays > 0 ? summary.totalAmount / periodDays : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Moyenne par mouvement',
                summary.averageAmountFormatted,
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Moyenne quotidienne',
                '${dailyAverage.toStringAsFixed(2)} FCFA',
                Icons.calendar_today,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Montant maximum',
                '${summary.maxAmount.toStringAsFixed(2)} FCFA',
                Icons.keyboard_arrow_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Montant minimum',
                '${summary.minAmount.toStringAsFixed(2)} FCFA',
                Icons.keyboard_arrow_down,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isMain = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMain ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: isMain ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isMain ? 28 : 24,
          ),
          SizedBox(height: isMain ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMain ? 8 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 14 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
