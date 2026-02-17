import 'package:flutter/material.dart';

/// Widget d'information sur la période sélectionnée
class PeriodInfoWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMovements;
  final double totalAmount;

  const PeriodInfoWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.totalMovements,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final periodDays = endDate.difference(startDate).inDays + 1;
    final averagePerDay = periodDays > 0 ? totalAmount / periodDays : 0.0;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Période Analysée',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Période',
                    _formatPeriod(),
                    Icons.date_range,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Durée',
                    '$periodDays jour${periodDays > 1 ? 's' : ''}',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Transactions',
                    '$totalMovements',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Moyenne/Jour',
                    '${averagePerDay.toStringAsFixed(0)} FCFA',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPeriod() {
    final start = '${startDate.day}/${startDate.month}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';

    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      if (startDate.day == endDate.day) {
        return '${startDate.day}/${startDate.month}/${startDate.year}';
      } else {
        return '$start - $end';
      }
    } else {
      return '${startDate.day}/${startDate.month}/${startDate.year} - $end';
    }
  }
}
