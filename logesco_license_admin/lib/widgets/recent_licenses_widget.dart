import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/license.dart';

class RecentLicensesWidget extends StatelessWidget {
  final List<License> licenses;

  const RecentLicensesWidget({
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
                Icons.key_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune licence récente',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ...licenses.map((license) => _buildLicenseItem(context, license)),
          if (licenses.length >= 5)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () {
                  // Navigation vers la liste complète des licences
                },
                child: const Text('Voir toutes les licences'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(BuildContext context, License license) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(license).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getStatusIcon(license),
          color: _getStatusColor(license),
          size: 20,
        ),
      ),
      title: Text(
        license.typeLabel,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Créée le ${DateFormat('dd/MM/yyyy').format(license.createdAt)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(license).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              license.statusLabel,
              style: TextStyle(
                color: _getStatusColor(license),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (license.isActive && !license.isExpired)
            Text(
              '${license.daysRemaining} jours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
        ],
      ),
      onTap: () {
        // Navigation vers les détails de la licence
      },
    );
  }

  Color _getStatusColor(License license) {
    if (license.isRevoked) return Colors.red;
    if (license.isExpired) return Colors.orange;
    if (license.daysRemaining <= 7) return Colors.amber;
    return Colors.green;
  }

  IconData _getStatusIcon(License license) {
    if (license.isRevoked) return Icons.block;
    if (license.isExpired) return Icons.schedule;
    if (license.daysRemaining <= 7) return Icons.warning;
    return Icons.check_circle;
  }
}
