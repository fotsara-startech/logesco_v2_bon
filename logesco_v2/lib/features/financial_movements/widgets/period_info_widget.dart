import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
    final daysDifference = endDate.difference(startDate).inDays + 1;
    final dailyAverage = daysDifference > 0 ? totalAmount / daysDifference : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Text(
                  'financial_movements_period_info'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'financial_movements_period_label'.tr,
                    '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'financial_movements_duration_label'.tr,
                    daysDifference > 1 ? 'financial_movements_days_plural'.tr.replaceAll('@count', '$daysDifference') : 'financial_movements_days_singular'.tr.replaceAll('@count', '$daysDifference'),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'financial_movements_total_movements'.tr,
                    '$totalMovements',
                    Icons.receipt_long,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'financial_movements_daily_average_label'.tr,
                    '${NumberFormat('#,##0', 'fr_FR').format(dailyAverage)} FCFA',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color is MaterialColor ? color.shade700 : color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
