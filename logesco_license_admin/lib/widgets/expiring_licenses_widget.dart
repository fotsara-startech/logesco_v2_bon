import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/license.dart';

class ExpiringLicensesWidget extends StatelessWidget {
  final List<License> licenses;

  const ExpiringLicensesWidget({
    super.key,
    required this.licenses,
  });

  @override
  Widget build(BuildContext context) {
    if (licenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune licence n\'expire bientôt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...licenses.map((license) => _buildLicenseItem(context, license)),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseItem(BuildContext context, License license) {
    final now = DateTime.now();
    final daysUntilExpiry = license.expiresAt.difference(now).inDays;
    final dateFormat = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;
    if (daysUntilExpiry <= 7) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (daysUntilExpiry <= 14) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.yellow.shade700;
      statusIcon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  license.typeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expire le ${dateFormat.format(license.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$daysUntilExpiry j',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
