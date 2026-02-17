import 'package:flutter/material.dart';
import '../models/subscription_status.dart';
import '../models/license_data.dart';
import 'license_activation_page.dart';

/// Dialog de notification d'expiration d'abonnement
class ExpirationNotificationDialog extends StatelessWidget {
  final SubscriptionStatus status;
  final bool isUrgent;

  const ExpirationNotificationDialog({
    super.key,
    required this.status,
    this.isUrgent = false,
  });

  /// Affiche le dialog de notification d'expiration
  static Future<void> show(BuildContext context, SubscriptionStatus status, {bool isUrgent = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isUrgent, // Ne peut pas être fermé si urgent
      builder: (context) => ExpirationNotificationDialog(
        status: status,
        isUrgent: isUrgent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingDays = status.remainingDays ?? 0;
    final isExpiringSoon = remainingDays <= 1;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isExpiringSoon ? Icons.warning : Icons.info,
            color: isExpiringSoon ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpiringSoon ? 'Expiration imminente' : 'Renouvellement recommandé',
              style: TextStyle(
                color: isExpiringSoon ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message principal
          Text(
            _getMainMessage(),
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Détails de l'abonnement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', _getSubscriptionTypeLabel()),
                const SizedBox(height: 8),
                if (status.expirationDate != null) _buildDetailRow('Expire le', _formatDate(status.expirationDate!)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Jours restants',
                  '$remainingDays jour${remainingDays > 1 ? 's' : ''}',
                  textColor: _getRemainingDaysColor(remainingDays),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Message d'action
          Text(
            _getActionMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      actions: [
        // Bouton "Plus tard" (seulement si pas urgent)
        if (!isUrgent)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),

        // Bouton "Activer une licence"
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LicenseActivationPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpiringSoon ? Colors.red : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Activer une licence'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _getMainMessage() {
    final remainingDays = status.remainingDays ?? 0;

    if (remainingDays == 0) {
      return status.type == SubscriptionType.trial ? 'Votre période d\'essai expire aujourd\'hui.' : 'Votre abonnement expire aujourd\'hui.';
    } else if (remainingDays == 1) {
      return status.type == SubscriptionType.trial ? 'Votre période d\'essai expire demain.' : 'Votre abonnement expire demain.';
    } else {
      return status.type == SubscriptionType.trial ? 'Votre période d\'essai expire dans $remainingDays jours.' : 'Votre abonnement expire dans $remainingDays jours.';
    }
  }

  String _getActionMessage() {
    final remainingDays = status.remainingDays ?? 0;

    if (remainingDays <= 1) {
      return 'Activez une nouvelle licence maintenant pour éviter l\'interruption du service.';
    } else {
      return 'Nous vous recommandons de renouveler votre abonnement pour continuer à profiter de toutes les fonctionnalités.';
    }
  }

  String _getSubscriptionTypeLabel() {
    switch (status.type) {
      case SubscriptionType.trial:
        return 'Période d\'essai';
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.annual:
        return 'Annuel';
      case SubscriptionType.lifetime:
        return 'Vie entière';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRemainingDaysColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }
}
